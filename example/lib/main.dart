import 'package:aws_image/aws_image.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final request = AwsImageGraphqlRequest(
    baseUrl: '', // Replace with your base URL
    query: '''
        mutation GetPreSignedUrlForMobileDevice(\$input: PreSignedUrlInputDto!) {
        getPreSignedUrlForMobileDevice(input: \$input) {
          url
        }
      }
      ''',
    enableLogging: true,
  );
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AwsClientProvider(
      request: request,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('AWS Image Example')),
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 20,
              children: <Widget>[
                const Text('Hello World!'),
                const SizedBox(height: 20),
                AwsImage(
                  cacheDuration: Duration(seconds: 1),
                  fit: BoxFit.cover,
                  //or
                  url:
                      'service/01e95605-151d-4965-861c-9602d57fe832/Frame 48948 (1).jpg', // Replace with your bucket key
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(100),
                  clipBehavior: Clip.antiAlias,
                  shape: BoxShape.circle,
                ),

                AwsImage(
                  cacheDuration: Duration(seconds: 1),
                  fit: BoxFit.cover,
                  //or
                  url:
                      'service/01e95605-151d-4965-861c-9602d57fe832/Frame 48948 (1).jpg', // Replace with your bucket key
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(100),
                  clipBehavior: Clip.antiAlias,
                  shape: BoxShape.circle,
                ),

                AwsImage(
                  cacheDuration: Duration(seconds: 1),
                  fit: BoxFit.cover,
                  //or
                  url:
                      'service/01e95605-151d-4965-861c-9602d57fe832/Frame 48948 (1).jpg', // Replace with your bucket key
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(100),

                  clipBehavior: Clip.antiAlias,
                  shape: BoxShape.circle,
                ),

                AwsImage(
                  cacheDuration: Duration(seconds: 1),
                  fit: BoxFit.cover,
                  //or
                  url:
                      'service/01e95605-151d-4965-861c-9602d57fe832/Frame 48948 (1).jpg', // Replace with your bucket key
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(100),
                  clipBehavior: Clip.antiAlias,
                  shape: BoxShape.circle,
                ),

                AwsImage(
                  cacheDuration: Duration(seconds: 1),
                  fit: BoxFit.cover,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(4),
                  width: 100,
                  height: 100,
                  border: Border.all(color: Colors.red, width: 2),

                  //or
                  url:
                      'service/01e95605-151d-4965-861c-9602d57fe832/Frame 48948 (1).jpg', // Replace with your bucket key
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
