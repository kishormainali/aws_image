import 'dart:io';

import 'package:aws_image/aws_image.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:fp_logger/fp_logger.dart';

/// {@template aws_image_request}
/// A request for an image from AWS.
/// It provides methods for getting images, uploading files, and getting
/// presigned URLs.
/// {@endtemplate}
abstract class AwsImageRequest with EquatableMixin {
  /// {@macro aws_image_request}
  const AwsImageRequest({
    required this.baseUrl,
    required this.responseParser,
    required this.requestTransformer,
    this.headers = const {},
    this.enableLogging = false,
  });

  /// The base URL for the request.
  final String baseUrl;

  /// The headers for the request.
  final Map<String, String> headers;

  /// The response parser for the request.
  final PresignedUrlResponseParser responseParser;

  /// The request transformer for the request.
  final PresignedRequestTransformer requestTransformer;

  /// Whether to enable logging for the request.
  final bool enableLogging;

  /// request the presigned URL
  Future<String?> request(
    String bucketKey, {
    String? contentType,
    String method = 'GET',
  });

  @override
  List<Object?> get props => [
        baseUrl,
        headers,
        requestTransformer,
        responseParser,
      ];
}

/// {@template aws_image_rest_request}
/// A request for an image from AWS using REST.
/// It provides methods for getting images, uploading files, and getting
/// presigned URLs.
/// {@endtemplate}
class AwsImageRestRequest extends AwsImageRequest {
  /// {@macro aws_image_rest_request}
  AwsImageRestRequest({
    required super.baseUrl,
    super.headers,
    super.requestTransformer = const DefaultRestPresignedRequestTransformer(),
    super.responseParser = const DefaultRestResponseParser(),
    super.enableLogging = false,
    this.queryParameters = const {},
  });

  /// The query parameters for the request.
  final Map<String, String> queryParameters;

  /// Dio instance for making requests
  late final _dio = Dio()
    ..interceptors.add(DioLogger(
      requestHeader: false,
      requestBody: kDebugMode && enableLogging,
      responseBody: kDebugMode && enableLogging,
      error: kDebugMode && enableLogging,
    ));

  @override
  Future<String?> request(
    String bucketKey, {
    String? contentType,
    String method = 'GET',
  }) async {
    try {
      final response = await _dio.get(
        baseUrl,
        queryParameters: queryParameters,
        data: requestTransformer.transformRequest(
          bucketKey,
          contentType: contentType,
          method: method,
        ),
        options: Options(
          contentType: 'application/json',
          headers: {
            HttpHeaders.acceptHeader: 'application/json',
            ...headers,
          },
        ),
      );

      if (response.statusCode == 200) {
        return responseParser.parseResponse(response);
      } else {
        throw DioException.badResponse(
          statusCode: response.statusCode ?? 500,
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } on DioException catch (error, stackTrace) {
      Logger.e(
        'Failed to get presigned URL: ${error.message}',
        error: error,
        stackTrace: stackTrace,
        tag: 'AwsImageClient',
      );
      return null;
    } catch (error, stackTrace) {
      if (error is DioException) rethrow;
      Logger.e(
        'Failed to get presigned URL: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
        tag: 'AwsImageClient',
      );
      return null;
    }
  }

  @override
  List<Object?> get props => [
        ...super.props,
        queryParameters,
      ];
}

/// {@template aws_image_graphql_request}
/// A request for an image from AWS using GraphQL.
/// It provides methods for getting images, uploading files, and getting
/// presigned URLs.
/// {@endtemplate}
class AwsImageGraphqlRequest extends AwsImageRequest {
  /// {@macro aws_image_graphql_request}
  AwsImageGraphqlRequest({
    required super.baseUrl,
    required this.query,
    super.headers,
    super.requestTransformer = const DefaultGqlPresignedRequestTransformer(),
    super.enableLogging = false,
    this.operationName,
    PresignedUrlResponseParser? responseParser,
  })  : assert(() {
          if (query.isEmpty) {
            throw ArgumentError('Query cannot be empty');
          }
          if (!isValidQuery(query)) {
            throw ArgumentError('Query is not valid');
          }
          return true;
        }()),
        super(
          responseParser:
              responseParser ?? DefaultGqlResponseParser(query: query),
        );

  /// The GraphQL query for the request.
  final String query;

  /// The operation name for the request.
  final String? operationName;

  /// Dio instance for making requests
  late final _dio = Dio()
    ..interceptors.add(GraphqlDioLogger(
      requestHeader: false,
      requestBody: kDebugMode && enableLogging,
      responseBody: kDebugMode && enableLogging,
      error: kDebugMode && enableLogging,
    ));

  @override
  Future<String?> request(
    String bucketKey, {
    String? contentType,
    String method = 'GET',
  }) async {
    try {
      String? operation = operationName ?? parseOperationName(query);
      final response = await _dio.post(
        baseUrl,
        data: {
          'query': query,
          'variables': requestTransformer.transformRequest(
            bucketKey,
            contentType: contentType,
            method: method,
          ),
          if (operation != null) 'operationName': operation,
        },
        options: Options(
          contentType: 'application/json',
          headers: {
            ...headers,
            HttpHeaders.acceptHeader: 'application/json',
          },
        ),
      );

      if (response.data is! Map<String, dynamic> ||
          response.data['errors'] != null ||
          response.data['data'] == null ||
          response.data['data'] is! Map<String, dynamic>) {
        throw DioException.badResponse(
          statusCode: response.statusCode ?? 500,
          requestOptions: response.requestOptions,
          response: response,
        );
      }
      return responseParser.parseResponse(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error, stackTrace) {
      Logger.e(
        'Failed to get presigned URL: ${error.message}',
        error: error,
        stackTrace: stackTrace,
        tag: 'AwsImageClient',
      );
      return null;
    } catch (error, stackTrace) {
      if (error is DioException) rethrow;
      Logger.e(
        'Failed to get presigned URL: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
        tag: 'AwsImageClient',
      );
      return null;
    }
  }

  @override
  List<Object?> get props => [
        ...super.props,
        query,
        operationName,
      ];
}
