// dart
import 'dart:io';
import 'dart:async';
import 'dart:collection';

// packages
import 'package:flutter_file_manager/flutter_file_manager.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_file_manager/src/time_tools.dart';

// local
import 'package:flutter_file_manager/src/sorting.dart';

// returns [File] or [Directory]
/// * argument objects = [File] or [Directory]
/// * argument by [String]: 'date', 'alpha', 'size'
List<dynamic> sortBy(List<dynamic> objects, FileManagerSorting by,
    {bool reversed: false}) {
  switch (by) {
    case FileManagerSorting.Alpha:
      objects
          .sort((a, b) => getBaseName(a.path).compareTo(getBaseName(b.path)));
      break;

    case FileManagerSorting.Date:
      objects.sort((a, b) {
        return a
            .statSync()
            .modified
            .millisecondsSinceEpoch
            .compareTo(b.statSync().modified.millisecondsSinceEpoch);
      });
      break;

    case FileManagerSorting.Size:
      objects.sort((a, b) {
        return a.statSync().size.compareTo(b.statSync().size);
      });
      break;

    case FileManagerSorting.Type:
      objects.sort((a, b) {
        return p.extension(a.path).compareTo(p.extension(b.path));
      });

      break;
    default:
      objects
          .sort((a, b) => getBaseName(a.path).compareTo(getBaseName(b.path)));
  }
  if (reversed == true) {
    return objects.reversed.toList();
  }
  return objects;
}

/// Return the name of the file or the folder
/// i.e: /root/home/myfile.zip = myfile.zip
/// [extension]: with extension [true] or not [false], [true]
/// by default
String getBaseName(String path, {bool extension: true}) {
  if (extension) {
    return p.split(path).last;
  } else {
    return p.split(path).last.split(new RegExp(r'\.\w+'))[0];
  }
}

/// Returns a [HashMap] containing detials of the file or the directory
/// in organised style. you can use details from [Directory] or
/// [File] instead this function.
/// ### arguments
/// * [path] should be of [File] or [Directory]
///
/// ### keys
/// * type
/// * lastChanged
/// * lastModified
/// * size
/// * permissions
/// * lastAccessed
/// * extension
/// * path
Future<Map> details(dynamic path) async {
  HashMap _details = HashMap();
  if (path == null || (!path.existsSync() && !File(path).existsSync())) {
    print("file or dir does not exists");
    return null;
    // directory
  } else if (path.existsSync()) {
    // directory or file
    _details["type"] = path.statSync().type.toString();
    _details["lastChanged"] = TimeTools.timeNormalize(path.statSync().changed);
    _details["lastModified"] = TimeTools.timeNormalize(
        Directory.fromUri(Uri.parse(path)).statSync().modified);
    _details["size"] = path.statSync().size;
    _details["type"] = path.statSync().type.toString();
    _details["lastAccessed"] =
        TimeTools.timeNormalize(path.statSync().accessed);
    _details["permissions"] = path.statSync().modeString();
    _details["path"] = path;

    return _details;
    // file
  } else if (File(path).existsSync()) {
    var fileStat = File(path).statSync();
    // directory or file
    _details["lastModified"] = TimeTools.timeNormalize(fileStat.modified);
    _details["lastAccessed"] = TimeTools.timeNormalize(fileStat.accessed);
    _details["lastChanged"] = TimeTools.timeNormalize(fileStat.changed);
    _details["type"] = fileStat.type.toString();
    _details["size"] = fileStat.size;
    _details["permissions"] = fileStat.modeString();
    _details["extension"] = p.extension(path.path).replaceFirst('.', '');
    _details["path"] = path;

    return _details;
  }
  return null;
}

bool isHidden(String path, String root) {
  // trying to infer relative path
  if (p.relative(path, from: root).startsWith('.')) {
    return true;
  } else {
    return false;
  }
}

bool validExtensions(List<String> extensions) {
  if (extensions != null) {
    for (var extension in extensions) {
      if (extension.startsWith('.')) {
        throw NotValidExtensionError(extension);
      }
    }
    return true;
  }
  return true;
}
