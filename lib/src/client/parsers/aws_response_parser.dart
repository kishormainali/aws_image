import 'dart:convert';

import 'package:aws_image/src/client/enums.dart';
import 'package:aws_image/src/client/response/aws_response.dart';
import 'package:aws_image/src/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:fp_logger/fp_logger.dart';

/// {@template aws_response_parser}
/// A parser for AWS responses.
/// It provides methods for parsing the response from the server.
/// {@endtemplate}
abstract class ResponseParser<T> {
  /// parse the response from the server
  AwsResponse? parseResponse(
    T response, {
    AwsUrlType type = AwsUrlType.GET,
  });
}

/// {@template aws_rest_response_parser}
/// A parser for AWS REST responses.
/// It provides methods for parsing the response from the server.
/// {@endtemplate}
class DefaultRestResponseParser implements ResponseParser<Response> {
  /// {@macro aws_response_parser}
  const DefaultRestResponseParser({
    this.responseKey = 'url',
  });

  /// responseKey is the key in the response that contains the URL
  final String responseKey;

  @override
  AwsResponse? parseResponse(
    Response response, {
    AwsUrlType type = AwsUrlType.GET,
  }) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final response = data[responseKey];
      if (response is String) {
        return switch (type) {
          AwsUrlType.PUT => AwsResponse(
              key: parseBucketKey(response),
              uploadUrl: response,
            ),
          _ => AwsResponse(
              key: parseBucketKey(response),
              previewUrl: response,
            ),
        };
      }
      return AwsResponse.fromMap(data);
    } else if (data is String) {
      try {
        final json = data.isNotEmpty ? jsonDecode(data) : null;
        if (json is Map<String, dynamic>) {
          final url = json[responseKey];
          if (url is String) {
            return switch (type) {
              AwsUrlType.PUT => AwsResponse(
                  key: parseBucketKey(url),
                  uploadUrl: url,
                ),
              _ => AwsResponse(
                  key: parseBucketKey(url),
                  previewUrl: url,
                ),
            };
          }
          return AwsResponse.fromMap(json);
        }
      } catch (error, stackTrace) {
        // Handle JSON parsing error
        Logger.e(
          'Failed to parse JSON: ',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return null;
  }
}

/// {@template aws_graphql_response_parser}
/// A parser for AWS GraphQL responses.
/// It provides methods for parsing the response from the server.
/// {@endtemplate}
class DefaultGqlResponseParser implements ResponseParser<Map<String, dynamic>> {
  const DefaultGqlResponseParser({
    required this.query,
    this.responseKey = 'url',
  });

  final String query;
  final String responseKey;

  @override
  AwsResponse? parseResponse(
    Map<String, dynamic> response, {
    AwsUrlType type = AwsUrlType.GET,
  }) {
    final queryName = parseQueryName(query);
    if (response['data'] != null && response['data'][queryName] != null) {
      final data = response['data'][queryName];
      if (data is Map<String, dynamic>) {
        if (data[responseKey] is String) {
          return switch (type) {
            AwsUrlType.PUT => AwsResponse(
                key: parseBucketKey(data[responseKey].toString()),
                uploadUrl: data[responseKey].toString(),
              ),
            _ => AwsResponse(
                key: parseBucketKey(data[responseKey].toString()),
                previewUrl: data[responseKey].toString(),
              ),
          };
        }
        return AwsResponse.fromMap(data);
      }
    }
    return null;
  }
}
