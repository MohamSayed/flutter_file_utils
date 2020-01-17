// dart
import 'dart:io';
import 'dart:async';
import 'dart:collection';

// packages
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';
import 'package:package_info/package_info.dart';


// local
import 'package:flutter_file_manager/flutter_file_manager.dart';
import 'package:flutter_file_manager/src/sorting.dart';
import 'package:flutter_file_manager/src/time_tools.dart';
import 'package:flutter_file_manager/src/io_extensions.dart';

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
        return pathlib.extension(a.path).compareTo(pathlib.extension(b.path));
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
    return pathlib.split(path).last;
  } else {
    return pathlib.split(path).last.split(new RegExp(r'\.\w+'))[0];
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
    _details["extension"] = pathlib.extension(path.path).replaceFirst('.', '');
    _details["path"] = path;

    return _details;
  }
  return null;
}

bool isHidden(String path, String root) {
  // trying to infer relative path
  if (pathlib.relative(path, from: root).startsWith('.')) {
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

/// Return all **paths**
Future<List<Directory>> getStorageList() async {
  List<Directory> paths = await getExternalStorageDirectories();
  List<Directory> filteredPaths = List<Directory>();
  for (Directory dir in paths) {
    filteredPaths
        .add(await getExternalStorageWithoutDataDir(dir.absolute.path));
  }
  return filteredPaths;
}

/// This function aims to get path like: `/storage/emulated/0/`
/// not like `/storage/emulated/0/Android/data/package.name.example/files`
Future<Directory> getExternalStorageWithoutDataDir(
    String unfilteredPath) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  print("storage_helper->getExternalStorageWithoutDataDir: " +
      packageInfo.packageName);
  String subPath =
      pathlib.join("Android", "data", packageInfo.packageName, "files");
  if (unfilteredPath.contains(subPath)) {
    String filteredPath = unfilteredPath.split(subPath).first;
    print("storage_helper->getExternalStorageWithoutDataDir: " + filteredPath);
    return Directory(filteredPath);
  } else {
    return Directory(unfilteredPath);
  }
}



/// keepHidden: show files that start with .
Stream<List<FileSystemEntity>> fileStream(String path,
    {changeCurrentPath: true,
    reverse: false,
    recursive: false,
    keepHidden: false}) async* {
  Directory _path = Directory(path);
  List<FileSystemEntity> _files = List<FileSystemEntity>();
  try {
    // Checking if the target directory contains files inside or not!
    // so that [StreamBuilder] won't emit the same old data if there are
    // no elements inside that directory.
    if (_path.listSync(recursive: recursive).length != 0) {
      if (!keepHidden) {
        yield* _path.list(recursive: recursive).transform(
            StreamTransformer.fromHandlers(
                handleData: (FileSystemEntity data, sink) {
          debugPrint("filsytem_utils -> fileStream: $data");
          _files.add(data);
          sink.add(_files);
        }));
      } else {
        yield* _path.list(recursive: recursive).transform(
            StreamTransformer.fromHandlers(
                handleData: (FileSystemEntity data, sink) {
          debugPrint("filsytem_utils -> fileStream: $data");
          if (data.basename().startsWith('.')) {
            _files.add(data);
            sink.add(_files);
          }
        }));
      }
    } else {
      yield [];
    }
  } on FileSystemException catch (e) {
    print(e);
    yield [];
  }
}


/// search for files and folder in current directory & sub-directories,
/// and return [File] or [Directory]
///
/// `path`: start point
/// `query`: regex or simple string
Stream<List<FileSystemEntity>> searchStream(dynamic path, String query,
    {bool matchCase: false, recursive: true, bool hidden: false}) async* {
  yield* fileStream(path, recursive: recursive)
      .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
    // Filtering
    data.retainWhere(
        (test) => test.basename().toLowerCase().contains(query.toLowerCase()));
    sink.add(data);
  }));
}

Future<int> getFreeSpace(String path) async {
  MethodChannel platform = const MethodChannel('samples.flutter.dev/battery');
  int freeSpace = await platform.invokeMethod("getFreeStorageSpace");
  return freeSpace;
}

/// Create folder by path
/// * i.e: `.createFolderByPath("/storage/emulated/0/", "folder name" )`
///
/// Supply path alone to create by already combined path, or path + filename
/// to be combined
Future<Directory> createFolderByPath(String path, {String folderName}) async {
  print("filesystem_utils->createFolderByPath: $folderName @ $path");
  var _directory;

  if (folderName != null) {
    _directory = Directory(pathlib.join(path, folderName));
  } else {
    _directory = Directory(path);
  }

  try {
    if (!_directory.existsSync()) {
      _directory.create();
    } else {
      FileSystemException("File already exists");
    }
    return _directory;
  } catch (e) {
    throw FileSystemException(e);
  }
}

/// This function returns every [Directory] in th path
List<Directory> splitPathToDirectories(String path) {
  List<Directory> splittedPath = List();
  Directory pathDir = Directory(path);
  splittedPath.add(pathDir);
  for (var item in pathlib.split(path)) {
    splittedPath.add(pathDir.parent);
    pathDir = pathDir.parent;
  }
  return splittedPath.reversed.toList();
}
