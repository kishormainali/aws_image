import 'dart:convert';

import 'package:aws_image/src/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:fp_logger/fp_logger.dart';

/// {@template aws_response_parser}
/// A parser for AWS responses.
/// It provides methods for parsing the response from the server.
/// {@endtemplate}
abstract class PresignedUrlResponseParser<T> {
  /// parse the response from the server
  String? parseResponse(T response);
}

/// {@template aws_rest_response_parser}
/// A parser for AWS REST responses.
/// It provides methods for parsing the response from the server.
/// {@endtemplate}
class DefaultRestResponseParser
    implements PresignedUrlResponseParser<Response> {
  /// {@macro aws_response_parser}
  const DefaultRestResponseParser({
    this.responseKey = 'url',
  });

  /// responseKey is the key in the response that contains the URL
  final String responseKey;

  @override
  String? parseResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final url = data[responseKey];
      if (url is String) {
        return url;
      }
    } else if (data is String) {
      try {
        final json = data.isNotEmpty ? jsonDecode(data) : null;
        if (json is Map<String, dynamic>) {
          final url = json[responseKey];
          if (url is String) {
            return url;
          }
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
class DefaultGqlResponseParser
    implements PresignedUrlResponseParser<Map<String, dynamic>> {
  const DefaultGqlResponseParser({
    required this.query,
    this.responseKey = 'url',
  });

  final String query;
  final String responseKey;

  @override
  String? parseResponse(Map<String, dynamic> response) {
    final queryName = parseQueryName(query);

    if (response['data'] != null && response['data'][queryName] != null) {
      final data = response['data'][queryName];
      if (data is Map<String, dynamic> && data[responseKey] != null) {
        return data[responseKey].toString();
      }
    }
    return null;
  }
}
