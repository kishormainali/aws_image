import 'dart:async';

import 'package:aws_image/aws_image.dart';
import 'package:aws_image/src/providers/_aws_image_resize.dart';
import 'package:aws_image/src/widgets/border_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';

/// The current loading state of an image.
///
/// Used internally by [RawAwsImage] to track image loading lifecycle.
enum LoadState {
  /// Image is currently being fetched from cache or network.
  loading,

  /// Image loaded successfully and is ready for display.
  success,

  /// Image failed to load due to network, cache, or decode error.
  error,
}

/// {@template raw_aws_image}
/// A high-performance widget for displaying images from AWS S3.
///
/// This widget provides comprehensive image loading capabilities with built-in
/// support for caching, error handling, and presigned URL management.
///
/// ## Features
///
/// - **Automatic caching**: Images are cached locally for faster subsequent loads.
/// - **Presigned URL refresh**: Automatically refreshes expired AWS presigned URLs.
/// - **Progress tracking**: Reports loading progress via [loadingBuilder].
/// - **Error handling**: Customizable error display via [errorBuilder] with retry support.
/// - **Image transformations**: Supports resizing, clipping, borders, and color blending.
/// - **Scroll-aware loading**: Optimizes loading based on scroll position.
/// - **Accessibility**: Full semantics support for screen readers.
///
/// ## Basic Usage
///
/// ```dart
/// RawAwsImage(
///   client: myAwsClient,
///   url: 'https://bucket.s3.amazonaws.com/image.jpg',
///   width: 200,
///   height: 200,
///   fit: BoxFit.cover,
/// )
/// ```
///
/// ## With Custom Loading and Error Widgets
///
/// ```dart
/// RawAwsImage(
///   client: myAwsClient,
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
/// ## With Shape and Border
///
/// ```dart
/// RawAwsImage(
///   client: myAwsClient,
///   url: avatarUrl,
///   width: 100,
///   height: 100,
///   shape: BoxShape.circle,
///   border: Border.all(color: Colors.blue, width: 2),
/// )
/// ```
///
/// See also:
/// - [AwsImageProvider] for the underlying image provider.
/// - [AwsImageClient] for configuring AWS S3 access.
/// {@endtemplate}
class RawAwsImage extends StatefulWidget {
  /// {@macro raw_aws_image}
  ///
  /// The [client] and [url] parameters are required.
  ///
  /// The [cacheWidth] and [cacheHeight] must be positive if provided.
  /// The [constraints] must be valid if provided.
  RawAwsImage({
    super.key,
    required AwsImageClient client,
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
    BoxConstraints? constraints,
    ResizeImagePolicy resizePolicy = ResizeImagePolicy.exact,
    bool allowUpscaling = false,
  })  : assert(constraints == null || constraints.debugAssertIsValid()),
        assert(cacheWidth == null || cacheWidth > 0),
        assert(cacheHeight == null || cacheHeight > 0),
        constraints = _resolveConstraints(constraints, width, height),
        image = AwsResizeImage.resizeIfNeeded(
          provider: AwsImageProvider(
            client: client,
            url: url,
            scale: scale,
            cacheDuration: cacheDuration,
            maxRetries: maxRetries,
            forceRefresh: forceRefresh,
            retryDelay: retryDelay,
            headers: headers,
            queryParameters: queryParameters,
          ),
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          maxBytes: maxBytes,
          compressionRatio: compressionRatio,
          policy: resizePolicy,
          allowUpscaling: allowUpscaling,
        );

  /// Resolves constraints by combining explicit dimensions with provided constraints.
  static BoxConstraints? _resolveConstraints(
    BoxConstraints? constraints,
    double? width,
    double? height,
  ) {
    if (width == null && height == null) return constraints;
    return constraints?.tighten(width: width, height: height) ??
        BoxConstraints.tightFor(width: width, height: height);
  }

  /// The presigned URL or S3 object key to retrieve the image.
  ///
  /// If the URL is expired, the [AwsImageProvider] will automatically
  /// request a new presigned URL via the [AwsImageClient].
  final String url;

