import 'package:flutter/material.dart';

/// Typedef for AWS image loading builder
typedef AwsImageLoadingBuilder = Widget Function(
  BuildContext context,
  int loadedBytes,
  int totalBytes,
);

/// Typedef for AWS image error builder
typedef AwsImageErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);
