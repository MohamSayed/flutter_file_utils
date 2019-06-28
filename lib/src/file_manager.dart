// dart
import 'dart:async';
import 'dart:io';

// packages
import 'package:flutter_file_manager/src/filter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// local files
import 'package:flutter_file_manager/src/sorting.dart';
import 'package:flutter_file_manager/src/utils.dart';

String permissionMessage = '''
    \n
    Try to add thes lines to your AndroidManifest.xml file

          `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>`
          `<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>`

    and grant storage permissions to your applicaion from app settings
    \n
''';

class FileManager {
  // The start point .
  Directory root;

  FileFilter filter;

  FileManager({this.root, this.filter}) : assert(root != null);

  /// * This function returns a [List] of [int howMany] of type [File] of recently created files.
  /// * [excludeHidded] if [true] hidden files will not be returned
  /// * sortedBy: [FileManagerSorting]
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<File>> recentFilesAndDirs(int count,
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
      throw FileManagerError(permissionMessage + error.toString());
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
  static Future<void> deleteAll(List<FileSystemEntity> files) async {
    try {
      for (var file in files) {
        file.delete();
      }
    } on FileSystemException catch (e) {
      throw FileManagerError(e.toString());
    } catch (e) {
      rethrow;
    }
  }

  /// Return tree [List] of files starting from the root of type [File].
  ///
  /// This function uses filter
  Stream<FileSystemEntity> walk({followLinks: false}) async* {
    if (filter != null) {
      try {
        yield* Directory(root.path)
            .list(recursive: true, followLinks: followLinks)
            .transform(StreamTransformer.fromHandlers(
                handleData: (FileSystemEntity fileOrDir, EventSink eventSink) {
          if (filter.validate(fileOrDir.absolute.path, root.absolute.path)) {
            eventSink.add(fileOrDir);
          }
        }));
      } catch (error) {
        throw FileManagerError(permissionMessage + error.toString());
      }
    } else {
      print("Flutter File Manager: walk: No filter");
      yield* Directory(root.path)
          .list(recursive: true, followLinks: followLinks);
    }
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
  Future<List<dynamic>> searchFuture(
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

  /// Returns a list of found items of [Directory] or [File] type or empty list.
  /// You may supply `Regular Expression` e.g: "*\.png", instead of string.
  /// * [filesOnly] if set to [true] return only files
  /// * [dirsOnly] if set to [true] return only directories
  /// * You can set both to [true]
  /// * sortedBy: [FileManagerSorting]
  /// * [bool] reverse: in case parameter sortedBy is used
  /// * Example:
  /// * `List<String> imagesPaths = await FileManager.search("myFile.png").toList();`
  Stream<FileSystemEntity> search(
    var keyword, {
    FileFilter searchFilter,
    FileManagerSorting sortedBy,
  }) async* {
    try {
      if (keyword.length == 0 || keyword == null) {
        throw FileManagerError("search keyword == null");
      }
      if (searchFilter != null) {
        print("Using default filter");
        yield* root.list(recursive: true, followLinks: true).where((test) {
          if (searchFilter.validate(test.absolute.path, root.absolute.path)) {
            return getBaseName(test.path, extension: true).contains(keyword);
          }
          return false;
        });
      } else if (filter != null) {
        print("Using default filter");
        yield* root.list(recursive: true, followLinks: true).where((test) {
          if (filter.validate(test.absolute.path, root.absolute.path)) {
            return getBaseName(test.path, extension: true).contains(keyword);
          }
          return false;
        });
      } else {
        yield* root.list(recursive: true, followLinks: true).where((test) =>
            getBaseName(test.path, extension: true).contains(keyword));
      }
    } on FileSystemException catch (e) {
      throw FileManagerError(permissionMessage + ' ' + e.toString());
    } catch (e) {
      throw FileManagerError(e.toString());
    }
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
      throw FileManagerError(error.toString());
    }
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
      throw FileManagerError(error.toString());
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
      throw FileManagerError(permissionMessage + error.toString());
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

  @override
  String toString() {
    return message;
  }
}
