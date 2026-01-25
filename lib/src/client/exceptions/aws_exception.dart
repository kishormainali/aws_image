/// {@template aws_exception}
/// An exception thrown by AWS S3 operations.
/// {@endtemplate}
class AwsException implements Exception {
  /// {@macro aws_exception}
  const AwsException(this.message, {this.stackTrace, this.originalError});

  /// The exception message.
  final String message;

  /// The original error object.
  final Object? originalError;

  /// The stack trace.
  final StackTrace? stackTrace;
}
