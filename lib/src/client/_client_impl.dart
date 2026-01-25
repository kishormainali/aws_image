import 'dart:io';
import 'dart:typed_data';

import 'package:aws_image/src/client/enums.dart';
import 'package:aws_image/src/client/exceptions/aws_exception.dart';
import 'package:aws_image/src/client/requests/aws_image_request.dart';
import 'package:aws_image/src/client/response/aws_response.dart';
import 'package:dio/dio.dart';
import 'package:fp_logger/fp_logger.dart';
import 'package:mime/mime.dart';

import 'http_client.dart';

/// {@template aws_image_client}
/// A client for making requests to AWS S3.
/// It provides methods for getting images, uploading files, and getting
/// presigned URLs.
/// {@endtemplate}
class AwsImageClientImpl implements AwsImageClient {
  ///{@macro aws_image_client}
  AwsImageClientImpl({
    AwsImageRequest? request,
    Map<String, dynamic> headers = const {},
  })  : _imageRequest = request,
        _headers = headers;

  /// Optional image request for presigned URL generation
  /// make sure to set while using AwsImageClient
  final AwsImageRequest? _imageRequest;

  /// default headers for aws client
  final Map<String, dynamic> _headers;

  /// Singleton instance of Dio
  static final _dio = Dio();

  /// Get updated presigned URL
  @override
  Future<AwsResponse?> getPresignedUrl(
    String bucketKey, {
    String? contentType,
    AwsUrlType type = AwsUrlType.GET,
  }) async {
    assert(
      _imageRequest != null,
      'AwsImageRequest is not initialized. Please provide an image request for AwsImageClient.',
    );
    return _imageRequest!.request(
      bucketKey,
      contentType: contentType,
      type: type,
    );
  }

  /// get image bytes from url
  @override
  Future<Uint8List?> getImage({
    required String url,
    Map<String, dynamic> queryParameters = const {},
    Map<String, dynamic> headers = const {},
    void Function(int, int)? onReceiveProgress,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final response = await _dio.get<List<int>>(
          url,
          queryParameters: queryParameters,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {
              ..._headers,
              ...headers,
            },
            followRedirects: true,
          ),
          onReceiveProgress: onReceiveProgress,
        );
        if (response.statusCode == 200 && response.data != null) {
          return Uint8List.fromList(response.data!);
        } else {
          throw DioException.badResponse(
            statusCode: response.statusCode ?? 500,
            requestOptions: response.requestOptions,
            response: response,
          );
        }
      } on DioException catch (e, stackTrace) {
        final bool canRetry = [
          DioExceptionType.cancel,
          DioExceptionType.connectionTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.connectionError,
        ].contains(e.type);

        if (!canRetry) {
          Logger.e(
            'Failed to get image: ${e.message}',
            error: e,
            stackTrace: stackTrace,
            tag: 'AwsImageClient',
          );
          if (onError != null) onError(e, stackTrace);
          break;
        }
        attempts++;
        if (attempts >= maxRetries) {
          Logger.e(
            'Failed to get image after $attempts attempts',
            error: e,
            stackTrace: stackTrace,
            tag: 'AwsImageClient',
          );
          if (onError != null) onError(e, stackTrace);
          break;
        }
        Logger.w(
          'Retrying to get image... Attempt: $attempts',
          tag: 'AwsImageClient',
        );
        await Future.delayed(retryDelay);
      }
    }
    return null;
  }

  @override
  Future<AwsResponse?> getAndUploadFile({
    required String bucketKey,
    required File image,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> queryParameters = const {},
    Map<String, dynamic> uploadHeaders = const {},
    Map<String, dynamic> uploadQueryParameters = const {},
    void Function(int, int)? onSendProgress,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      assert(
        _imageRequest != null,
        'AwsImageRequest is not initialized. Please provide an image request for AwsImageClient.',
      );
      final presignedResponse = await _imageRequest!.request(
        bucketKey,
        contentType: lookupMimeType(image.path),
        type: AwsUrlType.PUT,
      );

      if (presignedResponse?.uploadUrl == null) {
        throw AwsException(
          'Failed to get presigned URL for bucket key: $bucketKey',
        );
      }

      /// upload the file to S3
      await await _upload(
        image,
        presignedResponse!.uploadUrl!,
        uploadHeaders,
        uploadQueryParameters,
        onSendProgress,
      );

      return presignedResponse;
    } catch (error, stackTrace) {
      if (error is DioException) rethrow;
      Logger.e(
        'Failed to upload file: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
        tag: 'AwsImageClient',
      );
      throw AwsException(
        'Failed to get and upload file for bucket key: $bucketKey',
        stackTrace: stackTrace,
        originalError: error,
      );
    }
  }

  /// upload image to S3
  @override
  Future<dynamic> uploadFile({
    required String uploadUrl,
    required File image,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> queryParameters = const {},
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      return await _upload(
        image,
        uploadUrl,
        queryParameters,
        headers,
        onSendProgress,
      );
    } catch (error, stackTrace) {
      if (error is DioException) rethrow;
      Logger.e(
        'Failed to upload file: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
        tag: 'AwsImageClient',
      );
      throw AwsException(
        'Failed to upload file to S3. ${error.toString()}',
        stackTrace: stackTrace,
        originalError: error,
      );
    }
  }

  Future<dynamic> _upload(
    File image,
    String uploadUrl,
    Map<String, dynamic> queryParameters,
    Map<String, dynamic> headers,
    void Function(int, int)? onSendProgress,
  ) async {
    final mimeType = lookupMimeType(image.path);
    if (mimeType == null) {
      throw Exception('Could not determine mime type for file: ${image.path}');
    }
    final response = await _dio.put(
      uploadUrl,
      data: image.openRead(),
      queryParameters: queryParameters,
      options: Options(
        method: 'PUT',
        contentType: mimeType,
        headers: {
          ...headers,
          HttpHeaders.acceptHeader: '*/*',
          HttpHeaders.contentLengthHeader: image.readAsBytesSync().length,
          HttpHeaders.cacheControlHeader: 'public, max-age=31536000',
        },
      ),
      onSendProgress: onSendProgress,
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw DioException.badResponse(
        statusCode: response.statusCode ?? 500,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
  }
}
