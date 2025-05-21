import 'dart:async';

import 'package:aws_image/aws_image.dart';
import 'package:aws_image/src/providers/_aws_image_resize.dart';
import 'package:aws_image/src/utils/_extensions.dart';
import 'package:aws_image/src/widgets/border_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';

/// load state of the image
enum LoadState {
  /// loading state
  loading,

  /// success state
  success,

  /// error state
  error,
}

/// {@template aws_image}
/// A widget that displays an image from AWS S3.
/// It handles caching, loading from network, and refreshing expired URLs.
/// {@endtemplate}
class AwsImage extends StatefulWidget {
  /// {@macro aws_image}
  AwsImage({
    super.key,
    this.presignedUrl,
    this.bucketKey,
    required this.imageClient,
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
  })  : assert(
          presignedUrl.isNotNullOrEmpty || bucketKey.isNotNullOrEmpty,
          'At least one of presignedUrl or bucketKey must be provided.',
        ),
        assert(constraints == null || constraints.debugAssertIsValid()),
        assert(cacheWidth == null || cacheWidth > 0),
        assert(cacheHeight == null || cacheHeight > 0),
        constraints = (width != null || height != null)
            ? constraints?.tighten(
                  width: width,
                  height: height,
                ) ??
                BoxConstraints.tightFor(
                  width: width,
                  height: height,
                )
            : constraints,
        image = AwsResizeImage.resizeIfNeeded(
          provider: AwsImageProvider(
            presignedUrl: presignedUrl,
            bucketKey: bucketKey,
            imageClient: imageClient,
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

  /// Presigned URL to retrieve the image
  final String? presignedUrl;

  /// Bucket key to retrieve the image
  final String? bucketKey;

  /// AWS image client to retrieve and refresh the image
  final AwsImageClient imageClient;

  /// Headers to be sent with the request.
  final Map<String, dynamic> headers;

  /// Query parameters to be sent with the request.
  final Map<String, dynamic> queryParameters;

  /// image provider
  /// The image provider to be used to load the image.
  final ImageProvider image;

  /// semantic label for the image
  final String? semanticLabel;

  /// Whether to exclude the image from semantics.
  final bool excludeFromSemantics;

  /// The width of the image.
  final double? width;

  /// The height of the image.
  final double? height;

  /// The width of the image in the cache.
  final int? cacheWidth;

  /// The height of the image in the cache.
  final int? cacheHeight;

  /// The color to be applied to the image.
  final Color? color;

  /// The opacity of the image.
  final Animation<double>? opacity;

  /// The blend mode to be used for the color.
  final BlendMode? colorBlendMode;

  /// The fit of the image.
  final BoxFit? fit;

  /// The alignment of the image.
  final Alignment alignment;

  /// The repeat mode of the image.
  final ImageRepeat repeat;

  /// The center slice of the image.
  final Rect? centerSlice;

  /// match text direction
  final bool matchTextDirection;

  /// whether to use gapless playback
  /// This is used to prevent flickering when the image is reloaded.
  final bool gaplessPlayback;

  /// anti aliasing
  /// This is used to prevent aliasing artifacts in the image.
  final bool isAntiAlias;

  /// The filter quality of the image.
  final FilterQuality filterQuality;

  /// The shape of the image.
  final BoxShape? shape;

  /// The border of the image.
  /// This is used to draw a border around the image.
  final Border? border;

  /// The border radius of the image.
  final BorderRadius? borderRadius;

  /// The callback to be called when the image is tapped.
  final VoidCallback? onTap;

  /// The clip behavior of the image.
  final Clip clipBehavior;

  /// The constraints of the image.
  final BoxConstraints? constraints;

  /// The compression ratio of the image.
  final double? compressionRatio;

  /// The border of the image.
  final int? maxBytes;

  /// scale of the image
  final double scale;

  /// The duration for which the image should be cached.
  final Duration cacheDuration;

  /// The maximum number of retries to load the image from the network.
  final int maxRetries;

  /// Whether to force refresh the image.
  final bool forceRefresh;

  /// The delay between retries.
  final Duration retryDelay;

  /// The loading builder to be used to show a loading indicator.
  final AwsImageLoadingBuilder? loadingBuilder;

  /// The error builder to be used to show an error indicator.
  final AwsImageErrorBuilder? errorBuilder;

  @override
  State<AwsImage> createState() => _AwsImageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageProvider>('image', image));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(
      DiagnosticsProperty<Animation<double>?>(
        'opacity',
        opacity,
        defaultValue: null,
      ),
    );
    properties.add(
      EnumProperty<BlendMode>(
        'colorBlendMode',
        colorBlendMode,
        defaultValue: null,
      ),
    );
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(
      DiagnosticsProperty<AlignmentGeometry>(
        'alignment',
        alignment,
        defaultValue: null,
      ),
    );
    properties.add(
      EnumProperty<ImageRepeat>(
        'repeat',
        repeat,
        defaultValue: ImageRepeat.noRepeat,
      ),
    );
    properties.add(
      DiagnosticsProperty<Rect>('centerSlice', centerSlice, defaultValue: null),
    );
    properties.add(
      FlagProperty(
        'matchTextDirection',
        value: matchTextDirection,
        ifTrue: 'match text direction',
      ),
    );
    properties.add(
      StringProperty('semanticLabel', semanticLabel, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<bool>(
        'this.excludeFromSemantics',
        excludeFromSemantics,
      ),
    );
    properties.add(EnumProperty<FilterQuality>('filterQuality', filterQuality));
  }
}

class _AwsImageState extends State<AwsImage> with WidgetsBindingObserver {
  late LoadState _loadState;
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  bool _isListeningToStream = false;
  late bool _invertColors;
  ImageChunkEvent? _loadingProgress;
  int? _frameNumber;
  bool _wasSynchronouslyLoaded = false;
  late DisposableBuildContext<State<AwsImage>> _scrollAwareContext;
  Object? _lastException;
  StackTrace? _lastStack;
  ImageStreamCompleterHandle? _completerHandle;

