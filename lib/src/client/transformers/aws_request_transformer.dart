import 'package:aws_image/src/client/enums.dart';
import 'package:aws_image/src/utils/utils.dart';
import 'package:equatable/equatable.dart';

/// {@template aws_request_transformer}
/// A transformer for AWS presigned requests.
/// It provides methods for transforming the request
/// {@endtemplate}
abstract class RequestTransformer with EquatableMixin {
  const RequestTransformer();

  /// transform the presigned URL into a request
  Map<String, dynamic> transformRequest(
    String bucketKey, {
    String? contentType,
    AwsUrlType type = AwsUrlType.GET,
  });

  @override
  List<Object?> get props => [];
}

/// {@template aws_rest_request_transformer}
/// A transformer for AWS REST presigned requests.
/// It provides methods for transforming the request
/// {@endtemplate}
class DefaultRestRequestTransformer extends RequestTransformer {
  /// {@macro aws_request_transformer}
  const DefaultRestRequestTransformer();

  @override
  Map<String, dynamic> transformRequest(
    String bucketKey, {
    String? contentType,
    AwsUrlType type = AwsUrlType.GET,
  }) {
    return {
      'key': parseBucketKey(bucketKey),
      'contentType': contentType,
      'method': type.name,
    };
  }
}

class DefaultGqlRequestTransformer extends RequestTransformer {
  /// {@macro aws_request_transformer}
  const DefaultGqlRequestTransformer();

  @override
  Map<String, dynamic> transformRequest(
    String bucketKey, {
    String? contentType,
    AwsUrlType type = AwsUrlType.GET,
  }) {
    return {
      'input': {
        'key': parseBucketKey(bucketKey),
        'contentType': contentType,
        'method': type.name,
      },
    };
  }
}
