// dart
import 'dart:async';
import 'dart:collection';
import 'dart:io';

// packages
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// local files
import 'package:flutter_file_manager/src/time_tools.dart';

class FileManager {
  Directory root;
  String _permissionMessage = '''
    \n
    Try to add thes lines to your AndroidManifest.xml file

          `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>`
          `<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>`

    and grant storage permissions to your applicaion from app settings
    \n
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
  /// * sortedBy: 'type', 'size', 'date', 'alpha'
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<File>> recentCreatedFiles(int howMany,
      {List<String> extensions,
      List<String> excludedPaths,
      excludeHidden: false,
      String sortedBy,
      bool reversed: false}) async {
    List<File> filesPaths = await filesTree(
        excludedPaths: excludedPaths,
        extensions: extensions,
        excludeHidden: excludeHidden);

    // note: in case that number of recent files are not sufficient, we limit the [howMany]
    // to the number of the found ones
    if (filesPaths.length < howMany) howMany = filesPaths.length;

    var _sorted = sortBy(filesPaths, 'date', reversed: true);

    // decrease length to howMany
    _sorted = _sorted.getRange(0, howMany).toList();

    if (sortedBy != null) {
      return sortBy(filesPaths, sortedBy, reversed: reversed);
    }

    return _sorted;
  }

  /// This function returns a [List] of [int howMany] of type [String] of recently created files.
  /// * [excludeHidden] hidden files will not be returned
  /// * sortedBy: 'type', 'size', 'date', 'alpha'
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<String>> recentCreatedFilesAsStringList(int howMany,
      {List<String> extensions,
      List<String> excludedPaths,
      excludeHidden: false,
      String sortedBy,
      bool reversed: false}) async {
    List<String> _recents = [];

    List<File> filesPaths = await filesTree(
        excludedPaths: excludedPaths,
        extensions: extensions,
        excludeHidden: excludeHidden);

    // note: in case that number of recent files are not sufficient, we limit the [howMany]
    // to the number of the found ones
    if (filesPaths.length < howMany) howMany = filesPaths.length;

    var _sorted = sortBy(filesPaths, 'date', reversed: true);

    // decrease length to howMany
    _sorted = _sorted.getRange(0, howMany).toList();

    // to string
    _sorted.forEach((f) => _recents.add(f.path));

    if (sortedBy != null) {
      return sortBy(filesPaths, sortedBy, reversed: reversed);
    }
    return _recents;
  }

  /// Return list tree of directories.
  /// You may exclude some directories from the list.
  /// * [excludedPaths] will excluded paths and their subpaths from the final [list]
  /// * sortedBy: 'type', 'size', 'date', 'alpha'
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<Directory>> dirsTree(
      {List<String> excludedPaths,
      bool followLinks: false,
      bool excludeHidden: false,
      String sortedBy}) async {
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
    if (dirs != null) {
      return sortBy(dirs, sortedBy);
    }

    return dirs;
  }

  /// This function returns files' paths list only from  specific location.
  /// * You may specify the types of the files you want to get by supplying the optional
  /// [extensions].
  /// * sortedBy: 'type', 'size', 'date', 'alpha'
  /// * [bool] reversed: in case parameter sortedBy is used
  static Future<List<File>> listFiles(String path,
      {List<String> extensions,
      followsLinks = false,
      excludeHidden = false,
      String sortedBy,
      bool reversed: false}) async {
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
    if (files != null) {
      return sortBy(files, sortedBy, reversed: reversed);
    }

    return files;
  }

  /// This function return list of folders of type [String] , not paths of [Directory].
  /// * [hidden]: this parameter excludes folders starts with " . "
  /// * [excludedFolders]: this parameter excludes folders from the result
  /// * sortedBy: 'type', 'size', 'date', 'alpha'
  /// * [bool] reversed: in case parameter sortedBy is used
  /// * examples: ["Android", "Download", "DCIM", ....]
  static Future<List<String>> listFolder(Directory root,
      {List<String> excludedFolders,
      List<String> excludedPaths,
      bool hidden: true,
      String sortedBy,
      bool reversed: false}) async {
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
    if (folders != null) {
      return sortByFromStringList(
          folders.map((folder) => p.join(root.absolute.path, folder)), sortedBy,
          reversed: reversed);
    }

    return folders;
  }

  /// Return a [List] of directories starting from the given path
  /// * [hidden] : [true] or [false] return hidden directory, like: "/storage/.thumbnails"
  /// * [true] will return hidden directories
  /// * sortedBy: 'type', 'size', 'date', 'alpha'
  /// * [bool] reversed: in case parameter sortedBy is used

  static Future<List<Directory>> listDirectories(String path,
      {excludeHidden: false,
      followLinks = false,
      String sortedBy,
      bool reversed: false}) async {
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
    if (directories != null) {
      return sortBy(directories, sortedBy);
    }

    return directories;
  }

  /// Return tree [List] of files starting from the root of type [File]
  /// * [excludedPaths] example: '/storage/emulated/0/Android' no files will be
  /// returned from this path, and its sub directories
  /// * sortedBy: 'type', 'size', 'date', 'alpha'
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<File>> filesTree(
      {List<String> extensions,
      List<String> excludedPaths,
      excludeHidden = false,
      bool reversed: false,
      String sortedBy}) async {
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

    if (sortedBy != null) {
      return sortBy(files, sortedBy);
    }

    return files;
  }

  /// Return tree files [String] starting from the root of type
  /// * [excludedPaths] example: '/storage/emulated/0/Android' no files will be
  /// returned from this path, and its sub directories
  /// * sortedBy: 'type', 'size', 'date', 'alpha'
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<String>> filesTreeAsStringList(
      {List<String> extensions,
      List<String> excludedPaths,
      excludeHidden = false,
      bool reversed: false,
      String sortedBy}) async {
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

    if (files != null) {
      return sortByFromStringList(
          files.map((file) => p.join(root.absolute.path, file)).toList(),
          sortedBy,
          reversed: reversed);
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
  /// * sortedBy: 'type', 'size', 'date', 'alpha'
  /// * [bool] reversed: in case parameter sortedBy is used
  /// * Example:
  /// * List<String> imagesPaths = await FileManager.search("myFile.png");
  Future<List<dynamic>> search(
    var keyword, {
    List<String> excludedPaths,
    filesOnly = false,
    dirsOnly = false,
    List<String> extensions,
    bool reversed: false,
    String sortedBy,
  }) async {
    print("Searching for: $keyword");
    if (keyword.length == 0 || keyword == null) {
      throw Exception("search keyword == null");
    }

    if (filesOnly == false && dirsOnly == false) {
      filesOnly = true;
      dirsOnly = true;
    }

    List<Directory> dirs = await dirsTree(excludedPaths: excludedPaths);
    List<File> files =
        await filesTree(excludedPaths: excludedPaths, extensions: extensions);

    // files that will be returned
    List<dynamic> founds = [];

    // in the future fileAndDirTree will be used
    // searching in files
    if (dirsOnly == true) {
      for (var dir in dirs) {
        if (dir.absolute.path.contains(keyword)) {
          founds.add(dir);
        }
      }
    }
    // searching in files

    if (filesOnly == true) {
      for (var file in files) {
        if (file.absolute.path.contains(keyword)) {
          founds.add(file);
        }
      }
    }

    // sorting
    if (sortedBy != null) {
      return sortBy(founds, sortedBy);
    }
    return founds;
  }

  /// Delete a directory recursively or not
  /// e.g:
  /// * deleteFile(/storage/emulated/0/myFile.txt")
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

  // returns [File] or [Directory]
  /// * argument objects = [File] or [Directory]
  /// * argument by [String]: 'date', 'alpha', 'size'
  static List<dynamic> sortBy(List<dynamic> objects, String by,
      {bool reversed: false}) {
    switch (by) {
      case 'alpha':
        objects
            .sort((a, b) => getBaseName(a.path).compareTo(getBaseName(b.path)));
        break;

      case 'date':
        objects.sort((a, b) {
          return a
              .statSync()
              .modified
              .millisecondsSinceEpoch
              .compareTo(b.statSync().modified.millisecondsSinceEpoch);
        });
        break;

      case 'size':
        objects.sort((a, b) {
          return a.statSync().size.compareTo(b.statSync().size);
        });
        break;

      case 'type':
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

  /// objects = [File] or [Directory]
  /// argument [by] [String]: 'date', 'alpha', 'size'
  static List<dynamic> sortByFromStringList(List<String> objects, String by,
      {bool reversed: false}) {
    switch (by) {
      case 'alpha':
        objects.sort((a, b) => getBaseName(a).compareTo(getBaseName(b)));
        break;

      case 'date':
        objects.sort((a, b) {
          return File(a)
              .statSync()
              .modified
              .millisecondsSinceEpoch
              .compareTo(File(b).statSync().modified.millisecondsSinceEpoch);
        });
        break;

      case 'size':
        objects.sort((a, b) {
          return File(a).statSync().size.compareTo(File(b).statSync().size);
        });
        break;

      case 'type':
        objects.sort((a, b) {
          return p.extension(File(a).path).compareTo(p.extension(File(b).path));
        });

        break;
      default:
        objects.sort((a, b) => getBaseName(a).compareTo(getBaseName(b)));
    }
    if (reversed == true) {
      return objects.reversed.toList();
    }
    return objects;
  }

  static String getBaseName(String path) {
    return p.split(path).last;
  }

  /// return tree [List] of files starting from the root of type [File]
  /// * [excludedPaths] example: '/storage/emulated/0/Android' no files will be
  /// returned from this path, and its sub directories
  Future<List<dynamic>> fileAndDirTree({
    List<String> extensions,
    List<String> excludedPaths,
    excludeHidden = false,
  }) async {
    var _rawTree = root.listSync(followLinks: true, recursive: true);
    List<dynamic> tree = [];
    tree.insert(0, Directory(root.path));

    try {
      if (extensions != null) {
        for (var object in _rawTree) {
          if (object is File) {
            if (excludeHidden) {
              if (!object.path.startsWith(".")) tree.add(object);
            } else {
              tree.add(object);
            }
            // directory
          } else {
            for (var dir in await listDirectories(
              object.absolute.path,
            )) {
              if (excludeHidden) {
                if (!dir.path.startsWith(".")) tree.add(dir);
              } else {
                tree.add(dir);
              }
            }
          }
        }

        // extensions is null
      } else {
        for (var object in _rawTree) {
          if (object is File) {
            if (excludeHidden) {
              if (!object.path.startsWith(".")) tree.add(object);
            } else {
              tree.add(object);
            }
          } else {
            for (var dir in await listDirectories(
              object.absolute.path,
            )) {
              if (excludeHidden) {
                if (!dir.path.startsWith(".")) tree.add(dir);
              } else {
                tree.add(dir);
              }
            }
          }
        }
      }
    } catch (e) {
      print(e);
      return null;
    }

    return tree;
  }
}