  /// HTTP headers to include with the image request.
  ///
  /// Useful for passing authentication tokens or custom headers.
  final Map<String, dynamic> headers;

  /// Query parameters to append to the request URL.
  ///
  /// These are merged with any existing query parameters in [url].
  final Map<String, dynamic> queryParameters;

  /// The resolved image provider with optional resizing applied.
  ///
  /// This is created internally from the provided parameters.
  final ImageProvider image;

  /// A semantic description of the image for accessibility.
  ///
  /// Used by screen readers to describe the image content.
  /// If null, the cache key derived from [url] is used.
  final String? semanticLabel;

  /// Whether to exclude this image from the semantics tree.
  ///
  /// Set to `true` for decorative images that don't convey meaning.
  final bool excludeFromSemantics;

  /// The target display width of the image in logical pixels.
  ///
  /// If null, the image uses its intrinsic width.
  final double? width;

  /// The target display height of the image in logical pixels.
  ///
  /// If null, the image uses its intrinsic height.
  final double? height;

  /// The width to use when caching the decoded image in pixels.
  ///
  /// Reduces memory usage for large images displayed at smaller sizes.
  /// Must be positive if provided.
  final int? cacheWidth;

  /// The height to use when caching the decoded image in pixels.
  ///
  /// Reduces memory usage for large images displayed at smaller sizes.
  /// Must be positive if provided.
  final int? cacheHeight;

  /// A color to blend with the image.
  ///
  /// Combined with [colorBlendMode] to apply color effects.
  final Color? color;

  /// Animation controlling the image opacity.
  ///
  /// Useful for fade-in animations when the image loads.
  final Animation<double>? opacity;

  /// The blend mode for applying [color] to the image.
  ///
  /// Common values include [BlendMode.srcIn] for tinting
  /// and [BlendMode.multiply] for darkening.
  final BlendMode? colorBlendMode;

  /// How the image should be inscribed into the space allocated.
  ///
  /// See [BoxFit] for available options like [BoxFit.cover] and [BoxFit.contain].
  final BoxFit? fit;

  /// How to align the image within its bounds.
  ///
  /// Defaults to [Alignment.center].
  final Alignment alignment;

  /// How the image should repeat if it doesn't fill its bounds.
  ///
  /// Defaults to [ImageRepeat.noRepeat].
  final ImageRepeat repeat;

  /// The center slice for nine-patch images.
  ///
  /// Defines the stretchable region for images with fixed borders.
  final Rect? centerSlice;

  /// Whether to flip the image horizontally for RTL text direction.
  ///
  /// Useful for directional images like arrows or progress indicators.
  final bool matchTextDirection;

  /// Whether to keep showing the old image while loading a new one.
  ///
  /// When `true`, avoids flickering when the [url] changes.
  /// Defaults to `false`.
  final bool gaplessPlayback;

  /// Whether to apply anti-aliasing to the image edges.
  ///
  /// May improve visual quality at the cost of performance.
  final bool isAntiAlias;

  /// The quality of image filtering when scaled.
  ///
  /// Higher quality may impact performance. Defaults to [FilterQuality.medium].
  final FilterQuality filterQuality;

  /// The shape to clip the image to.
  ///
  /// Use [BoxShape.circle] for circular avatars or [BoxShape.rectangle]
  /// with [borderRadius] for rounded corners.
  final BoxShape? shape;

  /// Border to draw around the image.
  ///
  /// Applied after clipping to [shape].
  final Border? border;

  /// Border radius for rounded corners.
  ///
  /// Only applies when [shape] is [BoxShape.rectangle].
  final BorderRadius? borderRadius;

  /// Callback invoked when the image is tapped.
  ///
  /// Wraps the image in a [GestureDetector] if provided.
  final VoidCallback? onTap;

  /// How to clip the image content.
  ///
  /// Defaults to [Clip.antiAlias] for smooth edges.
  final Clip clipBehavior;

  /// Size constraints for the image container.
  ///
  /// Combined with [width] and [height] to determine final size.
  final BoxConstraints? constraints;

