# flutter_file_manager

[![pub package](https://img.shields.io/pub/v/flutter_file_manager.svg)](https://pub.dartlang.org/packages/flutter_file_manager)

A set of utilities, that help to manage the files & directories in Android system.

You are in your way to create to file manager app or a gallery app.


## Getting Started

For help getting started with Flutter, view our online [documentation](https://flutter.io/).

For help on editing package code, view the [documentation](https://flutter.io/developing-packages/).

## Screenshots
<p>
<img height="300em" /> <img src="https://github.com/Eagle6789/flutter_file_manager/blob/master/screenshots/ss1.png?raw=true" height="300em" />
<img height="300em" /> <img src="https://github.com/Eagle6789/flutter_file_manager/blob/master/screenshots/ss2.png?raw=true" height="300em" />
<img height="300em" /> <img src="https://github.com/Eagle6789/flutter_file_manager/blob/master/screenshots/ss3.jpg?raw=true" height="300em" />

</p>



## Usage

To use this package, add these  
dependency in your `pubspec.yaml`  file.

```yaml
dependencies:
  flutter:
    sdk: flutter
  path: ^1.6.2
  path_provider: ^0.4.1
  flutter_file_manager: ^0.0.3
```
And, add read / write permissions in your
`android/app/src/main/AndroidManifest.xml`
````xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
````
Don't forget to give `Storage` permissions to your app, manually or by this plugin [simple_permissions](https://pub.dartlang.org/packages/simple_permissions)

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
### Example
* [example](https://github.com/Eagle6789/flutter_file_manager/tree/master/example)

### Features
* file details
* search files or directory: supports regular expressions
* recent created files: you exclude a list of directories from the tree 
* directories only tree: you exclude a list of directories from the tree
* files only tree: you exclude a list of directories from the tree
* files list

### Contributors
* [Mohamed Naga](https://github.com/eagle6789)

## Donate
* [PayPal](https://www.paypal.me/eagle6789)

### Contact me
me.developer.a@gmail.com