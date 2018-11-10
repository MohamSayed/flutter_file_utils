# flutter_file_manager

[![pub package](https://img.shields.io/pub/v/flutter_file_manager.svg)](https://pub.dartlang.org/packages/flutter_file_manager)

A set of utilities, that help to manage the files & directories in Android system.

You are in your way to create File Manager app or a Gallery App.


## Getting Started

For help getting started with Flutter, view our online [documentation](https://flutter.io/).

For help on editing package code, view the [documentation](https://flutter.io/developing-packages/).

## Screenshots
<p>
<img src="screenshots/ss1.png" height="300em" /> <img src="screenshots/ss2.jpg" height="300em"/>
<img src="screenshots/ss3.jpg" height="300em" /> <img src="screenshots/ss4.jpg" height="300em"/>
<img src="screenshots/ss5.jpg" height="300em" /> <img src="screenshots/ss6.jpg" height="300em" /> <img src="screenshots/ss7.jpg" height="300em" />
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
  flutter_file_manager: ^0.0.4
```
And, add read / write permissions in your
`android/app/src/main/AndroidManifest.xml`
````xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
````

Don't forget to grant `Storage` permissions to your app, manually or by this plugin [simple_permissions](https://pub.dartlang.org/packages/simple_permissions)

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_manager/flutter_file_manager.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder(
            future: buildImages(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 0.0,
                    mainAxisSpacing: 0.0,
                  ),
                  primary: false,
                  itemCount: snapshot.data.length,

                  itemBuilder: (context, index) {
                    return Image.file(File(snapshot.data[index]));
                  },
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Text("Loading");
              }
            }),
      ),
    );
  }

  Future buildImages() async {
    var root = await getExternalStorageDirectory();

    // get all files that match these extensions
    List<String> files =
        await FileManager.filesTree(root.path, extensions: ["png", "jpg"]);
  
    return files;
  }
}
```
### Example
* [examples](https://github.com/Eagle6789/flutter_file_manager/tree/master/example)

### Features
* file details
* search files or directories: supports regular expressions
* recent created files: you can exclude a list of directories from the tree 
* directories only tree: you can exclude a list of directories from the tree
* files only tree: you can exclude a list of directories from the tree
* files list from specific point
* delete files
* delete directory

### Contributors
* [Mohamed Naga](https://github.com/eagle6789)

## Feel free to donate
* [PayPal](https://www.paypal.me/eagle6789)

### Contact me
me.developer.a@gmail.com