  /// Compression ratio for image resizing (0.0 to 1.0).
  ///
  /// Lower values produce smaller files with reduced quality.
  final double? compressionRatio;

  /// Maximum bytes for the decoded image in memory.
  ///
  /// Limits memory usage for very large images.
  final int? maxBytes;

  /// Scale factor applied to the image.
  ///
  /// A scale of 2.0 means the image is twice as large as its display size.
  /// Defaults to 1.0.
  final double scale;

  /// Duration to keep the image in the local cache.
  ///
  /// After expiration, the image is re-fetched from the network.
  /// Defaults to 7 days.
  final Duration cacheDuration;

  /// Maximum retry attempts for failed network requests.
  ///
  /// Defaults to 3 attempts.
  final int maxRetries;

  /// Whether to bypass the cache and fetch a fresh image.
  ///
  /// Useful for forcing updates when the remote image has changed.
  final bool forceRefresh;

  /// Delay between retry attempts after a network failure.
  ///
  /// Defaults to 2 seconds.
  final Duration retryDelay;

  /// Builder for a custom loading indicator.
  ///
  /// Receives the current bytes loaded and expected total bytes.
  /// If null, a default [CircularProgressIndicator] is shown.
  final AwsImageLoadingBuilder? loadingBuilder;

  /// Builder for a custom error display.
  ///
  /// Receives the error object and stack trace.
  /// If null, a default error icon with retry capability is shown.
  final AwsImageErrorBuilder? errorBuilder;

  @override
  State<RawAwsImage> createState() => _RawAwsImageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('url', url))
      ..add(DiagnosticsProperty<ImageProvider>('image', image))
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(DoubleProperty('height', height, defaultValue: null))
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(DiagnosticsProperty<Animation<double>?>(
        'opacity',
        opacity,
        defaultValue: null,
      ))
      ..add(EnumProperty<BlendMode>(
        'colorBlendMode',
        colorBlendMode,
        defaultValue: null,
      ))
      ..add(EnumProperty<BoxFit>('fit', fit, defaultValue: null))
      ..add(DiagnosticsProperty<AlignmentGeometry>(
        'alignment',
        alignment,
        defaultValue: null,
      ))
      ..add(EnumProperty<ImageRepeat>(
        'repeat',
        repeat,
        defaultValue: ImageRepeat.noRepeat,
      ))
      ..add(DiagnosticsProperty<Rect>(
        'centerSlice',
        centerSlice,
        defaultValue: null,
      ))
      ..add(FlagProperty(
        'matchTextDirection',
        value: matchTextDirection,
        ifTrue: 'match text direction',
      ))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(DiagnosticsProperty<bool>(
        'excludeFromSemantics',
        excludeFromSemantics,
      ))
      ..add(EnumProperty<FilterQuality>('filterQuality', filterQuality));
  }
}

/// Internal state for [RawAwsImage].
///
/// Manages image stream lifecycle, loading states, and accessibility features.
class _RawAwsImageState extends State<RawAwsImage> with WidgetsBindingObserver {
  LoadState _loadState = LoadState.loading;
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  ImageStreamListener? _imageStreamListener;
  ImageStreamCompleterHandle? _completerHandle;
  ImageChunkEvent? _loadingProgress;
  late DisposableBuildContext<State<RawAwsImage>> _scrollAwareContext;

  Object? _lastException;
  StackTrace? _lastStack;

  int? _frameNumber;
  bool _isListeningToStream = false;
  bool _wasSynchronouslyLoaded = false;
  late bool _invertColors;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollAwareContext = DisposableBuildContext<State<RawAwsImage>>(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateInvertColors();
    _resolveImage();
    _updateStreamSubscription();
  }

  @override
  void didUpdateWidget(RawAwsImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isListeningToStream &&
        oldWidget.loadingBuilder != widget.loadingBuilder) {
      _recreateListener();
    }

