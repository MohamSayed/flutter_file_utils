# flutter_file_manager example

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_manager/flutter_file_manager.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> imagesPaths = [];

  @override
  Widget build(BuildContext context) {
    buildImages();
    return MaterialApp(
      home: Scaffold(
        body: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 0.0,
            mainAxisSpacing: 0.0,
          ),
          primary: false,
          itemBuilder: (context, index) {
            return Image.file(File(imagesPaths[index]));
          },
        ),
      ),
    );
  }

 Future buildImages() async {
  var dir = await getExternalStorageDirectory();
    imagesPaths = await FileManager.filesTreeList(dir.path,
        extensions: ["png", "jpg"]);
  }
}
```