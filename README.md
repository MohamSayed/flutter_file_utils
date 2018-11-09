# flutter_file_manager

[![pub package](https://img.shields.io/pub/v/flutter_file_manager.svg)](https://pub.dartlang.org/packages/flutter_file_manager)

A set of utilities, that help to manage the files & directories in Android system.


## Getting Started

For help getting started with Flutter, view our online [documentation](https://flutter.io/).

For help on editing package code, view the [documentation](https://flutter.io/developing-packages/).

## Screenshots
<p>
<img height="300em" /> <img src="https://github.com/Eagle6789/flutter_file_manager/blob/master/screenshots/ss1.png?raw=true" height="300em" />
<img height="300em" /> <img src="https://github.com/Eagle6789/flutter_file_manager/blob/master/screenshots/ss2.png?raw=true" height="300em" />
<img height="300em" /> <img src="https://github.com/Eagle6789/flutter_file_manager/blob/master/screenshots/ss3.png?raw=true" height="300em" />

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
  flutter_file_manager: ^0.0.1
```
And, add read / write permissions in your
`android/app/src/main/AndroidManifest.xml`
````xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
````
Don't forget to give `Storage` permissions to your app, manually or by this plugin [simple_permissions](https://pub.dartlang.org/packages/simple_permissions)

```dart
/// this code will bring you all the file types that match the given extensions.
List<String> imagesPaths = [];
Future buildImages() async {
	var dir = await getExternalStorageDirectory();
	imagesPaths = await FileManager.filesTreeList(dir.path, extensions: ["png", "jpg"]);
}
```
### Example
* [example](https://github.com/Eagle6789/flutter_file_manager/tree/master/example)

### Contributors
* [Mohamed Naga](https://github.com/eagle6789)

## Donate
* [PayPal](https://www.paypal.me/eagle6789)

### Contact me
me.developer.a@gmail.com