    if (widget.image != oldWidget.image ||
        widget.forceRefresh != oldWidget.forceRefresh) {
      _resolveImage(widget.forceRefresh && !oldWidget.forceRefresh);
    }
  }

  @override
  void didChangeAccessibilityFeatures() {
    super.didChangeAccessibilityFeatures();
    setState(_updateInvertColors);
  }

  @override
  void reassemble() {
    _resolveImage();
    super.reassemble();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopListeningToStream();
    _completerHandle?.dispose();
    _scrollAwareContext.dispose();
    _disposeImageInfo();
    super.dispose();
  }

  /// Safely disposes the current [ImageInfo] after the frame completes.
  void _disposeImageInfo() {
    final oldInfo = _imageInfo;
    _imageInfo = null;
    if (oldInfo != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => oldInfo.dispose());
    }
  }

  /// Updates [_invertColors] based on accessibility settings.
  void _updateInvertColors() {
    _invertColors = MediaQuery.maybeOf(context)?.invertColors ??
        SemanticsBinding.instance.accessibilityFeatures.invertColors;
  }

  /// Subscribes or unsubscribes from the image stream based on ticker mode.
  void _updateStreamSubscription() {
    if (TickerMode.of(context)) {
      _listenToStream();
    } else {
      _stopListeningToStream(keepStreamAlive: true);
    }
  }

  /// Reloads the image, bypassing cache.
  ///
  /// Call this method to force a fresh fetch from the network.
  void reloadImage() => _resolveImage(true);

  /// Resolves the image from the provider and sets up the stream.
  void _resolveImage([bool forceReload = false]) {
    if (forceReload) {
      widget.image.evict();
    }

    final provider = ScrollAwareImageProvider<Object>(
      context: _scrollAwareContext,
      imageProvider: widget.image,
    );

    final newStream = provider.resolve(
      createLocalImageConfiguration(
        context,
        size: _targetSize,
      ),
    );

    if (_imageInfo != null &&
        !forceReload &&
        _imageStream?.key == newStream.key) {
      if (_loadState != LoadState.success) {
        setState(() => _loadState = LoadState.success);
      }
      return;
    }

    _updateSourceStream(newStream, forceReload: forceReload);
  }

  /// Returns the target size for image configuration.
  Size? get _targetSize {
    final w = widget.width;
    final h = widget.height;
    return (w != null && h != null) ? Size(w, h) : null;
  }

  /// Updates the image stream and manages listener lifecycle.
  void _updateSourceStream(ImageStream newStream, {bool forceReload = false}) {
    if (_imageStream?.key == newStream.key) return;

    if (_isListeningToStream) {
      _imageStream?.removeListener(_getListener());
    }

    final shouldResetImage = !widget.gaplessPlayback || forceReload;

    setState(() {
      if (shouldResetImage) {
        _disposeImageInfo();
        _loadState = LoadState.loading;
      }
      _frameNumber = null;
      _wasSynchronouslyLoaded = false;
      _imageStream = newStream;
    });

    if (_isListeningToStream) {
      _imageStream!.addListener(_getListener());
    }
  }

  /// Returns the cached listener or creates a new one.
  ImageStreamListener _getListener({bool recreate = false}) {
    if (_imageStreamListener == null || recreate) {
      _imageStreamListener = ImageStreamListener(
        _handleImageFrame,
        onChunk: _handleImageChunk,
        onError: _handleLoadError,
      );
    }
    return _imageStreamListener!;
  }

  /// Recreates the listener when the loading builder changes.
  void _recreateListener() {
    final oldListener = _getListener();
    _imageStream!.addListener(_getListener(recreate: true));
    _imageStream!.removeListener(oldListener);
  }

  /// Starts listening to the image stream.
  void _listenToStream() {
    if (_isListeningToStream) return;

    _imageStream!.addListener(_getListener());
    _completerHandle?.dispose();
    _completerHandle = null;
    _isListeningToStream = true;
  }

  /// Stops listening to the image stream.
  void _stopListeningToStream({bool keepStreamAlive = false}) {
    if (!_isListeningToStream) return;

    if (keepStreamAlive && _completerHandle == null) {
      _completerHandle = _imageStream?.completer?.keepAlive();
    }

    _imageStream?.removeListener(_getListener());
    _isListeningToStream = false;
  }

  /// Handles progress updates during image loading.
  void _handleImageChunk(ImageChunkEvent event) {
    if (_loadingProgress == event) return;
    setState(() {
      _loadingProgress = event;
      _clearError();
    });
  }

  /// Handles successful image frame decoding.
  void _handleImageFrame(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _replaceImage(imageInfo);
      _loadState = LoadState.success;
      _clearError();
      _frameNumber = (_frameNumber ?? -1) + 1;
      _wasSynchronouslyLoaded = _wasSynchronouslyLoaded || synchronousCall;
    });
  }

  /// Handles image loading errors.
  void _handleLoadError(Object exception, StackTrace? stackTrace) {
    setState(() {
      _lastException = exception;
      _lastStack = stackTrace;
      _loadState = LoadState.error;
    });
    scheduleMicrotask(() => widget.image.evict());
  }

  /// Clears the stored error state.
  void _clearError() {
    _lastException = null;
    _lastStack = null;
  }

  /// Replaces the current image with a new one.
  void _replaceImage(ImageInfo? info) {
    _disposeImageInfo();
    _imageInfo = info;
  }

  @override
  Widget build(BuildContext context) {
    Widget current = _buildImageContent();
    current = _applyShape(current);
    current = _applyBorder(current);
    current = _applyConstraints(current);
    current = _applyTapHandler(current);
    return _applySemantics(current);
  }

  /// Builds the appropriate widget based on loading state.
  Widget _buildImageContent() {
    return switch (_loadState) {
      LoadState.loading => _buildLoadingWidget(),
      LoadState.error => _buildErrorWidget(),
      LoadState.success => _buildSuccessWidget(),
    };
  }

  /// Builds the loading state widget.
  Widget _buildLoadingWidget() {
    return widget.loadingBuilder?.call(
          context,
          _loadingProgress?.cumulativeBytesLoaded ?? 0,
          _loadingProgress?.expectedTotalBytes ?? 0,
        ) ??
        _AwsImageLoader(
          width: widget.width,
          height: widget.height,
          color: widget.color,
          colorBlendMode: widget.colorBlendMode,
          shape: widget.shape,
          borderRadius: widget.borderRadius,
        );
  }

  /// Builds the error state widget.
  Widget _buildErrorWidget() {
    return widget.errorBuilder?.call(
          context,
          _lastException ?? 'Error while loading image',
          _lastStack,
        ) ??
        _AwsImageError(
          width: widget.width,
          height: widget.height,
          color: widget.color,
          colorBlendMode: widget.colorBlendMode,
          error: _lastException,
          stackTrace: _lastStack,
          onRetry: reloadImage,
          shape: widget.shape,
          borderRadius: widget.borderRadius,
        );
  }

  /// Builds the success state widget with the loaded image.
  Widget _buildSuccessWidget() {
    return RawImage(
      image: _imageInfo?.image,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
      isAntiAlias: widget.isAntiAlias,
      filterQuality: widget.filterQuality,
      scale: widget.scale,
      opacity: widget.opacity,
      invertColors: _invertColors,
    );
  }

  /// Applies shape clipping (circle or rounded rectangle).
  Widget _applyShape(Widget child) {
    final shape = widget.shape;
    if (shape == null) return child;

    return switch (shape) {
      BoxShape.circle => ClipOval(
          clipBehavior: widget.clipBehavior,
          child: child,
        ),
      BoxShape.rectangle when widget.borderRadius != null => ClipRRect(
          borderRadius: widget.borderRadius!,
          clipBehavior: widget.clipBehavior,
          child: child,
        ),
      _ => child,
    };
  }

  /// Applies border painting.
  Widget _applyBorder(Widget child) {
    final border = widget.border;
    if (border == null) return child;

    return CustomPaint(
      foregroundPainter: AwsImageBorderPainter(
        borderRadius: widget.borderRadius,
        border: border,
        shape: widget.shape ?? BoxShape.rectangle,
      ),
      child: child,
    );
  }

  /// Applies size constraints.
  Widget _applyConstraints(Widget child) {
    final constraints = widget.constraints;
    if (constraints == null) return child;

    return ConstrainedBox(
      constraints: constraints,
      child: child,
    );
  }

  /// Wraps with tap handler if provided.
  Widget _applyTapHandler(Widget child) {
    final onTap = widget.onTap;
    if (onTap == null) return child;

    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }

  /// Wraps with semantics for accessibility.
  Widget _applySemantics(Widget child) {
    if (widget.excludeFromSemantics) return child;

    return Semantics(
      container: widget.semanticLabel != null,
      image: true,
      label: widget.semanticLabel ?? parseCacheKey(widget.url),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ImageStream>('stream', _imageStream))
      ..add(DiagnosticsProperty<ImageInfo>('pixels', _imageInfo))
      ..add(DiagnosticsProperty<ImageChunkEvent>(
        'loadingProgress',
        _loadingProgress,
      ))
      ..add(IntProperty('frameNumber', _frameNumber))
      ..add(DiagnosticsProperty<bool>(
        'wasSynchronouslyLoaded',
        _wasSynchronouslyLoaded,
      ));
  }
}

