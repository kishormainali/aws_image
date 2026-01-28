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
    this.httpMethod = HttpMethod.GET,
  });

  /// The base URL for the request.
  final String baseUrl;

  /// The headers for the request.
  final Map<String, String> headers;

  /// The response parser for the request.
  final ResponseParser responseParser;

  /// The request transformer for the request.
  final RequestTransformer requestTransformer;

  /// Whether to enable logging for the request.
  final bool enableLogging;

  /// The HTTP method for the request to get the presigned URL.
  /// This will be ignored for GraphQL requests as they always use POST.
  final HttpMethod httpMethod;

  /// request the presigned URL
  Future<AwsResponse?> request(
    String bucketKey, {
    String? contentType,
    AwsUrlType type = AwsUrlType.GET,
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
    super.requestTransformer = const DefaultRestRequestTransformer(),
    super.responseParser = const DefaultRestResponseParser(),
    super.enableLogging = false,
    this.queryParameters = const {},
    super.httpMethod = HttpMethod.GET,
  });

  /// The query parameters for the request.
  final Map<String, String> queryParameters;

  /// Dio instance for making requests
  late final _dio = Dio()
    ..interceptors.add(DioLogger(
      loggerOptions: LoggerOptions(
        requestBody: enableLogging && kDebugMode,
        responseBody: enableLogging && kDebugMode,
        requestHeader: false,
        redact: false,
        error: enableLogging && kDebugMode,
        responseHeader: false,
      ),
    ));

  @override
  Future<AwsResponse?> request(
    String bucketKey, {
    String? contentType,
    AwsUrlType type = AwsUrlType.GET,
  }) async {
    try {
      final response = await _dio.request(
        baseUrl,
        queryParameters: queryParameters,
        data: requestTransformer.transformRequest(
          bucketKey,
          contentType: contentType,
          type: type,
        ),
        options: Options(
          contentType: 'application/json',
          method: httpMethod.name,
          headers: {
            HttpHeaders.acceptHeader: 'application/json',
            ...headers,
          },
        ),
      );

      if (response.statusCode == 200) {
        return responseParser.parseResponse(response);
      } else {
        throw AwsException(
          'Failed to get presigned URL: ${response.statusCode} ${response.statusMessage}',
        );
      }
    } catch (error, stackTrace) {
      Logger.e(
        'Failed to get presigned URL: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
        tag: 'AwsImageClient',
      );
      throw AwsException(
        'Failed to get presigned URL: ${error.toString()}',
        stackTrace: stackTrace,
        originalError: error,
      );
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
    super.requestTransformer = const DefaultGqlRequestTransformer(),
    super.enableLogging = false,
    this.operationName,
    ResponseParser? responseParser,
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
          httpMethod: HttpMethod.POST,
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
      loggerOptions: LoggerOptions(
        requestBody: enableLogging && kDebugMode,
        responseBody: enableLogging && kDebugMode,
        requestHeader: false,
        redact: false,
        error: enableLogging && kDebugMode,
        responseHeader: false,
      ),
    ));

  @override
  Future<AwsResponse?> request(
    String bucketKey, {
    String? contentType,
    AwsUrlType type = AwsUrlType.GET,
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
            type: type,
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
        throw AwsException(
          'Failed to get presigned URL: Invalid response format',
        );
      }
      return responseParser.parseResponse(
        response.data as Map<String, dynamic>,
      );
    } catch (error, stackTrace) {
      Logger.e(
        'Failed to get presigned URL: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
        tag: 'AwsImageClient',
      );
      throw AwsException(
        'Failed to get presigned URL: ${error.toString()}',
        stackTrace: stackTrace,
        originalError: error,
      );
    }
  }

  @override
  List<Object?> get props => [
        ...super.props,
        query,
        operationName,
      ];
}
