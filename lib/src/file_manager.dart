// dart
import 'dart:async';
import 'dart:collection';
import 'dart:io';

// packages
import 'package:flutter_file_manager/src/sorting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// local files
import 'package:flutter_file_manager/src/time_tools.dart';

String permissionMessage = '''
    \n
    Try to add thes lines to your AndroidManifest.xml file

          `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>`
          `<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>`

    and grant storage permissions to your applicaion from app settings
    \n
    ''';

class FileManager {
  Directory root;
  FileManager({this.root}) : assert(root != null);

  /// * This function returns a [List] of [int howMany] of type [File] of recently created files.
  /// * [excludeHidded] if [true] hidden files will not be returned
  /// * sortedBy: [FileManagerSorting]
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<File>> recentCreatedFiles(int count,
      {List<String> extensions,
      List<String> excludedPaths,
      excludeHidden: false,
      FileManagerSorting sortedBy,
      bool reversed: false}) async {
    List<File> filesPaths = await filesTree(
        excludedPaths: excludedPaths,
        extensions: extensions,
        excludeHidden: excludeHidden);

    // note: in case that number of recent files are not sufficient, we limit the [howMany]
    // to the number of the found ones
    if (filesPaths.length < count) count = filesPaths.length;

    var _sorted = sortBy(filesPaths, FileManagerSorting.Date, reversed: true);

    // decrease length to howMany
    _sorted = _sorted.getRange(0, count).toList();

    if (sortedBy != null) {
      return sortBy(filesPaths, sortedBy, reversed: reversed);
    }

    return _sorted;
  }

