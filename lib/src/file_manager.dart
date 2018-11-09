import 'dart:async';
import 'dart:collection';
import 'dart:io';
import './regex_tools.dart';
import './time_tools.dart';
import 'package:path/path.dart' as p;

class FileManager {
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
  static Future<List<String>> recentCreatedFiles(List paths, int howMany,
      {List<String> extensions, List excludedPaths}) async {
    List<String> recentFilesPaths = [];
    if (paths.length < howMany) howMany = paths.length;
    for (int i = 0; i < howMany; i++) {
      String rcf = await recentCreatedFile(paths);
      recentFilesPaths.add(rcf);
      paths.remove(rcf);
    }

    return recentFilesPaths;
  }

  static Future<String> recentCreatedFile(paths) async {
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
  ///
  static Future<List<String>> dirsTree(String path,
      {List<String> excludedDirs, bool followLinks: false}) async {
    List<String> dirsList = [];

    String currentDir = _buildPath(path);
    List contents =
        new Directory(path).listSync(recursive: true, followLinks: followLinks);
    try {
      if (excludedDirs != null) {
        for (var fileOrDir in contents) {
          if (fileOrDir is Directory) {
            if (!RegexTools.deeperPathCheckAll(
                currentDir + fileOrDir.path.replaceFirst('.', ''),
                excludedDirs)) {
              //print(fileOrDir.path);
              dirsList.add(p.normalize(fileOrDir.path));
            }
          }
        }
      } else {
        for (var fileOrDir in contents) {
          if (fileOrDir is Directory) {
            // print(fileOrDir.path);
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
    List<String> filesList = [];
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
                filesList.add(p.normalize(currentDir + fileOrDir.path));
              }
            }
          }
        }
      } else {
        for (var fileOrDir in contents) {
          if (fileOrDir is File) {
            filesList.add(p.normalize(currentDir + fileOrDir.path));
          }
        }
      }
    } catch (e) {
      return null;
    }
    return filesList;
  }

  static Future<List<String>> filesTreeList(String path,
      {List<String> extensions, List<String> excludedDirs}) async {
    List<String> filesList = [];
    List<String> dirsTreeList =
        await dirsTree(path, excludedDirs: excludedDirs);
    try {
      if (extensions != null) {
        for (var dir in dirsTreeList) {
          for (var file in await listFiles(dir, extensions: extensions)) {
            //print(file);
            filesList.add(file);
          }
        }
      } else {
        for (var dir in dirsTreeList) {
          for (var file in await listFiles(dir)) {
            //print(file);
            filesList.add(file);
          }
        }
      }
    } catch (e) {
      print(e);
      return null;
    }
    return filesList;
  }

  static Future deleteFile(String path, {recursive: false}) async {
    //print("~ deleting:" + path);
    var file = File(path);
    try {
      file.delete(recursive: recursive);
    } catch (e) {
      print("error while deleting a file: $e");
    }
  }

  /// Returns a list of found items or empty list.
  /// You may supply `Regular Expression` e.g: "*\.png", instead of string.
  /// Example:
  /// List<String> imagesPaths = await FileManager.search("/storage/emulated/0/", "png");
  static Future<List<String>> search(String path, var keyword) async {
    Future<List<String>> dirs = dirsTree(path);
    Future<List<String>> files = filesTreeList(path);
    //print(files);
    List<String> founds = [];
    for (var dir in await dirs) {
      if (RegexTools.searchCheck(dir, keyword)) {
        founds.add(dir);
      }
    }

    for (var file in await files) {
      if (RegexTools.searchCheck(file, keyword)) {
        //print(file);
        founds.add(file);
      }
    }
    return founds;
  }

  static bool deleteDir(String path, {recursive: false}) {
    //print("~ deleting:" + path);
    if (File(path).existsSync()) {
      throw Exception("This is file path not directory path");
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
