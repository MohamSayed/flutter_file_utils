// dart
import 'dart:io';
// packages
import 'package:path/path.dart' as pathlib;

// local
import 'package:flutter_file_manager/src/helper_functions.dart';

abstract class FileFilter {
  /// Checking if file is validate or not
  /// if it was valid then return [true] else [false]
  bool validate(String path, String root);
}

class SimpleFileFilter extends FileFilter {
  /// Allowed allowedExtensions
  ///
  /// There must not be . before extension name
  List<String> allowedExtensions;

  /// If [true] (default) then get hidden,
  /// else [false] do not get hidden
  bool hidden;

  SimpleFileFilter({
    this.allowedExtensions,
    this.hidden: true,
  }) : assert(validExtensions(allowedExtensions) == true);

  bool checkExtension(String path) {
    if (allowedExtensions.contains(pathlib.extension(path).replaceFirst('.', '')))
      return true;
    return false;
  }

  @override
  bool validate(String path, String root) {
    // is directory or link
    if (path is Directory) {
      if (!hidden) {
        if (isHidden(path, root)) {
          print("filtering hidden dir: $path");

          return false;
        }
        return true;
      }
      return true;
      // is file
    } else if (path is File) {
      if (checkExtension(path)) {
        print("filtering extension: $path");
        if (!hidden) {
          if (isHidden(path, root)) {
            print("filtering hidden file: $path");
            return false;
          }
        }

        return true;
      }
      return false;
    } else if (path is Link) {
      return true;
    } else {
      return true;
    }
  }
}

class NotValidExtensionError extends Error {
  final String message;
  NotValidExtensionError(this.message);

  @override
  String toString() {
    return "Not valid extension: $message";
  }
}