  /// Return list tree of directories.
  /// You may exclude some directories from the list.
  /// * [excludedPaths] will excluded paths and their subpaths from the final [list]
  /// * sortedBy: [FileManagerSorting]
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<Directory>> dirsTree(
      {List<String> excludedPaths,
      bool followLinks: false,
      bool excludeHidden: false,
      FileManagerSorting sortedBy}) async {
    List<Directory> dirs = [];

    try {
      var contents = root.listSync(recursive: true, followLinks: followLinks);
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
              // ".file" in pathe
              if (!fileOrDir.absolute.path.contains(RegExp(r"\.[\w]+"))) {
                dirs.add(Directory(p.normalize(fileOrDir.absolute.path)));
              }
            }
          }
        }
      }
    } catch (error) {
      FileManagerError(permissionMessage + error.toString());
    }
    if (dirs != null) {
      return sortBy(dirs, sortedBy);
    }

    return dirs;
  }

  /// Return tree [List] of files starting from the root of type [File]
  /// * [excludedPaths] example: '/storage/emulated/0/Android' no files will be
  ///   returned from this path, and its sub directories
  /// * sortedBy: [FileManagerSorting]
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<File>> filesTree(
      {List<String> extensions,
      List<String> excludedPaths,
      excludeHidden = false,
      bool reversed: false,
      FileManagerSorting sortedBy}) async {
    List<File> files = [];

    List<Directory> dirs = await dirsTree(
        excludedPaths: excludedPaths, excludeHidden: excludeHidden);

    dirs.insert(0, Directory(root.path));

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

    if (sortedBy != null) {
      return sortBy(files, sortedBy);
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
    } catch (error) {
      FileManagerError(error.toString());
    }
  }

  /// return tree [List] of files starting from the root of type [File]
  /// * [excludedPaths] example: '/storage/emulated/0/Android' no files will be
  /// returned from this path, and its sub directories
  Future<List<dynamic>> walk({
    List<String> extensions,
    List<String> excludedPaths,
    excludeHidden = false,
  }) async {
    List<dynamic> tree = [];
    tree.insert(0, Directory(root.path));

    try {
      var _rawTree = root.listSync(followLinks: true, recursive: true);
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
              object,
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
              object,
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
    } catch (error) {
      FileManagerError(permissionMessage + error.toString());
    }

    return tree;
  }

  /// Returns a list of found items of [Directory] or [File] type or empty list.
  /// You may supply `Regular Expression` e.g: "*\.png", instead of string.
  /// * [filesOnly] if set to [true] return only files
  /// * [dirsOnly] if set to [true] return only directories
  /// * You can set both to [true]
  /// * sortedBy: [FileManagerSorting]
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
    FileManagerSorting sortedBy,
  }) async {
    print("Searching for: $keyword");
    // files that will be returned
    List<dynamic> founds = [];

    if (keyword.length == 0 || keyword == null) {
      throw Exception("search keyword == null");
    }

    List<Directory> dirs = await dirsTree(excludedPaths: excludedPaths);
    List<File> files =
        await filesTree(excludedPaths: excludedPaths, extensions: extensions);

    if (filesOnly == false && dirsOnly == false) {
      filesOnly = true;
      dirsOnly = true;
    }
    if (extensions.isNotEmpty) dirsOnly = false;
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
    } catch (error) {
      FileManagerError(error.toString());
      // could not delete the file then return false
      return false;
    }
  }

  // returns [File] or [Directory]
  /// * argument objects = [File] or [Directory]
  /// * argument by [String]: 'date', 'alpha', 'size'
  static List<dynamic> sortBy(List<dynamic> objects, FileManagerSorting by,
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
  static String getBaseName(String path, {bool extension: true}) {
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
  static Future<HashMap> details(dynamic path) async {
    HashMap _details = HashMap();
    if (path == null || (!path.existsSync() && !File(path).existsSync())) {
      print("file or dir does not exists");
      return null;
      // directory
    } else if (path.existsSync()) {
      // directory or file
      _details["type"] = path.statSync().type.toString();
      _details["lastChanged"] =
          TimeTools.timeNormalize(path.statSync().changed);
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

  /// This function creates temporary file on the device storage
  /// Return [File]
  /// You can call normal [File] methods
  static Future<File> cacheFile(String name) async {
    Directory tempDir = await getTemporaryDirectory();
    return File(p.join(tempDir.path, name));
  }

  /// This function returns files' paths list only from  specific location.
  /// * You may specify the types of the files you want to get by supplying the optional
  /// [extensions].
  /// * sortedBy: [FileManagerSorting]
  /// * [bool] reversed: in case parameter sortedBy is used
  static Future<List<File>> listFiles(String path,
      {List<String> extensions,
      followsLinks = false,
      excludeHidden = false,
      FileManagerSorting sortedBy,
      bool reversed: false}) async {
    List<File> files = [];

    try {
      List contents =
          Directory(path).listSync(followLinks: followsLinks, recursive: false);
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
    } catch (error) {
      FileManagerError(error.toString());
    }
    if (files != null) {
      return sortBy(files, sortedBy, reversed: reversed);
    }

    return files;
  }

  /// This function return list of folders of type [String] , not full paths [Directory].
  ///
  /// e.g: listFolders(Directory("/")) = root, usr, var, proc, mnt ...
  /// * [hidden]: this parameter excludes folders starts with " . "
  /// * [excludedFolders]: this parameter excludes folders from the result
  /// * sortedBy: [FileManagerSorting]
  /// * [bool] reversed: in case parameter sortedBy is used
  /// * examples: ["Android", "Download", "DCIM", ....]
  static Future<List<String>> listFolders(Directory path,
      {List<String> excludedFolders,
      List<String> excludedPaths,
      bool excludeHidden: false,
      followLinks: false,
      FileManagerSorting sortedBy,
      bool reversed: false}) async {
    List<String> folders = (await listDirectories(path,
            excludeHidden: excludeHidden,
            followLinks: false,
            reversed: reversed,
            sortedBy: sortedBy))
        .map((Directory directory) => p.split(directory.absolute.path).last)
        .toList();
    return folders;
  }

  /// Return a [List] of directories starting from the given path
  /// * [hidden] : [true] or [false] return hidden directory, like: "/storage/.thumbnails"
  /// * [true] will return hidden directories
  /// * sortedBy: [FileManagerSorting]
  /// * [bool] reversed: in case parameter sortedBy is used
  static Future<List<Directory>> listDirectories(Directory path,
      {excludeHidden: false,
      followLinks = false,
      FileManagerSorting sortedBy,
      bool reversed: false}) async {
    List<Directory> directories = [];
    try {
      List contents = path.listSync(followLinks: followLinks, recursive: false);
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
    } catch (error) {
      FileManagerError(permissionMessage + error.toString());
    }
    if (directories != null) {
      return sortBy(directories, sortedBy);
    }

    return directories;
  }
}

class FileManagerError extends Error {
  final String message;
  FileManagerError(this.message);
}
