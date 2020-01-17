/*
 This code is used to extend dart:io llibrary, 
 to add extra functionality to avoid repeating code
*/

// dart
import 'dart:io';

// packages
import 'package:path/path.dart' as pathlib;

/// Extension on [File]
extension ExtendedFile on File {
  /// Get the extension of a file
  String extension() {
    return pathlib.extension(path);
  }

  String basename() {
    return pathlib.basename(path);
  }
}

/// Extension on [Directory]
extension ExtendedDirectory on Directory {
  String basename() {
    return pathlib.basename(this.path);
  }
}

/// Extension on [FileSystemEntity]
extension ExtendedFileSystemEntity on FileSystemEntity {
  String basename() {
    return pathlib.basename(path);
  }
}