  ImageStreamListener? _imageStreamListener;

  LoadState get loadState => _loadState;

  /// reload image
  void reloadImage() {
    _resolveImage(true);
  }

  @override
  void didChangeAccessibilityFeatures() {
    super.didChangeAccessibilityFeatures();
    setState(() {
      _updateInvertColors();
    });
  }

  @override
  void didChangeDependencies() {
    _updateInvertColors();
    _resolveImage();
    if (TickerMode.of(context)) {
      _listenToStream();
    } else {
      _stopListeningToStream(keepStreamAlive: true);
    }

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(AwsImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isListeningToStream &&
        oldWidget.loadingBuilder != widget.loadingBuilder) {
      final ImageStreamListener oldListener = _getListener();
      _imageStream!.addListener(_getListener(recreateListener: true));
      _imageStream!.removeListener(oldListener);
    }
    if (widget.image != oldWidget.image) {
      _resolveImage();
    }
    if (widget.forceRefresh != oldWidget.forceRefresh) {
      _resolveImage(true);
    }
  }

  @override
  void dispose() {
    assert(_imageStream != null);
    WidgetsBinding.instance.removeObserver(this);
    _stopListeningToStream();
    _completerHandle?.dispose();
    _scrollAwareContext.dispose();
    _replaceImage(info: null);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadState = LoadState.loading;
    WidgetsBinding.instance.addObserver(this);
    _scrollAwareContext = DisposableBuildContext<State<AwsImage>>(this);
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageStream>('stream', _imageStream));
    properties.add(DiagnosticsProperty<ImageInfo>('pixels', _imageInfo));
    properties.add(
      DiagnosticsProperty<ImageChunkEvent>('loadingProgress', _loadingProgress),
    );
    properties.add(DiagnosticsProperty<int>('frameNumber', _frameNumber));
    properties.add(
      DiagnosticsProperty<bool>(
        'wasSynchronouslyLoaded',
        _wasSynchronouslyLoaded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget? current = switch (_loadState) {
      LoadState.loading => widget.loadingBuilder?.call(
            context,
            _loadingProgress?.cumulativeBytesLoaded ?? 0,
            _loadingProgress?.expectedTotalBytes ?? 0,
          ) ??
          _AwsImageLoader(
            width: widget.width,
            height: widget.height,
            color: widget.color,
            colorBlendMode: widget.colorBlendMode,
          ),
      LoadState.error => widget.errorBuilder?.call(
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
            onRetry: () => reloadImage(),
          ),
      LoadState.success => RawImage(
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
        ),
    };

    if (widget.shape != null) {
      switch (widget.shape!) {
        case BoxShape.circle:
          current = ClipOval(
            clipBehavior: widget.clipBehavior,
            child: current,
          );
          break;
        case BoxShape.rectangle:
          if (widget.borderRadius != null) {
            current = ClipRRect(
              borderRadius: widget.borderRadius!,
              clipBehavior: widget.clipBehavior,
              child: current,
            );
          }
          break;
      }
    }

    if (widget.border != null) {
      current = CustomPaint(
        foregroundPainter: AwsImageBorderPainter(
          borderRadius: widget.borderRadius,
          border: widget.border,
          shape: widget.shape ?? BoxShape.rectangle,
        ),
        size: widget.width != null && widget.height != null
            ? Size(widget.width!, widget.height!)
            : Size.zero,
        child: current,
      );
    }

    if (widget.constraints != null) {
      current = ConstrainedBox(
        constraints: widget.constraints!,
        child: current,
      );
    }

    if (widget.onTap != null) {
      current = GestureDetector(
        onTap: widget.onTap,
        child: current,
      );
    }

    if (widget.excludeFromSemantics) {
      return current;
    }

    return Semantics(
      container: widget.semanticLabel != null,
      image: true,
      label: widget.semanticLabel ??
          parseCacheKey(
            widget.presignedUrl,
            widget.bucketKey,
          ),
      child: current,
    );
  }

  ImageStreamListener _getListener({bool recreateListener = false}) {
    if (_imageStreamListener == null || recreateListener) {
      _lastException = null;
      _lastStack = null;
      _imageStreamListener = ImageStreamListener(
        _handleImageFrame,
        onChunk: _handleImageChunk,
        onError: _loadFailed,
      );
    }
    return _imageStreamListener!;
  }

  void _handleImageChunk(ImageChunkEvent event) {
    setState(() {
      _lastException = null;
      _lastStack = null;
    });
  }

  void _handleImageFrame(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _replaceImage(info: imageInfo);
      _loadState = LoadState.success;
      _lastException = null;
      _lastStack = null;
      _frameNumber = _frameNumber == null ? 0 : _frameNumber! + 1;
      _wasSynchronouslyLoaded = _wasSynchronouslyLoaded | synchronousCall;
    });
  }

