import 'dart:async';
import 'dart:ui' show Codec;

import 'package:aws_image/src/client/http_client.dart';
import 'package:aws_image/src/utils/_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fp_logger/fp_logger.dart';
import 'package:mime/mime.dart';

import '../client/image_cache_service.dart';
import '../utils/utils.dart';

/// {@template aws_image}
/// A custom image provider for loading images from AWS S3.
/// It handles caching, loading from network, and refreshing expired URLs.
/// It uses the [AwsImageLoader] to refresh the URL if it is expired.
/// {@endtemplate}
class AwsImageProvider extends ImageProvider<AwsImageProvider> {
  ///{@macro aws_image}
  AwsImageProvider({
    this.presignedUrl,
    String? bucketKey,
    required this.imageClient,
    this.headers = const {},
    this.queryParameters = const {},
    this.cacheDuration = defaultCacheDuration,
    this.maxRetries = defaultMaxRetries,
    this.retryDelay = defaultRetryDelay,
    this.scale = defaultScale,
    this.forceRefresh = false,
  })  : assert(
          presignedUrl.isNotNullOrEmpty || bucketKey.isNotNullOrEmpty,
          'At least one of presignedUrl or bucketKey must be provided.',
        ),
        bucketKey = bucketKey ?? parseBucketKey(presignedUrl!),
        cacheKey = parseCacheKey(presignedUrl, bucketKey);

  /// presigned url info
  final String? presignedUrl;

  /// bucket key to retrieve the image
  final String bucketKey;

  /// cache key to store the image
  final String cacheKey;

  /// aws image client
  final AwsImageClient imageClient;

  /// headers per request
  final Map<String, dynamic> headers;

  /// query parameters for the request
  final Map<String, dynamic> queryParameters;

  /// The cache duration for the image.
  /// Default is 7 days.
  final Duration cacheDuration;

  /// The maximum number of retries to load the image from the network.
  /// Default is 3.
  final int maxRetries;

  /// The delay between retries.
  /// Default is 2 seconds.
  final Duration retryDelay;

  /// The scale of the image.
  /// Default is 1.0.
  final double scale;

  /// Whether to force refresh the image.
  final bool forceRefresh;

  @override
  Future<AwsImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AwsImageProvider>(this);
  }

  @override
  Future<bool> evict({
    ImageCache? cache,
    ImageConfiguration configuration = ImageConfiguration.empty,
  }) async {
    await ImageCacheService().deleteImageCache(cacheKey);
    return true;
  }

  @override
  ImageStreamCompleter loadImage(
    AwsImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode, chunkEvents),
      scale: scale,
      chunkEvents: chunkEvents.stream,
      debugLabel: key.presignedUrl,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('ImageProvider', this),
        DiagnosticsProperty<AwsImageProvider>('AwsImageProvider', key),
        ErrorDescription(
          'The URL has expired. Please refresh the image url using loader.',
        ),
        ErrorDescription('URL: ${key.presignedUrl}'),
      ],
    );
  }

  /// _loadAsync loads the image asynchronously.
  /// It uses the [AwsImageLoader] to refresh the URL if it is expired.
  /// It returns a [Codec] that can be used to decode the image.
  Future<Codec> _loadAsync(
    AwsImageProvider key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    assert(
      key == this,
      'ImageProvider key should be the same as the original key.',
    );

    Uint8List? imageBytes;

    /// local cache
    if (!key.forceRefresh) {
      imageBytes = await ImageCacheService().getCachedImage(key.cacheKey);
    }

    // If not in cache or forceRefresh, load from network
    imageBytes ??= await _loadFromNetwork(key, chunkEvents);

    if (imageBytes != null) {
      unawaited(ImageCacheService().cacheFile(key.cacheKey, imageBytes));
      final buffer = await ImmutableBuffer.fromUint8List(imageBytes);
      return decode(buffer);
    }
    unawaited(evict());
    await chunkEvents.close();
    return Future.error('Failed to load image codec.', StackTrace.current);
  }

  /// loadFromNetwork loads the image from network and returns the bytes.
  /// It also handles retries and chunk events.
  /// It uses the [AwsImageLoader] to refresh the URL if it is expired.
  /// It returns null if the image fails to load.
  Future<Uint8List?> _loadFromNetwork(
    AwsImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    assert(
      key == this,
      'ImageProvider key should be the same as the original key.',
    );
    String? imageUrl = key.presignedUrl;

    /// If the URL is not provided, get it from the image client.
    imageUrl ??= await _refetchImage(key);

    if (imageUrl.isNullOrEmpty) {
      unawaited(evict());
      return null;
    }

    // If the URL is expired, refresh it using the loader.
    if (isUrlExpired(imageUrl!)) {
      Logger.d(
        'Presigned URL is expired. Refreshing it using loader.',
        tag: 'AwsImageProvider',
      );
      imageUrl = await _refetchImage(key);
      if (imageUrl == null) {
        unawaited(evict());
        return null;
      }
    }

    // If the URL is still empty, return null.
    if (imageUrl.isNullOrEmpty) return null;

    // Load the image from network.
    final response = await key.imageClient.getImage(
      url: imageUrl,
      headers: key.headers,
      queryParameters: key.queryParameters,
      onReceiveProgress: (received, total) {
        if (total == -1) return;
        chunkEvents.add(
          ImageChunkEvent(
            cumulativeBytesLoaded: received,
            expectedTotalBytes: total,
          ),
        );
      },
      maxRetries: key.maxRetries,
      retryDelay: key.retryDelay,
      onError: (error, stackTrace) {
        evict();
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'aws_image',
            context: ErrorDescription(error.toString()),
            informationCollector: () => <DiagnosticsNode>[
              DiagnosticsProperty<AwsImageProvider>('AwsImageProvider', key),
              ErrorDescription('URL: $imageUrl'),
            ],
          ),
        );
      },
    );
    return response;
  }

  Future<String?> _refetchImage(AwsImageProvider key) async {
    return await key.imageClient.getPresignedUrl(
      key.bucketKey,
      contentType: lookupMimeType(key.bucketKey),
    );
  }

  @override
  int get hashCode => Object.hashAll([
        imageClient,
        presignedUrl,
        cacheKey,
        scale,
        forceRefresh,
        cacheDuration,
        maxRetries,
        retryDelay,
      ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AwsImageProvider) return false;
    return other.presignedUrl == presignedUrl &&
        other.cacheKey == cacheKey &&
        other.scale == scale &&
        other.forceRefresh == forceRefresh &&
        other.cacheDuration == cacheDuration &&
        other.maxRetries == maxRetries &&
        other.retryDelay == retryDelay;
  }
}
