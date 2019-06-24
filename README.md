# flutter_file_manager

[![pub package](https://img.shields.io/pub/v/flutter_file_manager.svg)](https://pub.dartlang.org/packages/flutter_file_manager)

A set of utilities, that help to manage the files & directories in Android system.

You are in your way to create File Manager app or a Gallery App.

## Getting Started

For help getting started with Flutter, view our online [documentation](https://flutter.io/).

For help on editing package code, view the [documentation](https://flutter.io/developing-packages/).

## Screenshots

<p>
  <img src="https://github.com/Eagle6789/flutter_file_manager/blob/master/screenshots/ss1.png?raw=true" height="300em" /> <img src="https://github.com/Eagle6789/flutter_file_manager/raw/master/screenshots/ss2.jpg" height="300em"/>
  <img src="https://github.com/Eagle6789/flutter_file_manager/raw/master/screenshots/ss3.jpg" height="300em" /> <img src="https://github.com/Eagle6789/flutter_file_manager/raw/master/screenshots/ss4.jpg" height="300em"/>
  <img src="https://github.com/Eagle6789/flutter_file_manager/raw/master/screenshots/ss5.jpg" height="300em" /> <img src="https://github.com/Eagle6789/flutter_file_manager/raw/master/screenshots/ss6.jpg" height="300em" /> <img src="https://github.com/Eagle6789/flutter_file_manager/raw/master/screenshots/ss7.jpg" height="300em" />
</p>

## Usage

To use this package, add these  
dependency in your `pubspec.yaml`  file.

```yaml
dependencies:
  flutter:
    sdk: flutter
  path: 1.6.2
  path_provider: 0.5.0+1
  flutter_file_manager: ^0.2.0
```

And, add read / write permissions in your
`android/app/src/main/AndroidManifest.xml`

````xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
````

Don't forget to grant `Storage` permissions to your app, manually or by this plugin [simple_permissions](https://pub.dartlang.org/packages/simple_permissions)

```dart
// dart files
import 'dart:async';

// framework
import 'package:flutter/material.dart';

// packages
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_manager/flutter_file_manager.dart';
import 'package:simple_permissions/simple_permissions.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    SimplePermissions.requestPermission(Permission.ReadExternalStorage);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Flutter File Manager Example"),
        ),
        body: FutureBuilder(
            future: buildImages(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return ListView.builder(
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(snapshot.data[index].path.split('/').last),
                    );
                  },
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Text("Loading"));
              }
            }),
      ),
    );
  }

  Future buildImages() async {
    var root = await getExternalStorageDirectory();
    var files = await FileManager(root: root).walk();
    return files;
  }
}

```

### Examples

* [examples](https://github.com/Eagle6789/flutter_file_manager/tree/master/example/lib)

### Features

* file details
* search files or directories: supports regular expressions
* recent created files: you can exclude a list of directories from the tree 
* directories only tree: you can exclude a list of directories from the tree
* files only tree: you can exclude a list of directories from the tree
* files list from specific point
* delete files
* delete directory
* temp file
* Sorting
  * Type
  * Size
  * date
  * Alpha

### Contributors

* [Mohamed Naga](https://github.com/eagle6789)

## Feel free to donate

* [PayPal](https://www.paypal.me/eagle6789)
* me49544@gmail.com

### Contact me

* me.dev6789@gmail.com