  void _listenToStream() {
    if (_isListeningToStream) {
      return;
    }
    _imageStream!.addListener(_getListener());
    _completerHandle?.dispose();
    _completerHandle = null;
    _isListeningToStream = true;
  }

  void _loadFailed(dynamic exception, StackTrace? stackTrace) {
    setState(() {
      _lastStack = stackTrace;
      _lastException = exception;
      _loadState = LoadState.error;
    });
    scheduleMicrotask(() {
      widget.image.evict();
    });
  }

  void _replaceImage({required ImageInfo? info}) {
    final ImageInfo? oldImageInfo = _imageInfo;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => oldImageInfo?.dispose(),
    );
    _imageInfo = info;
  }

  void _resolveImage([bool rebuild = false]) {
    if (rebuild) {
      widget.image.evict();
    }

    final ScrollAwareImageProvider provider = ScrollAwareImageProvider<Object>(
      context: _scrollAwareContext,
      imageProvider: widget.image,
    );

    final ImageStream newStream = provider.resolve(
      createLocalImageConfiguration(
        context,
        size: widget.width != null && widget.height != null
            ? Size(widget.width!, widget.height!)
            : null,
      ),
    );

    if (_imageInfo != null && !rebuild && _imageStream?.key == newStream.key) {
      setState(() {
        _loadState = LoadState.success;
      });
    }

    _updateSourceStream(newStream, rebuild: rebuild);
  }

  /// Stops listening to the image stream, if this state object has attached a
  /// listener.
  ///
  /// If the listener from this state is the last listener on the stream, the
  /// stream will be disposed. To keep the stream alive, set `keepStreamAlive`
  /// to true, which create [ImageStreamCompleterHandle] to keep the completer
  /// alive and is compatible with the [TickerMode] being off.
  void _stopListeningToStream({bool keepStreamAlive = false}) {
    if (!_isListeningToStream) {
      return;
    }
    if (keepStreamAlive &&
        _completerHandle == null &&
        _imageStream?.completer != null) {
      _completerHandle = _imageStream!.completer!.keepAlive();
    }
    _imageStream!.removeListener(_getListener());
    _isListeningToStream = false;
  }

  void _updateInvertColors() {
    _invertColors = MediaQuery.maybeOf(context)?.invertColors ??
        SemanticsBinding.instance.accessibilityFeatures.invertColors;
  }

  void _updateSourceStream(ImageStream newStream, {bool rebuild = false}) {
    if (_imageStream?.key == newStream.key) {
      return;
    }

    if (_isListeningToStream) {
      _imageStream?.removeListener(_getListener());
    }

    if (!widget.gaplessPlayback || rebuild) {
      setState(() {
        _replaceImage(info: null);
        _loadState = LoadState.loading;
      });
    }

    setState(() {
      _frameNumber = null;
      _wasSynchronouslyLoaded = false;
    });

    _imageStream = newStream;
    if (_isListeningToStream) {
      _imageStream!.addListener(_getListener());
    }
  }
}

class _AwsImageError extends StatelessWidget {
  const _AwsImageError({
    required this.width,
    required this.height,
    required this.error,
    required this.stackTrace,
    this.color,
    this.colorBlendMode,
    this.onRetry,
  });

  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Object? error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/broken_link.svg',
            package: 'aws_image',
            width: width != null ? width! / 3 : null,
            height: height != null ? height! / 3 : null,
            fit: BoxFit.cover,
            colorFilter: color != null && colorBlendMode != null
                ? ColorFilter.mode(
                    color!,
                    colorBlendMode!,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _AwsImageLoader extends StatelessWidget {
  const _AwsImageLoader({
    required this.width,
    required this.height,
    required this.color,
    required this.colorBlendMode,
  });

  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color ?? Colors.transparent,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
