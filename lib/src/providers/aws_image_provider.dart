import 'dart:async';
import 'dart:ui' as ui;

import 'package:aws_image/aws_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:fp_logger/fp_logger.dart';
import 'package:mime/mime.dart';

/// {@template aws_image_provider}
/// An [ImageProvider] that loads images from AWS S3 with caching support.
///
/// This provider handles:
/// - Fetching images from AWS S3 using presigned URLs
/// - Local caching with configurable duration
/// - Automatic cache invalidation after [cacheDuration]
/// - Retry logic for failed requests
/// - Presigned URL refresh when expired
///
/// ## Basic Usage
///
/// ```dart
/// Image(
///   image: AwsImageProvider(
///     client: myAwsClient,
///     url: 'https://bucket.s3.amazonaws.com/image.jpg',
///   ),
/// )
/// ```
///
/// ## With Custom Cache Duration
///
/// ```dart
/// AwsImageProvider(
///   client: myAwsClient,
///   url: imageUrl,
///   cacheDuration: const Duration(days: 30),
/// )
/// ```
///
/// See also:
/// - [AwsImage] for a convenient widget wrapper.
/// - [RawAwsImage] for advanced widget usage.
/// {@endtemplate}
@immutable
class AwsImageProvider extends ImageProvider<AwsImageProvider> {
  /// {@macro aws_image_provider}
  const AwsImageProvider({
    required this.client,
    required this.url,
    this.scale = 1.0,
    this.cacheDuration = defaultCacheDuration,
    this.maxRetries = defaultMaxRetries,
    this.forceRefresh = false,
    this.retryDelay = defaultRetryDelay,
    this.headers = const {},
    this.queryParameters = const {},
  });

  /// The AWS client for fetching images and presigned URLs.
  final AwsImageClient client;

  /// The image URL or S3 object key.
  final String url;

  /// Scale factor for the image.
  final double scale;

  /// Duration to cache the image locally before invalidation.
  final Duration cacheDuration;

  /// Maximum retry attempts for failed requests.
  final int maxRetries;

  /// Whether to bypass cache and fetch fresh.
  final bool forceRefresh;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// HTTP headers for the request.
  final Map<String, dynamic> headers;

  /// Query parameters for the request.
  final Map<String, dynamic> queryParameters;

  /// Cache key derived from the URL.
  String get cacheKey => parseCacheKey(url);

  // Access the singleton cache manager
  static final cacheManager = AwsCacheManager.instance;

  @override
  Future<AwsImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AwsImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    AwsImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.cacheKey,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<AwsImageProvider>('Image key', key),
      ],
    );
  }

  /// Load image bytes, either from cache or network.
  Future<ui.Codec> _loadAsync(
    AwsImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    try {
      // Check if cache is valid (not expired)
      if (!forceRefresh) {
        final isCacheValid = await cacheManager.isCacheValid(
          key.cacheKey,
          key.cacheDuration,
        );

        if (isCacheValid) {
          final cachedBytes = await cacheManager.getFromCache(key.cacheKey);
          if (cachedBytes != null) {
            final buffer = await ui.ImmutableBuffer.fromUint8List(cachedBytes);
            return decode(buffer);
          }
        } else {
          // Cache expired, invalidate it
          await cacheManager.invalidate(key.cacheKey);
        }
      }

      // Fetch from network
      final bytes = await _fetchWithRetry(key, chunkEvents);
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Failed to load image: empty or null bytes');
      }

      // Cache the fetched bytes with timestamp
      await cacheManager.cacheImage(key.cacheKey, bytes);
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (e, st) {
      chunkEvents.addError(e, st);
      rethrow;
    } finally {
      await chunkEvents.close();
    }
  }

  /// Fetch image bytes with retry logic.
  Future<Uint8List?> _fetchWithRetry(
    AwsImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    final imageUrl = await _resolveImageUrl();
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await client.getImage(
          url: imageUrl,
          headers: key.headers,
          queryParameters: key.queryParameters,
          onReceiveProgress: (loaded, total) {
            if (total < 0) {
              return;
            }
            chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: loaded,
              expectedTotalBytes: total,
            ));
          },
        );
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        if (attempt < maxRetries - 1) {
          await Future<void>.delayed(retryDelay);
        }
      }
    }

    Error.throwWithStackTrace(
      lastError ??
          Exception('Failed to fetch image after $maxRetries attempts'),
      lastStackTrace ?? StackTrace.current,
    );
  }

  /// Resolve the image URL, refreshing if expired.
  Future<String?> _resolveImageUrl() async {
    if (isValidUrl(url) && !isUrlExpired(url)) {
      return url;
    }
    Logger.d(
      'URL invalid or expired. Fetching new URL. from the AwsRequest',
      tag: 'AwsImageProvider',
    );
    return _fetchPresignedUrl(url);
  }

  Future<String?> _fetchPresignedUrl(String key) async {
    final res = await client.getPresignedUrl(
      key,
      contentType: lookupMimeType(key),
      type: AwsUrlType.GET,
    );

    if (res?.previewUrl == null) return null;
    return res!.previewUrl!;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AwsImageProvider &&
        other.cacheKey == cacheKey &&
        other.scale == scale &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode => Object.hash(cacheKey, scale, forceRefresh);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'AwsImageProvider')}("$cacheKey", scale: $scale)';
}
