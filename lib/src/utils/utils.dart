import 'dart:convert';

import 'package:aws_image/src/utils/_extensions.dart';
import 'package:crypto/crypto.dart';

/// Default cache duration for images.
const defaultCacheDuration = Duration(days: 3);

/// Default maximum number of retries for requests.
const defaultMaxRetries = 3;

/// Default delay between retries.
const defaultRetryDelay = Duration(seconds: 1);

/// Default scale for images.
const defaultScale = 1.0;

/// hashes the given key using MD5 algorithm.
String hashKey(String key) {
  final bytes = utf8.encode(key);
  final digest = md5.convert(bytes);
  return digest.toString();
}

/// Checks if the given value is a valid Unix timestamp.
bool isUnixTimestamp(int value) {
  // Accepts seconds or milliseconds since epoch
  final min = DateTime(1970).millisecondsSinceEpoch;
  final max = DateTime(3000).millisecondsSinceEpoch;
  // If value is in seconds, convert to ms for comparison
  if (value < 1000000000000) {
    value *= 1000;
  }
  return value >= min && value <= max;
}

/// Parses the query name from query string.
String? parseQueryName(String query) {
  // Remove comments and compress whitespace
  final cleaned =
      query.replaceAll(RegExp(r'#.*'), '').replaceAll(RegExp(r'\s+'), ' ');
  // Match: mutation Name(...) { fieldName(
  final match = RegExp(r'(mutation|query)\s+\w*\s*\([^\)]*\)\s*\{\s*(\w+)')
      .firstMatch(cleaned);
  if (match != null && match.groupCount >= 2) {
    return match.group(2);
  }
  // Fallback: find first field after first '{'
  final fallback = RegExp(r'\{\s*(\w+)').firstMatch(cleaned);
  if (fallback != null && fallback.groupCount >= 1) {
    return fallback.group(1);
  }
  return null;
}

/// Parses the operation name from a GraphQL query string.
String? parseOperationName(String query) {
  // Remove comments and compress whitespace
  final cleaned =
      query.replaceAll(RegExp(r'#.*'), '').replaceAll(RegExp(r'\s+'), ' ');
  // Match: mutation Name(
  final match = RegExp(r'(mutation|query)\s+(\w+)').firstMatch(cleaned);
  if (match != null && match.groupCount >= 2) {
    return match.group(2);
  }
  return null;
}

/// Parses the bucket key from a URL.
String parseBucketKey(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  if (uri.pathSegments.isEmpty) {
    throw ArgumentError(
      'Invalid URL: $url. Unable to parse bucket key.',
    );
  }
  return uri.pathSegments.join('/');
}

/// Checks if the given string is a valid GraphQL query or mutation.
/// Returns true if it starts with 'query' or 'mutation' (optionally with an operation name and variables) and an opening '{'.
bool isValidQuery(String query) {
  // Remove comments and compress whitespace
  final cleaned = query
      .replaceAll(RegExp(r'#.*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  // Match: query|mutation [Name] [(...)] {
  final regex = RegExp(r'^(query|mutation)(\s+\w+)?(\s*\([^\)]*\))?\s*\{');
  return regex.hasMatch(cleaned);
}

/// Parses the cache key from a presigned URL.
String parseCacheKey(String url) {
  if (url.isNotNullOrEmpty && Uri.tryParse(url) != null) {
    return hashKey(parseBucketKey(url));
  }
  return hashKey(url);
}

/// check if the url is expired
bool isUrlExpired(String url) {
  final uri = Uri.tryParse(url);
  final expires =
      uri?.queryParameters['X-Amz-Expires'] ?? uri?.queryParameters['Expires'];
  if (expires == null) {
    return false;
  }
  final expiresInt = int.tryParse(expires);
  if (expiresInt == null) {
    return false;
  }
  final now = DateTime.now().toLocal();

  if (isUnixTimestamp(expiresInt)) {
    final expiresDate = DateTime.fromMillisecondsSinceEpoch(expiresInt * 1000);
    return now.isAfter(expiresDate);
  } else {
    final expiresDate = DateTime.tryParse(expires);
    if (expiresDate == null) {
      return false;
    }
    return now.isAfter(expiresDate);
  }
}

bool isValidUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
}
