// dart
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

// packages
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// local files
import './time_tools.dart';

class FileManager {
  Directory root;
  String _permissionMessage = '''
      \n\n
      Try to add this lines to your AndroidManifest.xml file

      `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>`
      `<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>`

      or/and grant storage permissions to your applicaion from app settings\n
      ''';
  FileManager({this.root}) : assert(root != null);

  /// Returns a [HashMap] containing detials of the file or the directory.
  /// keys list:
  /// * type
  /// * lastChanged
  /// * lastModified
  /// * size
  /// * permissions
  /// * lastAccessed
  /// * extension
  /// you can use details from [Directory] or [File] instead
  static Future<HashMap> fileDetails(String path) async {
    HashMap detailsList = HashMap();
    if (path == null ||
        (!Directory(path).existsSync() && !File(path).existsSync())) {
      print("file or dir does not exists");
      return null;
      // directory
    } else if (Directory(path).existsSync()) {
      // directory or file
      detailsList["type"] = Directory(path).statSync().type.toString();
      detailsList["lastChanged"] =
          TimeTools.timeNormalize(Directory(path).statSync().changed);
      detailsList["lastModified"] = TimeTools.timeNormalize(
          Directory.fromUri(Uri.parse(path)).statSync().modified);
      detailsList["size"] = Directory(path).statSync().size;
      detailsList["type"] = Directory(path).statSync().type.toString();
      detailsList["lastAccessed"] =
          TimeTools.timeNormalize(Directory(path).statSync().accessed);
      detailsList["permissions"] = Directory(path).statSync().modeString();
      detailsList["path"] = path;

      return detailsList;
      // file
    } else if (File(path).existsSync()) {
      var fileStat = File(path).statSync();
      // directory or file
      detailsList["lastModified"] = TimeTools.timeNormalize(fileStat.modified);
      detailsList["lastAccessed"] = TimeTools.timeNormalize(fileStat.accessed);
      detailsList["lastChanged"] = TimeTools.timeNormalize(fileStat.changed);
      detailsList["type"] = fileStat.type.toString();
      detailsList["size"] = fileStat.size;
      detailsList["permissions"] = fileStat.modeString();
      detailsList["extension"] = p.extension(path).replaceFirst('.', '');
      detailsList["path"] = path;

      return detailsList;
    }
    return null;
  }

  /// This function creates temporary file on the device.
  /// Return [File]
  /// You can call normal [File] methods
  static Future<File> createTempFile(String name) async {
    Directory tempDir = await getTemporaryDirectory();
    return File(p.join(tempDir.path, name));
  }

  /// * This function returns a [List] of [int howMany] of type [File] of recently created files.
  /// * [excludeHidded] if [true] hidden files will not be returned
  Future<List<File>> recentCreatedFiles(int howMany,
      {List<String> extensions,
      List<String> excludedPaths,
      excludeHidden: false}) async {
    List<File> recents = [];

    List<File> filesPaths = await filesTree(
        excludedPaths: excludedPaths,
        extensions: extensions,
        excludeHidden: excludeHidden);

    // note: in case that number of recent files are not sufficient, we limit the [howMany]
    // to the number of the found ones
    if (filesPaths.length < howMany) howMany = filesPaths.length;

    // adding
    HashMap<int, File> times = HashMap();
    filesPaths.forEach((file) => times
        .addAll({file.statSync().modified.millisecondsSinceEpoch.abs(): file}));
    for (var i = 0; i <= howMany; i++) {
      var _max = times.keys.toList().reduce(max);
      recents.add(times[_max]);

      times.remove(times.remove(_max));
    }

    return recents;
  }

  /// * This function returns a [List] of [int howMany] of type [String] of recently created files.
  /// * [excludeHidden] hidden files will not be returned
  Future<List<String>> recentCreatedFilesAsString(int howMany,
      {List<String> extensions,
      List<String> excludedPaths,
      excludeHidden: false}) async {
    List<String> recents = [];

    List<File> filesPaths = await filesTree(
        excludedPaths: excludedPaths,
        extensions: extensions,
        excludeHidden: excludeHidden);

    // note: in case that number of recent files are not sufficient, we limit the [howMany]
    // to the number of the found ones
    if (filesPaths.length < howMany) howMany = filesPaths.length;

    // adding
    HashMap<int, File> times = HashMap();
    filesPaths.forEach((file) => times
        .addAll({file.statSync().modified.millisecondsSinceEpoch.abs(): file}));
    for (var i = 0; i <= howMany; i++) {
      var _max = times.keys.toList().reduce(max);
      recents.add(times[_max].absolute.path);

      times.remove(times.remove(_max));
    }

    return recents;
  }

