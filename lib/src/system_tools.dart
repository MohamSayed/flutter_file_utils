// dart sdk
import 'dart:io';
import 'dart:async';

// packages
import 'package:path/path.dart' as pathlib;

void copy(String target, String destination) {
  Directory targetDir = Directory(target);
  try {
    print("Trying Copying directory: $target");
    if (targetDir.existsSync()) {
      print("Target path exists, copying directory...");
      String targetBasename = pathlib.basename(target);

      // Create target
      Directory newPath = Directory(pathlib.join(destination, targetBasename))
        ..create();
      for (var fileOrDir in targetDir.listSync()) {
        // if it was file
        if (fileOrDir is File) {
          print("Copying file: ${fileOrDir.path} to ${newPath.path}\n");
          fileOrDir.copy(
              pathlib.join(newPath.path, pathlib.basename(fileOrDir.path)));
        } else if (fileOrDir is Directory) {
          print("Copying directory: ${fileOrDir.path} to ${newPath.path}\n");
          // recursion
          copy(fileOrDir.path, newPath.path);
        }
        // if ? is link then ...
        else {
          fileOrDir.rename(
              pathlib.join(newPath.path, pathlib.basename(fileOrDir.path)));
        }
      }
    } else {
      throw FileSystemException("Target does not exist", target);
    }
  } catch (e) {
    rethrow;
  }
}

Future<Directory> rename(String target, String destination) async {
  Directory targetDir = Directory(target);
  String basename = pathlib.basename(targetDir.path);
  return await targetDir.rename(pathlib.join(destination, basename));
}
