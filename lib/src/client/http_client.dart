// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:aws_image/src/client/enums.dart';
import 'package:aws_image/src/client/response/aws_response.dart';

import '_client_impl.dart';
import 'requests/aws_image_request.dart';

/// {@template aws_image_client}
/// A client for making requests to AWS S3.
/// It provides methods for getting images, uploading files, and getting
/// presigned URLs.
/// {@endtemplate}
abstract class AwsImageClient {
  ///{@macro aws_image_client}
  factory AwsImageClient({
    AwsImageRequest? request,
    Map<String, dynamic> headers = const {},
  }) {
    return AwsImageClientImpl(
      request: request,
      headers: headers,
    );
  }

  /// Get updated presigned URL
  Future<AwsResponse?> getPresignedUrl(
    String bucketKey, {
    String? contentType,
    AwsUrlType type = AwsUrlType.GET,
  });

  /// get image bytes from url
  Future<Uint8List?> getImage({
    required String url,
    Map<String, dynamic> queryParameters = const {},
    Map<String, dynamic> headers = const {},
    void Function(int, int)? onReceiveProgress,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    void Function(Object error, StackTrace stackTrace)? onError,
  });

  /// get presigned URL and upload image to S3
  Future<AwsResponse?> getAndUploadFile({
    required String bucketKey,
    required File image,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> queryParameters = const {},
    Map<String, dynamic> uploadHeaders = const {},
    Map<String, dynamic> uploadQueryParameters = const {},
    void Function(int, int)? onSendProgress,
    void Function(Object error, StackTrace stackTrace)? onError,
  });

  /// upload image to S3
  Future<dynamic> uploadFile({
    required String uploadUrl,
    required File image,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> queryParameters = const {},
    void Function(int, int)? onSendProgress,
  });
}
