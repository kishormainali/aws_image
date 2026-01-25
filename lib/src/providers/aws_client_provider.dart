import 'package:aws_image/aws_image.dart';
import 'package:flutter/widgets.dart';

/// {@template aws_client_provider}
/// An InheritedWidget that provides an instance of [AwsImageClient]
/// to its descendants in the widget tree.
/// This allows for easy access to AWS S3 functionalities such as
/// generating presigned URLs, uploading files, and fetching images.
/// {@endtemplate}
class AwsClientProvider extends InheritedWidget {
  ///{@macro aws_client_provider}
  const AwsClientProvider({
    super.key,
    required super.child,
    required this.request,
    this.headers = const {},
  });

  /// Aws Image Request for generating presigned URLs
  final AwsImageRequest request;

  /// Default headers for AWS client
  final Map<String, dynamic> headers;

  /// Method to access the AwsImageClient from the context
  static AwsImageClient of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AwsClientProvider>();
    assert(
      provider != null,
      'No AwsClientProvider found in context. Please wrap your widget tree with AwsClientProvider.',
    );
    return AwsImageClient(
      request: provider!.request,
      headers: provider.headers,
    );
  }

  @override
  bool updateShouldNotify(covariant AwsClientProvider oldWidget) {
    return request != oldWidget.request || headers != oldWidget.headers;
  }
}