/// Default error widget displaying a broken link icon with retry capability.
/// Tapping the widget triggers [onRetry] to reload the image.
class _AwsImageError extends StatelessWidget {
  const _AwsImageError({
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.shape,
    this.borderRadius,
    this.error,
    this.stackTrace,
    this.onRetry,
  });

  /// Default size when no dimensions are provided.
  static const double _defaultSize = 100.0;

  /// Default icon size ratio relative to container.
  static const double _iconSizeRatio = 0.35;

  /// Minimum icon size.
  static const double _minIconSize = 24.0;

  /// Maximum icon size.
  static const double _maxIconSize = 64.0;

  /// Width of the error container.
  final double? width;

  /// Height of the error container.
  final double? height;

  /// Color to apply to the error icon.
  final Color? color;

  /// Blend mode for the icon color.
  final BlendMode? colorBlendMode;

  /// Shape of the error placeholder.
  final BoxShape? shape;

  /// Border radius for rounded corners.
  final BorderRadius? borderRadius;

  /// The error that caused the load failure.
  final Object? error;

  /// Stack trace associated with the error.
  final StackTrace? stackTrace;

  /// Callback to retry loading the image.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        color?.withValues(alpha: 0.1) ?? Colors.grey.shade200;
    final iconColor = color ?? Theme.of(context).colorScheme.error;

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = _calculateWidth(constraints);
        final effectiveHeight = _calculateHeight(constraints);
        final iconSize = _calculateIconSize(effectiveWidth, effectiveHeight);

