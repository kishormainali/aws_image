import 'package:flutter/material.dart';

typedef AwsImageLoadingBuilder = Widget Function(
  BuildContext context,
  int loadedBytes,
  int totalBytes,
);

typedef AwsImageErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);
