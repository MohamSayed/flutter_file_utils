// dart
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// packages
import 'package:path/path.dart' as p;

// local files
import './regex_tools.dart';
import './time_tools.dart';
import 'package:flutter_file_manager/src/cutsom_file.dart';

class FileManager {
  Directory root;
  FileManager({this.root}) : assert(root != null);

  /// Returns a [HashMap] containing detials of the file or the directory.
  /// keys list:
  /// type, lastChanged, lastModified, size
  /// permissions, lastAccessed, extension
  /// you can use details from [Directory] of [File] instead
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

  /// This function returns a [List] of [int howMany] recently created files.
  /// [excludeHidded] means that files that its folder are hidden will not be added
  Future<List<String>> recentCreatedFiles(int howMany,
      {List<String> extensions,
      List<String> excludedPaths,
      excludeHidden: false}) async {
    List<String> recents = [];

    List<String> filesPaths =
        await filesTree(excludedPaths: excludedPaths, extensions: extensions);

    // note: in case that number of recent files are not sufficient, we limit the [howMany]
    // to the number of the found ones
    if (filesPaths.length < howMany) howMany = filesPaths.length;

    // adding
    HashMap<int, String> times = HashMap();
    filesPaths.forEach((file) => times.addAll(
        {File(file).statSync().modified.millisecondsSinceEpoch.abs(): file}));
    for (var i = 0; i <= howMany; i++) {
      var _max = times.keys.toList().reduce(max);
      recents.add(times[_max]);

      times.remove(times.remove(_max));
    }

    return recents;
  }

  /// Return list tree of directories.
  /// You may exclude some directories from the list .
  Future<List<String>> dirsTree(
      {List<String> excludedPaths, bool followLinks: false}) async {
    List<String> dirsList = [];
    var contents;
    try {
      contents = root.listSync(recursive: true, followLinks: followLinks);
    } catch (e) {
      print(Permisions)
    }

    try {
      if (excludedPaths != null) {
        for (var fileOrDir in contents) {
          if (fileOrDir is Directory) {
            if (!RegexTools.deeperPathCheckAll(
                root.path + r'/' + fileOrDir.path.replaceFirst('.', ''),
                excludedPaths)) {
              //print(fileOrDir.path);
              dirsList.add(p.normalize(fileOrDir.path));
            }
          }
        }
      } else {
        for (var fileOrDir in contents) {
          if (fileOrDir is Directory) {
            //print(fileOrDir.path);
            dirsList.add(p.normalize(fileOrDir.path));
          }
        }
      }
    } catch (e) {
      //return null;
    }
    return dirsList;
  }

  static _buildPath(String path) {
    String currentDir = '';
    if (path == '.' &&
        !path.startsWith(r"\") &&
        !path.startsWith(r"/") &&
        !path.startsWith(RegExp('\d:') // for Windows platforms
            )) {
      currentDir = Directory.current.path;
    }

    return currentDir;
  }

  /// This function returns files' paths list only from  specific location.
  /// You may specify the types of the files you want to get by supplying the optional
  /// parameter [extensions].
  ///
  static Future<List<String>> listFiles(String path,
      {List<String> extensions}) async {
    List<String> paths = [];
    List contents =
        Directory(path).listSync(followLinks: false, recursive: false);
    //String currentDir = _buildPath(path);
    try {
      if (extensions != null) {
        Future<List<String>> extensionsPatterns =
            RegexTools.makeExtensionPatternList(extensions);
        for (var fileOrDir in contents) {
          if (fileOrDir is File) {
            for (var extension in await extensionsPatterns) {
              if (RegexTools.checkExtension(extension, fileOrDir.path)) {
                paths.add(p.normalize(path + fileOrDir.path));
              }
            }
          }
        }
      } else {
        for (var fileOrDir in contents) {
          if (fileOrDir is File) {
            paths.add(p.normalize(path + fileOrDir.path));
          }
        }
      }
    } catch (e) {
      return null;
    }
    return paths;
  }

  /// This function return list of folders not paths
  /// [hidden]: this parameter excludes folders starts with " . "
  /// [excludedFolders]: this parameter excludes folders from the result
  /// [excludedPaths]: not working currently
  static Future<List<String>> folderList(Directory root,
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

  /// return [List] directories from specific path
  /// [hidden] : [true] or [false] return hidden directory, like: "/storage/.thumbnails"
  /// [true] will return hidden directories
  static Future<List<String>> getDirectories(String path,
      {hidden: true}) async {
    List<String> directories = [];
    List contents =
        new Directory(path).listSync(followLinks: false, recursive: false);
    String currentDir = _buildPath(path);
    try {
      if (hidden == false) {
        for (var fileOrDir in contents) {
          if (fileOrDir is Directory) {
            if (!fileOrDir.path.startsWith("."))
              directories.add(p.normalize(currentDir + fileOrDir.path));
          }
        }
      } else {
        for (var fileOrDir in contents) {
          if (fileOrDir is Directory) {
            // dir/../dir3 to dir/dir2/dir3
            directories.add(p.normalize(currentDir + fileOrDir.path));
          }
        }
      }
    } catch (e) {
      return null;
    }
    return directories;
  }

  /// return tree [List] of files starting from the root
  Future<List<String>> filesTree(
      {List<String> extensions, List<String> excludedPaths}) async {
    List<String> files = [];

    List<String> dirs = await dirsTree();
    dirs.insert(0, root.path);

    try {
      if (extensions != null) {
        for (var dir in dirs) {
          for (var file in await listFiles(dir, extensions: extensions)) {
            files.add(file);
          }
        }
      } else {
        for (var dir in dirs) {
          for (var file in await listFiles(dir)) {
            files.add(file);
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

  /// Returns a list of found items or empty list.
  /// You may supply `Regular Expression` e.g: "*\.png", instead of string.
  /// Example:
  /// List<String> imagesPaths = await FileManager.search("/storage/emulated/0/", "png");
  Future<List<String>> search(var keyword) async {
    print("Searching for: $keyword");
    if (keyword.length == 0 || keyword == null) {
      throw Exception("search keyword == null");
    }
    Future<List<String>> dirs = dirsTree();
    List<String> files = await filesTree();
    //print(files);
    List<String> founds = [];
    for (var dir in await dirs) {
      if (RegexTools.searchCheck(dir, keyword)) {
        founds.add(dir);
      }
    }

    for (var file in files) {
      if (RegexTools.searchCheck(file, keyword)) {
        //print(file);
        founds.add(file);
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
