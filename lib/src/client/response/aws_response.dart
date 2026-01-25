import 'package:equatable/equatable.dart';

/// {@template aws_response}
/// A response from AWS S3.
/// It contains the S3 object key, presigned upload URL, and presigned preview URL.
/// {@endtemplate}
class AwsResponse extends Equatable {
  const AwsResponse({
    required this.key,
    this.uploadUrl,
    this.previewUrl,
  });

  /// Create an AwsResponse from a map
  factory AwsResponse.fromMap(Map<String, dynamic> map) {
    return AwsResponse(
      key: map['key'] as String,
      uploadUrl: map['uploadUrl'] as String?,
      previewUrl: map['previewUrl'] as String?,
    );
  }

  /// The S3 object key.
  final String key;

  /// The presigned upload URL.
  final String? uploadUrl;

  /// The presigned preview URL.
  final String? previewUrl;

  @override
  List<Object?> get props => [key, uploadUrl, previewUrl];
}