  /// Return list tree of directories.
  /// You may exclude some directories from the list.
  /// * [excludedPaths] will excluded paths and their subpaths from the final [list]
  Future<List<Directory>> dirsTree({
    List<String> excludedPaths,
    bool followLinks: false,
    bool excludeHidden: false,
  }) async {
    List<Directory> dirs = [];
    var contents;
    try {
      contents = root.listSync(recursive: true, followLinks: followLinks);
    } catch (FileSystemException) {
      print(_permissionMessage);
    }

    try {
      if (excludedPaths != null) {
        for (var fileOrDir in contents) {
          if (fileOrDir is Directory) {
            for (var excludedPath in excludedPaths) {
              if (!p.isWithin(excludedPath, p.normalize(fileOrDir.path))) {
                if (!excludeHidden) {
                  dirs.add(Directory(p.normalize(fileOrDir.absolute.path)));
                } else {
                  if (!fileOrDir.absolute.path.contains(RegExp(r"\.[\w]+"))) {
                    dirs.add(Directory(p.normalize(fileOrDir.absolute.path)));
                  }
                }
              }
            }
          }
        }
      } else {
        for (var fileOrDir in contents) {
          if (fileOrDir is Directory) {
            if (!excludeHidden) {
              dirs.add(Directory(p.normalize(fileOrDir.absolute.path)));
            } else {
              // The Regex below is used to check if the directory contains
              // ".folder" in pathe
              if (!fileOrDir.absolute.path.contains(RegExp(r"\.[\w]+"))) {
                dirs.add(Directory(p.normalize(fileOrDir.absolute.path)));
              }
            }
          }
        }
      }
    } catch (e) {
      return null;
    }
    return dirs;
  }

  /// This function returns files' paths list only from  specific location.
  /// * You may specify the types of the files you want to get by supplying the optional
  /// [extensions].
  ///
  static Future<List<File>> listFiles(String path,
      {List<String> extensions,
      followsLinks = false,
      excludeHidden = false}) async {
    List<File> files = [];
    List contents =
        Directory(path).listSync(followLinks: followsLinks, recursive: false);
    try {
      if (extensions != null) {
        // Future<List<String>> extensionsPatterns =
        //     RegexTools.makeExtensionPatterns(extensions);
        for (var fileOrDir in contents) {
          if (fileOrDir is File) {
            String file = p.normalize(fileOrDir.path);
            for (var extension in extensions) {
              if (p.extension(file).replaceFirst(".", "") ==
                  extension.replaceFirst('.', '')) {
                if (excludeHidden) {
                  if (file.startsWith('.'))
                    files.add(File(p.normalize(fileOrDir.absolute.path)));
                } else {
                  files.add(File(p.normalize(fileOrDir.absolute.path)));
                }
              }
            }
          }
        }
      } else {
        for (var fileOrDir in contents) {
          if (fileOrDir is File) {
            files.add(File(p.normalize(fileOrDir.absolute.path)));
          }
        }
      }
    } catch (e) {
      return null;
    }
    return files;
  }

  /// This function return list of folders , not paths, of type [String]
  /// * [hidden]: this parameter excludes folders starts with " . "
  /// * [excludedFolders]: this parameter excludes folders from the result
  /// * [excludedPaths]: not working currently
  /// * examples: ["Android", "Download", "DCIM", ....]
  static Future<List<String>> listFolder(Directory root,
      {List<String> excludedFolders,
      List<String> excludedPaths,
      bool hidden: true}) async {
    var dirs = root.listSync(recursive: false, followLinks: false);
    List<String> folders = [];

    try {
      for (var dir in dirs) {
        if (dir is Directory) {
          String folder = dir.path.toString().split(r"/").last;
          if (excludedFolders != null) {
            if (!excludedFolders.contains(folder)) {
              if (hidden == false) {
                if (!folder.startsWith(".")) {
                  folders.add(dir.path.toString().split(r"/").last);
                } else
                  folders.add(dir.path.toString().split(r"/").last);
              }
            }
          } else {
            if (hidden == false) {
              if (!folder.startsWith(".")) folders.add(folder);
            } else
              folders.add(folder);
          }
        }
      }
    } catch (e) {
      print(e);
      return null;
    }
    return folders;
  }

  /// Return a [List] of directories starting from the given path
  /// * [hidden] : [true] or [false] return hidden directory, like: "/storage/.thumbnails"
  /// * [true] will return hidden directories
  static Future<List<Directory>> listDirectories(String path,
      {excludeHidden: false, followLinks = false}) async {
    List<Directory> directories = [];
    List contents = new Directory(path)
        .listSync(followLinks: followLinks, recursive: false);
    try {
      if (excludeHidden == true) {
        for (var fileOrDir in contents) {
          if (fileOrDir is Directory) {
            if (!fileOrDir.path.startsWith("."))
              directories.add(Directory(p.normalize(fileOrDir.absolute.path)));
          }
        }
      } else {
        for (var fileOrDir in contents) {
          if (fileOrDir is Directory) {
            // dir/../dir3 to dir/dir2/dir3
            directories.add(Directory(p.normalize(fileOrDir.absolute.path)));
          }
        }
      }
    } catch (e) {
      return null;
    }
    return directories;
  }

