import 'package:aws_image/aws_image.dart';
import 'package:flutter/material.dart';

void main() {
  final client = AwsImageClient(
    AwsImageGraphqlRequest(
      baseUrl: 'baseURl', // Replace with your base URL
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('AWS Image Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Hello World!'),
              const SizedBox(height: 20),
              AwsImage(
                width: 100,
                height: 100,
                cacheHeight: 100,
                cacheWidth: 100,
                compressionRatio: 0.8,
                cacheDuration: Duration(seconds: 1),
                fit: BoxFit.cover,
                imageClient: client,
                presignedUrl:
                    'presigned url', // Replace with your presigned URL
                //or
                bucketKey: 'bucketKey', // Replace with your bucket key
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(100),
                clipBehavior: Clip.antiAlias,
                shape: BoxShape.circle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
