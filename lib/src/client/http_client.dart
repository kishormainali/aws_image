// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:aws_image/src/client/aws_image_request.dart';
import 'package:dio/dio.dart';
import 'package:fp_logger/fp_logger.dart';
import 'package:mime/mime.dart';

AwsImageClient createAwsImageClient(
  AwsImageRequest request, {
  Map<String, dynamic> headers = const {},
}) {
  if (request is AwsImageGraphqlRequest) {
    return AwsImageClient._(request, headers: headers);
  } else if (request is AwsImageRestRequest) {
    return AwsImageClient._(request, headers: headers);
  } else {
    throw Exception('Invalid request type: ${request.runtimeType}');
  }
}

/// {@template aws_image_client}
/// A client for making requests to AWS S3.
/// It provides methods for getting images, uploading files, and getting
/// presigned URLs.
/// {@endtemplate}
class AwsImageClient {
  /// {@macro aws_image_client}
  AwsImageClient._(
    this.imageRequest, {
    this.headers = const {},
  });

  /// {@macro aws_image_client}
  factory AwsImageClient(
    AwsImageRequest request, {
    Map<String, dynamic> headers = const {},
  }) =>
      createAwsImageClient(request, headers: headers);

  /// Singleton instance of Dio
  final _dio = Dio();

  /// The request object containing the base URL and other configurations.
  final AwsImageRequest imageRequest;

  /// default headers for aws client
  final Map<String, dynamic> headers;

  /// Get updated presigned URL
  Future<String?> getPresignedUrl(
    String bucketKey, {
    String? contentType,
    String method = 'GET',
  }) async {
    final response = await imageRequest.request(
      bucketKey,
      contentType: contentType,
      method: method,
    );
    return response;
  }

  /// get image bytes from url
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
              ...this.headers,
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

  /// upload image to S3
  Future<dynamic> uploadFile({
    required String presignedUrl,
    required File image,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> queryParameters = const {},
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final mimeType = lookupMimeType(image.path);
      if (mimeType == null) {
        throw Exception(
            'Could not determine mime type for file: ${image.path}');
      }
      final response = await _dio.put(
        presignedUrl,
        data: image.openRead(),
        queryParameters: queryParameters,
        options: Options(
          method: 'PUT',
          contentType: mimeType,
          headers: {
            ...headers,
            HttpHeaders.acceptHeader: '*/*',
            HttpHeaders.contentLengthHeader: image.readAsBytesSync().length,
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
    } on DioException catch (error, stackTrace) {
      Logger.e(
        'Failed to upload file: ${error.message}',
        error: error,
        stackTrace: stackTrace,
        tag: 'AwsImageClient',
      );
      return null;
    } catch (error, stackTrace) {
      if (error is DioException) rethrow;
      Logger.e(
        'Failed to upload file: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
        tag: 'AwsImageClient',
      );
      return null;
    }
  }
}