  /// return tree [List] of files starting from the root of type [File]
  /// * [excludedPaths] example: '/storage/emulated/0/Android' no files will be
  /// returned from this path, and its sub directories
  Future<List<File>> filesTree(
      {List<String> extensions,
      List<String> excludedPaths,
      excludeHidden = false}) async {
    List<File> files = [];

    List<Directory> dirs = await dirsTree(
        excludedPaths: excludedPaths, excludeHidden: excludeHidden);

    dirs.insert(0, Directory(root.path));

    try {
      if (extensions != null) {
        for (var dir in dirs) {
          for (var file
              in await listFiles(dir.absolute.path, extensions: extensions)) {
            if (excludeHidden) {
              if (!file.path.startsWith("."))
                files.add(file);
              else
                print("Excluded: ${file.path}");
            } else {
              files.add(file);
            }
          }
        }
      } else {
        for (var dir in dirs) {
          for (var file in await listFiles(dir.absolute.path)) {
            if (excludeHidden) {
              if (!file.path.startsWith("."))
                files.add(file);
              else
                print("Excluded: ${file.path}");
            } else {
              files.add(file);
            }
          }
        }
      }
    } catch (e) {
      print(e);
      return null;
    }
    return files;
  }

  /// Return tree files [String] starting from the root of type
  /// * [excludedPaths] example: '/storage/emulated/0/Android' no files will be
  /// returned from this path, and its sub directories
  Future<List<String>> filesTreeAsString(
      {List<String> extensions,
      List<String> excludedPaths,
      excludeHidden = false}) async {
    List<String> files = [];

    List<Directory> dirs = await dirsTree(
        excludedPaths: excludedPaths, excludeHidden: excludeHidden);
    dirs.insert(0, Directory(root.path));

    try {
      if (extensions != null) {
        for (var dir in dirs) {
          for (var file
              in await listFiles(dir.absolute.path, extensions: extensions)) {
            if (excludeHidden) {
              if (!file.path.startsWith(".")) files.add(file.path);
            } else {
              files.add(file.path);
            }
          }
        }
      } else {
        for (var dir in dirs) {
          for (var file in await listFiles(dir.absolute.path)) {
            // hidden files e.g: .bashrc
            if (excludeHidden) {
              if (!file.path.startsWith(".")) files.add(file.path);
            } else {
              files.add(file.path);
            }
          }
        }
      }
    } catch (e) {
      print(e);
      return null;
    }
    return files;
  }

  /// Delete file not a directory
  /// e.g:
  /// deleteFile(/storage/emulated/0/myFile.txt")
  static Future<void> deleteFile(String path) async {
    //print("~ deleting:" + path);
    var file = File(path);
    try {
      file.delete();
    } catch (e) {
      print("error: $e");
    }
  }

  /// Returns a list of found items of [Directory] or [File] type or empty list.
  /// You may supply `Regular Expression` e.g: "*\.png", instead of string.
  /// * [filesOnly] if set to [true] return only files
  /// * [dirsOnly] if set to [true] return only directories
  /// * You can set both to [true]
  /// * Example:
  /// * List<String> imagesPaths = await FileManager.search("myFile.png");
  ///
  Future<List<String>> search(var keyword,
      {List<String> excludedPaths, filesOnly = false, dirsOnly = false, List<String> extensions}) async {
    print("Searching for: $keyword");
    if (keyword.length == 0 || keyword == null) {
      throw Exception("search keyword == null");
    }
    if (filesOnly == false && dirsOnly == false) {
      filesOnly = true;
      dirsOnly = true;
    }
    List<Directory> dirs = await dirsTree(excludedPaths: excludedPaths);
    List<File> files = await filesTree(excludedPaths: excludedPaths, extensions: extensions);
    List<String> founds = [];

    if (dirsOnly == true) {
      for (var dir in dirs) {
        if (dir.absolute.path.contains(keyword)) {
          founds.add(dir.absolute.path);
        }
      }
    }
    if (filesOnly == true) {
      for (var file in files) {
        if (file.absolute.path.contains(keyword)) {
          founds.add(file.absolute.path);
        }
      }
    }
    return founds;
  }

  /// Delete a directory recursively or not
  /// e.g:
  /// deleteFile(/storage/emulated/0/myFile.txt")
  static bool deleteDir(String path, {recursive: false}) {
    //print("~ deleting:" + path);
    if (File(path).existsSync()) {
      throw Exception("This is a file path not a directory path");
    }
    var file = File(path);
    try {
      file.delete(recursive: recursive);
      return true;
    } catch (_) {
      return false;
    }
  }
}
