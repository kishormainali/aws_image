import 'package:aws_image/src/utils/utils.dart';
import 'package:equatable/equatable.dart';

/// {@template aws_request_transformer}
/// A transformer for AWS presigned requests.
/// It provides methods for transforming the request
/// {@endtemplate}
abstract class PresignedRequestTransformer with EquatableMixin {
  const PresignedRequestTransformer();

  /// transform the presigned URL into a request
  Map<String, dynamic> transformRequest(
    String bucketKey, {
    String? contentType,
    String method = 'GET',
  });

  @override
  List<Object?> get props => [];
}

/// {@template aws_rest_request_transformer}
/// A transformer for AWS REST presigned requests.
/// It provides methods for transforming the request
/// {@endtemplate}
class DefaultRestPresignedRequestTransformer
    extends PresignedRequestTransformer {
  /// {@macro aws_request_transformer}
  const DefaultRestPresignedRequestTransformer();

  @override
  Map<String, dynamic> transformRequest(
    String bucketKey, {
    String? contentType,
    String method = 'GET',
  }) {
    return {
      'key': parseBucketKey(bucketKey),
      'contentType': contentType,
      'method': method,
    };
  }
}

class DefaultGqlPresignedRequestTransformer
    extends PresignedRequestTransformer {
  /// {@macro aws_request_transformer}
  const DefaultGqlPresignedRequestTransformer();

  @override
  Map<String, dynamic> transformRequest(
    String bucketKey, {
    String? contentType,
    String method = 'GET',
  }) {
    return {
      'input': {
        'key': bucketKey,
        'contentType': contentType,
        'method': method,
      },
    };
  }
}