        return GestureDetector(
          onTap: onRetry,
          child: SizedBox(
            width: effectiveWidth,
            height: effectiveHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: shape ?? BoxShape.rectangle,
                borderRadius: shape == BoxShape.circle ? null : borderRadius,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/broken_link.svg',
                  package: 'aws_image',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  colorFilter: _buildColorFilter(iconColor),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Calculates effective width based on widget config and constraints.
  double _calculateWidth(BoxConstraints constraints) {
    // 1. Explicit width provided
    if (width != null) return width!;

    // 2. Parent has tight width (e.g., SizedBox, Container with width)
    if (constraints.hasTightWidth) {
      return constraints.maxWidth;
    }

    // 3. Explicit height provided - make it square
    if (height != null) return height!;

    // 4. Parent has tight height - make it square
    if (constraints.hasTightHeight) {
      return constraints.maxHeight;
    }

    // 5. Both dimensions are loose/unbounded - use default
    return _defaultSize;
  }

  /// Calculates effective height based on widget config and constraints.
  double _calculateHeight(BoxConstraints constraints) {
    // 1. Explicit height provided
    if (height != null) return height!;

    // 2. Parent has tight height (e.g., SizedBox, Container with height)
    if (constraints.hasTightHeight) {
      return constraints.maxHeight;
    }

    // 3. Explicit width provided - make it square
    if (width != null) return width!;

    // 4. Parent has tight width - make it square
    if (constraints.hasTightWidth) {
      return constraints.maxWidth;
    }

    // 5. Both dimensions are loose/unbounded - use default
    return _defaultSize;
  }

  /// Calculates icon size based on container dimensions.
  double _calculateIconSize(double containerWidth, double containerHeight) {
    final smallerDimension =
        containerWidth < containerHeight ? containerWidth : containerHeight;
    final calculatedSize = smallerDimension * _iconSizeRatio;
    return calculatedSize.clamp(_minIconSize, _maxIconSize);
  }

  /// Builds the color filter for the SVG icon.
  ColorFilter _buildColorFilter(Color iconColor) {
    return ColorFilter.mode(
      iconColor,
      colorBlendMode ?? BlendMode.srcIn,
    );
  }
}

/// Default loading widget displaying a shimmer skeleton effect.
class _AwsImageLoader extends StatefulWidget {
  const _AwsImageLoader({
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.shape,
    this.borderRadius,
  });

  /// Default size when no dimensions are provided.
  static const double _defaultSize = 100.0;

  /// Width of the loading container.
  final double? width;

  /// Height of the loading container.
  final double? height;

  /// Base color for the shimmer effect.
  final Color? color;

  /// Blend mode (unused, kept for API consistency).
  final BlendMode? colorBlendMode;

  /// Shape of the loading placeholder.
  final BoxShape? shape;

  /// Border radius for rounded corners.
  final BorderRadius? borderRadius;

  @override
  State<_AwsImageLoader> createState() => _AwsImageLoaderState();
}

class _AwsImageLoaderState extends State<_AwsImageLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Colors.grey.shade300;
    final highlightColor = Color.lerp(baseColor, Colors.white, 0.5)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = _calculateWidth(constraints);
        final effectiveHeight = _calculateHeight(constraints);

        return SizedBox(
          width: effectiveWidth,
          height: effectiveHeight,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  shape: widget.shape ?? BoxShape.rectangle,
                  borderRadius: widget.shape == BoxShape.circle
                      ? null
                      : widget.borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      baseColor,
                      highlightColor,
                      baseColor,
                    ],
                    stops: [
                      0.0,
                      (0.5 + _animation.value * 0.25).clamp(0.0, 1.0),
                      1.0,
                    ],
                    transform: _ShimmerGradientTransform(_animation.value),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Calculates effective width based on widget config and constraints.
  double _calculateWidth(BoxConstraints constraints) {
    // 1. Explicit width provided
    if (widget.width != null) return widget.width!;

    // 2. Parent has tight width (e.g., SizedBox, Container with width)
    if (constraints.hasTightWidth) {
      return constraints.maxWidth;
    }

    // 3. Explicit height provided - make it square
    if (widget.height != null) return widget.height!;

    // 4. Parent has tight height - make it square
    if (constraints.hasTightHeight) {
      return constraints.maxHeight;
    }

    // 5. Both dimensions are loose/unbounded - use default
    return _AwsImageLoader._defaultSize;
  }

  /// Calculates effective height based on widget config and constraints.
  double _calculateHeight(BoxConstraints constraints) {
    // 1. Explicit height provided
    if (widget.height != null) return widget.height!;

    // 2. Parent has tight height (e.g., SizedBox, Container with height)
    if (constraints.hasTightHeight) {
      return constraints.maxHeight;
    }

    // 3. Explicit width provided - make it square
    if (widget.width != null) return widget.width!;

    // 4. Parent has tight width - make it square
    if (constraints.hasTightWidth) {
      return constraints.maxWidth;
    }

    // 5. Both dimensions are loose/unbounded - use default
    return _AwsImageLoader._defaultSize;
  }
}

/// Transforms the gradient to create a shimmer sweep effect.
class _ShimmerGradientTransform extends GradientTransform {
  const _ShimmerGradientTransform(this.value);

  final double value;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * value * 0.5, 0.0, 0.0);
  }
}
