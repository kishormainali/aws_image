# aws_image

A Flutter package for loading, caching, and displaying images from AWS S3 using presigned URLs. It provides widgets and utilities to simplify working with AWS S3 images, including automatic URL refresh, caching, and custom image providers.

## Features

- Load images from AWS S3 using presigned URLs
- Automatic refresh of expired presigned URLs
- Customizable headers and query parameters
- Caching and retry logic
- Support for resizing, scaling, and custom builders
- Modern shimmer loading animation
- Customizable error and loading states
- Shape support (circle, rounded rectangle)
- Easy integration with Flutter widgets

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  aws_image: latest_version
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

Below is a complete example using `AwsImage`:

```dart
import 'package:aws_image/aws_image.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.client});
  @override
  Widget build(BuildContext context) {
    return AwsClientProvider(
      request: AwsImageGraphqlRequest(
        baseUrl: '',
        query: '''
        mutation GetPreSignedUrlForMobileDevice(\$input: PreSignedUrlInputDto!) {
          getPreSignedUrlForMobileDevice(input: \$input) {
            url
          }
        }
      ''',
        enableLogging: true,
      ),
      child: MaterialApp(
        title: 'AWS Image Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('AWS Image Example')),
          body: Center(
            child: AwsImage(
              cacheDuration: Duration(seconds: 1),
              fit: BoxFit.cover,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(4),
              width: 100,
              height: 100,
              border: Border.all(color: Colors.red, width: 2),
              url: '', // Replace with your bucket key or presigned url
            ),
          ),
        ),
      ),
    );
  }
}
```

## License

[MIT](LICENSE)
