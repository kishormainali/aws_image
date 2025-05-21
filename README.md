# aws_image

A Flutter package for loading, caching, and displaying images from AWS S3 using presigned URLs. It provides widgets and utilities to simplify working with AWS S3 images, including automatic URL refresh, caching, and custom image providers.

## Features

- Load images from AWS S3 using presigned URLs
- Automatic refresh of expired presigned URLs
- Customizable headers and query parameters
- Caching and retry logic
- Support for resizing, scaling, and custom builders
- Easy integration with Flutter widgets

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  aws_image: ^1.0.0
```

Then run:

```sh
flutter pub get
```

## Usage

Import the package:

```dart
import 'package:aws_image/aws_image.dart';
```

## Example

Below is a complete example using `AwsImage` and `AwsImageClient`:

```dart
import 'package:aws_image/aws_image.dart';
import 'package:flutter/material.dart';

void main() {
  final client = AwsImageClient(
    AwsImageGraphqlRequest(
      baseUrl: baseUrlForGraphql,
      query: '''
        mutation GetPreSignedUrlForMobileDevice(\$input: PreSignedUrlInputDto!) {
          getPreSignedUrlForMobileDevice(input: \$input) {
            url
          }
        }
      ''',
      enableLogging: true,
    ),
  );
  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.client});
  final AwsImageClient client;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AWS Image Example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: Scaffold(
        appBar: AppBar(title: const Text('AWS Image Example')),
        body: Center(
          child: AwsImage(
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            imageClient: client,
            presignedUrl: 'aws-presigned-url',
            border: Border.all(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(100),
            clipBehavior: Clip.antiAlias,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
```

## API Reference

- **AwsImage**: Widget for displaying images from AWS S3. Handles caching, loading, and refreshing expired URLs.
- **AwsImageClient**: Client for making requests to AWS S3. Handles getting images, uploading files, and presigned URLs.
- **AwsImageProvider**: Custom ImageProvider for AWS S3, used internally by AwsImage.
- **AwsImageInfo**: Holds information about the image, including presigned URL, headers, and query parameters.
- **AwsImageGraphqlRequest**: Request for an image from AWS using GraphQL.

## Contributing

Contributions are welcome! Please open issues or pull requests on [GitHub](https://github.com/kishormainali/aws_image).

## License

[MIT](LICENSE)
