import 'dart:async';
import 'dart:collection';
import 'dart:io';
import './regex_tools.dart';
import './time_tools.dart';
import 'package:path/path.dart' as p;

class FileManager {
  String root;
  FileManager({this.root}) : assert(root != null);

  /// Returns a [HashMap] containing detials of the file or the directory.
  /// keys:
  /// type, lastChanged, lastModified, size
  /// permissions, lastAccessed
  ///
  static Future<HashMap> fileDetails(String path) async {
    HashMap detailsList = HashMap();
    if (path == null ||
        (!Directory(path).existsSync() && !File(path).existsSync())) {
      print("path = null");
      return null;
    } else if (Directory(path).existsSync()) {
      detailsList["type"] = Directory(path).statSync().type.toString();
      detailsList["lastChanged"] =
          TimeTools.timeNormalize(Directory(path).statSync().changed);
      detailsList["lastModified"] = TimeTools.timeNormalize(
          Directory.fromUri(Uri.parse(path)).statSync().modified);
      detailsList["size"] = Directory(path).statSync().size;
      detailsList["lastAccessed"] =
          TimeTools.timeNormalize(Directory(path).statSync().accessed);
      detailsList["permissions"] = Directory(path).statSync().modeString();
      return detailsList;
    } else if (File(path).existsSync()) {
      var fileStat = File(path).statSync();
      detailsList["type"] = fileStat.type.toString();
      detailsList["lastModified"] = TimeTools.timeNormalize(fileStat.modified);
      detailsList["lastAccessed"] = TimeTools.timeNormalize(fileStat.accessed);
      detailsList["lastChanged"] = TimeTools.timeNormalize(fileStat.changed);
      detailsList["size"] = fileStat.size;
      detailsList["permissions"] = fileStat.modeString();
      return detailsList;
    }
    return null;
  }

  /// This function returns a [List] of [int howMany] recently created files.
  /// You may use `listFiles()` as paths to this function
  Future<List<String>> recentCreatedFiles(int howMany,
      {List<String> extensions, List<String> excludedPaths}) async {
    List<String> recentFilesPaths = [];

    List<String> filesPaths =
        await filesTree(excludedPaths: excludedPaths, extensions: extensions);

    if (filesPaths.length < howMany) howMany = filesPaths.length;

    for (int i = 0; i < howMany; i++) {
      String rcf = await _recentCreatedFile(filesPaths);
      recentFilesPaths.add(rcf);
      filesPaths.remove(rcf);
    }

    return recentFilesPaths;
  }

  static Future<String> _recentCreatedFile(paths) async {
    String recentFilepath = paths[0];

    for (var path in paths) {
      if (File(recentFilepath)
              .statSync()
              .modified
              .compareTo(File(path).statSync().modified) ==
          -1) {
        recentFilepath = path;
      }
    }
    return recentFilepath;
  }

  /// Return list tree of directories.
  /// You may exclude some directories from the list .
  Future<List<String>> dirsTree(
      {List<String> excludedPaths, bool followLinks: false}) async {
    List<String> dirsList = [];

    //String currentDir = _buildPath(root);
    List contents =
        new Directory(root).listSync(recursive: true, followLinks: followLinks);
    try {
      if (excludedPaths != null) {
        for (var fileOrDir in contents) {
          if (fileOrDir is Directory) {
            if (!RegexTools.deeperPathCheckAll(
                root + r'/' + fileOrDir.path.replaceFirst('.', ''),
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

  /// This function returns files' paths list only of from  specific location.
  /// You may specify the types of the files you want to get by supplying the optional
  /// parameter [extensions].
  ///
  static Future<List<String>> listFiles(String path,
      {List<String> extensions}) async {
    List<String> dirs = [];
    List contents =
        new Directory(path).listSync(followLinks: false, recursive: false);
    String currentDir = _buildPath(path);
    try {
      if (extensions != null) {
        Future<List<String>> extensionsPatterns =
            RegexTools.makeExtensionPatternList(extensions);
        for (var fileOrDir in contents) {
          if (fileOrDir is File) {
            for (var extension in await extensionsPatterns) {
              if (RegexTools.checkExtension(extension, fileOrDir.path)) {
                dirs.add(p.normalize(currentDir + fileOrDir.path));
              }
            }
          }
        }
      } else {
        for (var fileOrDir in contents) {
          if (fileOrDir is File) {
            dirs.add(p.normalize(currentDir + fileOrDir.path));
          }
        }
      }
    } catch (e) {
      return null;
    }
    return dirs;
  }

  /// return a [List] of path starting from the root
  Future<List<String>> filesTree(
      {List<String> extensions, List<String> excludedPaths}) async {
    List<String> files = [];

    List<String> dirs = await dirsTree();

    try {
      if (extensions != null) {
        for (var dir in dirs) {
          for (var file in await listFiles(dir, extensions: extensions)) {
            //print(file);
            files.add(file);
          }
        }
      } else {
        for (var dir in dirs) {
          for (var file in await listFiles(dir)) {
            //print(file);
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
