// dart
import 'dart:io';
// packages
import 'package:path/path.dart' as pathlib;

// local
import 'package:flutter_file_manager/src/utils.dart';

// Base file filter for creating other filters
abstract class FileFilter {
  /// Checking if file is valid or not
  /// if it was valid then return [true] else [false]
  bool isValid(String path, String root);
}

class SimpleFileFilter extends FileFilter {
  /// Allowed allowedExtensions
  ///
  /// There must not be . before extension name
  List<String> allowedExtensions;

  /// If [true] (default) then get hidden,
  /// else [false] do not get hidden
  bool includeHidden;

  /// Only return [File]s
  bool fileOnly;

  /// Only return [Directory]s
  bool directoryOnly;
  SimpleFileFilter(
      {this.allowedExtensions,
      this.includeHidden: true,
      this.fileOnly: false,
      this.directoryOnly: false})
      : assert(validExtensions(allowedExtensions) == true),
        assert(fileOnly && directoryOnly != true);

  bool checkExtension(String path) {
    if (allowedExtensions
        .contains(pathlib.extension(path).replaceFirst('.', ''))) return true;
    return false;
  }

  @override
  bool isValid(String path, String root) {
    if (directoryOnly) {
      // is directory or link
      if (FileSystemEntity.isDirectorySync(path)) {
        if (!includeHidden) {
          if (isHidden(path, root)) {
            return false;
          }
          return true;
        }
        return true;
        // is file
      } else
        return false;
    } else if (fileOnly) {
      // is directory or link
      if (FileSystemEntity.isDirectorySync(path)) {
        return false;
        // is file
      } else if (FileSystemEntity.isFileSync(path)) {
        if (checkExtension(path)) {
          if (!includeHidden) {
            if (isHidden(path, root)) {
              return false;
            }
          }

          return true;
        }
        return false;
      } else if (FileSystemEntity.isLinkSync(path)) {
        return true;
      } else {
        return false;
      }
    } else {
      // is directory or link
      if (path is Directory) {
        if (!includeHidden) {
          if (isHidden(path, root)) {
            return false;
          }
          return true;
        }
        return true;
        // is file
      } else if (path is File) {
        if (checkExtension(path)) {
          if (!includeHidden) {
            if (isHidden(path, root)) {
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
}

class NotValidExtensionError extends Error {
  final String message;
  NotValidExtensionError(this.message);

  @override
  String toString() {
    return "Not valid extension: $message";
  }
}
