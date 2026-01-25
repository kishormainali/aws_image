import 'package:aws_image/aws_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'raw_aws_image.dart';

/// {@template aws_image}
/// A convenience widget for displaying images from AWS S3.
///
/// This widget automatically retrieves the [AwsImageClient] from the widget tree
/// via [AwsClientProvider], simplifying usage compared to [RawAwsImage].
///
/// ## Features
///
/// - **Context-aware client**: Automatically uses the nearest [AwsClientProvider].
/// - **Full customization**: Supports all [RawAwsImage] features.
/// - **Caching**: Local caching with configurable duration.
/// - **Error handling**: Customizable loading and error states.
///
/// ## Basic Usage
///
/// ```dart
/// // Wrap your app with AwsClientProvider
/// AwsClientProvider(
///   client: myAwsClient,
///   child: MaterialApp(...),
/// )
///
/// // Then use AwsImage anywhere in the tree
/// AwsImage(
///   url: 'https://bucket.s3.amazonaws.com/image.jpg',
///   width: 200,
///   height: 200,
///   fit: BoxFit.cover,
/// )
/// ```
///
/// ## With Custom Builders
///
/// ```dart
/// AwsImage(
///   url: imageUrl,
///   width: 300,
///   height: 200,
///   loadingBuilder: (context, bytesLoaded, totalBytes) {
///     final progress = totalBytes > 0 ? bytesLoaded / totalBytes : 0.0;
///     return CircularProgressIndicator(value: progress);
///   },
///   errorBuilder: (context, error, stackTrace) {
///     return const Icon(Icons.error, color: Colors.red);
///   },
/// )
/// ```
///
/// ## Circular Avatar
///
/// ```dart
/// AwsImage(
///   url: avatarUrl,
///   width: 100,
///   height: 100,
///   shape: BoxShape.circle,
///   border: Border.all(color: Colors.blue, width: 2),
/// )
/// ```
///
/// See also:
/// - [RawAwsImage] for direct usage with an explicit client.
/// - [AwsClientProvider] for providing the client to the widget tree.
/// - [AwsImageProvider] for the underlying image provider.
/// {@endtemplate}
class AwsImage extends StatelessWidget {
  /// {@macro aws_image}
  const AwsImage({
    super.key,
    required this.url,
    this.headers = const {},
    this.queryParameters = const {},
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.isAntiAlias = false,
    this.filterQuality = FilterQuality.medium,
    this.shape,
    this.border,
    this.borderRadius,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
    this.compressionRatio,
    this.maxBytes,
    this.scale = 1.0,
    this.cacheDuration = defaultCacheDuration,
    this.maxRetries = defaultMaxRetries,
    this.forceRefresh = false,
    this.retryDelay = defaultRetryDelay,
    this.loadingBuilder,
    this.errorBuilder,
    this.constraints,
    this.resizePolicy = ResizeImagePolicy.exact,
    this.allowUpscaling = false,
  });

  /// The presigned URL or S3 object key to retrieve the image.
  ///
  /// Accepts:
  /// - A full presigned URL (used directly)
  /// - An S3 object key (presigned URL fetched via [AwsImageClient])
  final String url;

  /// HTTP headers to include with the image request.
  final Map<String, dynamic> headers;

  /// Query parameters to append to the request URL.
  final Map<String, dynamic> queryParameters;

  /// Semantic description for accessibility.
  final String? semanticLabel;

  /// Whether to exclude from the semantics tree.
  final bool excludeFromSemantics;

  /// Target display width in logical pixels.
  final double? width;

  /// Target display height in logical pixels.
  final double? height;

  /// Width for caching the decoded image (reduces memory for large images).
  final int? cacheWidth;

  /// Height for caching the decoded image (reduces memory for large images).
  final int? cacheHeight;

  /// Color to blend with the image.
  final Color? color;

  /// Animation controlling image opacity (for fade effects).
  final Animation<double>? opacity;

  /// Blend mode for applying [color].
  final BlendMode? colorBlendMode;

  /// How the image fits within its bounds.
  final BoxFit? fit;

  /// Alignment within the container.
  final Alignment alignment;

