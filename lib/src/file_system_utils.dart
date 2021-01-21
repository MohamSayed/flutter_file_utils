// dart
import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';

import 'exceptions.dart';
import 'file_manager.dart';
import 'io_extensions.dart';
import 'sorting.dart';
import 'time_tools.dart';

// returns [File] or [Directory]
/// * argument objects = [File] or [Directory]
/// * argument by [String]: 'date', 'alpha', 'size'
List<FileSystemEntity> sortBy(
    List<FileSystemEntity> objects, FlutterFileUtilsSorting by,
    {bool reversed = false}) {
  switch (by) {
    case FlutterFileUtilsSorting.Alpha:
      objects
          .sort((a, b) => getBaseName(a.path).compareTo(getBaseName(b.path)));
      break;

    case FlutterFileUtilsSorting.Date:
      objects.sort((a, b) {
        return a
            .statSync()
            .modified
            .millisecondsSinceEpoch
            .compareTo(b.statSync().modified.millisecondsSinceEpoch);
      });
      break;

    case FlutterFileUtilsSorting.Size:
      objects.sort((a, b) {
        return a.statSync().size.compareTo(b.statSync().size);
      });
      break;

    case FlutterFileUtilsSorting.Type:
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
String getBaseName(String path, {bool extension = true}) {
  if (extension) {
    return pathlib.split(path).last;
  } else {
    return pathlib.split(path).last.split(RegExp(r'\.\w+'))[0];
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
Future<Map<String, dynamic>> details(FileSystemEntity path) async {
  var _details = <String, dynamic>{};
  if (path == null || !path.existsSync()) {
    print('file or dir does not exists');
    return null;
    // directory
  } else if (path.existsSync()) {
    // directory or file
    _details['type'] = path.statSync().type.toString();
    _details['lastChanged'] = TimeTools.timeNormalize(path.statSync().changed);
    _details['lastModified'] = TimeTools.timeNormalize(
        Directory.fromUri(Uri.parse(path.path)).statSync().modified);
    _details['size'] = path.statSync().size;
    _details['type'] = path.statSync().type.toString();
    _details['lastAccessed'] =
        TimeTools.timeNormalize(path.statSync().accessed);
    _details['permissions'] = path.statSync().modeString();
    _details['path'] = path;

    return _details;
    // file
  } else if (path.existsSync()) {
    var fileStat = File(path.path).statSync();
    // directory or file
    _details['lastModified'] = TimeTools.timeNormalize(fileStat.modified);
    _details['lastAccessed'] = TimeTools.timeNormalize(fileStat.accessed);
    _details['lastChanged'] = TimeTools.timeNormalize(fileStat.changed);
    _details['type'] = fileStat.type.toString();
    _details['size'] = fileStat.size;
    _details['permissions'] = fileStat.modeString();
    _details['extension'] = pathlib.extension(path.path).replaceFirst('.', '');
    _details['path'] = path;

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

/// keepHidden: show files that start with .
Stream<List<FileSystemEntity>> fileStream(String path,
    {bool changeCurrentPath = true,
    bool reverse = false,
    bool recursive = false,
    bool keepHidden = false}) async* {
  var _path = Directory(path);
  var _files = <FileSystemEntity>[];
  try {
    // Checking if the target directory contains files inside or not!
    // so that [StreamBuilder] won't emit the same old data if there are
    // no elements inside that directory.
    if (_path.listSync(recursive: recursive).isNotEmpty) {
      if (!keepHidden) {
        yield* _path.list(recursive: recursive).transform(
            StreamTransformer.fromHandlers(
                handleData: (FileSystemEntity data, sink) {
          print('filsytem_utils -> fileStream: $data');
          _files.add(data);
          sink.add(_files);
        }));
      } else {
        yield* _path.list(recursive: recursive).transform(
            StreamTransformer.fromHandlers(
                handleData: (FileSystemEntity data, sink) {
          print('filsytem_utils -> fileStream: $data');
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
Stream<List<FileSystemEntity>> searchStream(String path, String query,
    {bool matchCase = false,
    bool recursive = true,
    bool hidden = false}) async* {
  yield* fileStream(path, recursive: recursive)
      .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
    // Filtering
    data.retainWhere(
        (test) => test.basename().toLowerCase().contains(query.toLowerCase()));
    sink.add(data);
  }));
}

// Future<int> getFreeSpace(String path) async {
//   MethodChannel platform = const MethodChannel('samples.flutter.dev/battery');
//   int freeSpace = await platform.invokeMethod('getFreeStorageSpace');
//   return freeSpace;
// }

/// Create folder by path
/// * i.e: `.createFolderByPath('/storage/emulated/0/', 'folder name' )`
///
/// Supply path alone to create by already combined path, or path + filename
/// to be combined
Future<Directory> createFolderByPath(String path, {String folderName}) async {
  print('filesystem_utils->createFolderByPath: $folderName @ $path');
  Directory _directory;

  if (folderName != null) {
    _directory = Directory(pathlib.join(path, folderName));
  } else {
    _directory = Directory(path);
  }

  try {
    if (!_directory.existsSync()) {
      await _directory.create();
    } else {
      FileSystemException('File already exists');
    }
    return _directory;
  } catch (e) {
    throw FileSystemException(e.toString());
  }
}

/// This function returns every [Directory] in the path
/// independently
///
/// e.g:
///
/// path: /lib/user/share/var/foo
/// * `Directory: /`
/// * `Directory: /lib/`
/// * `Directory: /lib/user`
/// * `Directory: /lib/user/share`
/// * `....`
List<Directory> splitPathToDirectories(String fullPath) {
  var splittedPath = <Directory>[];
  var fullPathDir = Directory(fullPath);
  splittedPath.add(fullPathDir);
  for (var i = 0; i == pathlib.split(fullPath).length; i++) {
    splittedPath.add(fullPathDir.parent);
    fullPathDir = fullPathDir.parent;
  }
  return splittedPath.reversed.toList();
}

void copy(String targetPath, String destination) {
  var targetDir = Directory(targetPath);
  try {
    print('Trying Copying directory: $targetPath');
    if (targetDir.existsSync()) {
      print('Target path exists, copying directory...');
      var targetBasename = pathlib.basename(targetPath);

      // Create target
      var newPath = Directory(pathlib.join(destination, targetBasename))
        ..create();
      for (var fileOrDir in targetDir.listSync()) {
        // if it was file
        if (fileOrDir is File) {
          print('Copying file: ${fileOrDir.path} to ${newPath.path}\n');
          fileOrDir.copy(
              pathlib.join(newPath.path, pathlib.basename(fileOrDir.path)));
        } else if (fileOrDir is Directory) {
          print('Copying directory: ${fileOrDir.path} to ${newPath.path}\n');
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
      throw FileSystemException('Target does not exist', targetPath);
    }
  } catch (e) {
    rethrow;
  }
}

Future<Directory> rename(String target, String destination) async {
  var targetDir = Directory(target);
  var basename = pathlib.basename(targetDir.path);
  return await targetDir.rename(pathlib.join(destination, basename));
}

/// This function creates temporary file on the device storage
/// Return [File]
/// You can call normal [File] methods
Future<File> cacheFile(String name) async {
  var tempDir = await getTemporaryDirectory();
  return File(pathlib.join(tempDir.path, name));
}

/// This function returns files' paths list only from  specific location.
/// * You may specify the types of the files you want to get by supplying the optional
/// [extensions].
/// * sortedBy: [FlutterFileUtilsSorting]
/// * [bool] reversed: in case parameter sortedBy is used
Future<List<FileSystemEntity>> listFiles(String path,
    {List<String> extensions,
    bool followsLinks = false,
    bool excludeHidden = false,
    FlutterFileUtilsSorting sortedBy,
    bool reversed = false}) async {
  var files = <File>[];

  try {
    List contents =
        Directory(path).listSync(followLinks: followsLinks, recursive: false);
    if (extensions != null) {
      // Future<List<String>> extensionsPatterns =
      //     RegexTools.makeExtensionPatterns(extensions);
      for (var fileOrDir in contents) {
        if (fileOrDir is File) {
          var file = pathlib.normalize(fileOrDir.path);
          for (var extension in extensions) {
            if (pathlib.extension(file).replaceFirst('.', '') ==
                extension.replaceFirst('.', '')) {
              if (excludeHidden) {
                if (file.startsWith('.')) {
                  files.add(File(pathlib.normalize(fileOrDir.absolute.path)));
                }
              } else {
                files.add(File(pathlib.normalize(fileOrDir.absolute.path)));
              }
            }
          }
        }
      }
    } else {
      for (var fileOrDir in contents) {
        if (fileOrDir is File) {
          files.add(File(pathlib.normalize(fileOrDir.absolute.path)));
        }
      }
    }
  } catch (error) {
    throw FileManagerError(error.toString());
  }
  if (files != null) {
    return sortBy(files, sortedBy, reversed: reversed);
  }

  return files;
}

/// This function return list of folders of type [String] , not full paths [Directory].
///
/// e.g: listFolders(Directory('/')) = root, usr, var, proc, mnt ...
/// * [hidden]: this parameter excludes folders starts with ' . '
/// * [excludedFolders]: this parameter excludes folders from the result
/// * sortedBy: [Sorting]
/// * [bool] reversed: in case parameter sortedBy is used
/// * examples: ['Android', 'Download', 'DCIM', ....]
Future<List<String>> listFolders(Directory path,
    {List<String> excludedFolders,
    List<String> excludedPaths,
    bool excludeHidden = false,
    bool followLinks = false,
    FlutterFileUtilsSorting sortedBy,
    bool reversed = false}) async {
  var folders = (await listDirectories(path,
          excludeHidden: excludeHidden,
          followLinks: false,
          reversed: reversed,
          sortedBy: sortedBy))
      .map((FileSystemEntity directory) =>
          pathlib.split(directory.absolute.path).last)
      .toList();
  return folders;
}

/// Return a [List] of directories starting from the given path
/// * [hidden] : [true] or [false] return hidden directory, like: '/storage/.thumbnails'
/// * [true] will return hidden directories
/// * sortedBy: [Sorting]
/// * [bool] reversed: in case parameter sortedBy is used
Future<List<FileSystemEntity>> listDirectories(Directory path,
    {bool excludeHidden = false,
    bool followLinks = false,
    FlutterFileUtilsSorting sortedBy,
    bool reversed = false}) async {
  var directories = <Directory>[];
  try {
    List contents = path.listSync(followLinks: followLinks, recursive: false);
    if (excludeHidden == true) {
      for (var fileOrDir in contents) {
        if (fileOrDir is Directory) {
          if (!fileOrDir.path.startsWith('.')) {
            directories
                .add(Directory(pathlib.normalize(fileOrDir.absolute.path)));
          }
        }
      }
    } else {
      for (var fileOrDir in contents) {
        if (fileOrDir is Directory) {
          // dir/../dir3 to dir/dir2/dir3
          directories
              .add(Directory(pathlib.normalize(fileOrDir.absolute.path)));
        }
      }
    }
  } catch (error) {
    throw FileManagerError(permissionMessage + error.toString());
  }
  if (directories != null) {
    return sortBy(directories, sortedBy);
  }

  return directories;
}

/// e.g:
Future<void> deleteAll(List<FileSystemEntity> files) async {
  try {
    for (var file in files) {
      await file.delete();
    }
  } on FileSystemException catch (e) {
    throw FileManagerError(e.toString());
  } catch (e) {
    rethrow;
  }
}

/// Delete a directory recursively or not
///
/// e.g:
/// * deleteFile(/storage/emulated/0/myFile.txt')
bool deleteDir(String path, {bool recursive = false}) {
  //print('~ deleting:' + path);
  if (File(path).existsSync()) {
    throw Exception('This is a file path not a directory path');
  }
  var file = File(path);
  try {
    file.delete(recursive: recursive);
    return true;
  } catch (error) {
    throw FileManagerError(error.toString());
  }
}