  /// How the image repeats if smaller than its bounds.
  final ImageRepeat repeat;

  /// Center slice for nine-patch images.
  final Rect? centerSlice;

  /// Whether to flip horizontally for RTL text direction.
  final bool matchTextDirection;

  /// Whether to show old image while loading new one (prevents flicker).
  final bool gaplessPlayback;

  /// Whether to apply anti-aliasing.
  final bool isAntiAlias;

  /// Quality of image filtering when scaled.
  final FilterQuality filterQuality;

  /// Shape to clip the image to.
  final BoxShape? shape;

  /// Border around the image.
  final Border? border;

  /// Border radius for rounded corners.
  final BorderRadius? borderRadius;

  /// Tap callback.
  final VoidCallback? onTap;

  /// How to clip the image content.
  final Clip clipBehavior;

  /// Size constraints for the image container.
  final BoxConstraints? constraints;

  /// Policy for resizing the image.
  final ResizeImagePolicy resizePolicy;

  /// Compression ratio for resizing (0.0 to 1.0).
  final double? compressionRatio;

  /// Maximum bytes for the decoded image in memory.
  final int? maxBytes;

  /// Scale factor for the image.
  final double scale;

  /// Whether to allow upscaling beyond original dimensions.
  final bool allowUpscaling;

  /// Duration to cache the image locally.
  final Duration cacheDuration;

  /// Maximum retry attempts for failed requests.
  final int maxRetries;

  /// Whether to bypass cache and fetch fresh.
  final bool forceRefresh;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// Builder for custom loading indicator.
  final AwsImageLoadingBuilder? loadingBuilder;

  /// Builder for custom error display.
  final AwsImageErrorBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return RawAwsImage(
      client: AwsClientProvider.of(context),
      url: url,
      headers: headers,
      queryParameters: queryParameters,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      filterQuality: filterQuality,
      shape: shape,
      border: border,
      borderRadius: borderRadius,
      onTap: onTap,
      clipBehavior: clipBehavior,
      constraints: constraints,
      compressionRatio: compressionRatio,
      maxBytes: maxBytes,
      scale: scale,
      cacheDuration: cacheDuration,
      maxRetries: maxRetries,
      forceRefresh: forceRefresh,
      retryDelay: retryDelay,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      resizePolicy: resizePolicy,
      allowUpscaling: allowUpscaling,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('url', url))
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(DoubleProperty('height', height, defaultValue: null))
      ..add(IntProperty('cacheWidth', cacheWidth, defaultValue: null))
      ..add(IntProperty('cacheHeight', cacheHeight, defaultValue: null))
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(EnumProperty<BlendMode>(
        'colorBlendMode',
        colorBlendMode,
        defaultValue: null,
      ))
      ..add(EnumProperty<BoxFit>('fit', fit, defaultValue: null))
      ..add(DiagnosticsProperty<Alignment>(
        'alignment',
        alignment,
        defaultValue: Alignment.center,
      ))
      ..add(EnumProperty<ImageRepeat>(
        'repeat',
        repeat,
        defaultValue: ImageRepeat.noRepeat,
      ))
      ..add(EnumProperty<BoxShape>('shape', shape, defaultValue: null))
      ..add(DiagnosticsProperty<BorderRadius>(
        'borderRadius',
        borderRadius,
        defaultValue: null,
      ))
      ..add(EnumProperty<Clip>(
        'clipBehavior',
        clipBehavior,
        defaultValue: Clip.antiAlias,
      ))
      ..add(DoubleProperty('scale', scale, defaultValue: 1.0))
      ..add(DiagnosticsProperty<Duration>(
        'cacheDuration',
        cacheDuration,
        defaultValue: defaultCacheDuration,
      ))
      ..add(IntProperty('maxRetries', maxRetries,
          defaultValue: defaultMaxRetries))
      ..add(FlagProperty(
        'forceRefresh',
        value: forceRefresh,
        ifTrue: 'force refresh enabled',
      ))
      ..add(EnumProperty<FilterQuality>(
        'filterQuality',
        filterQuality,
        defaultValue: FilterQuality.medium,
      ));
  }
}
