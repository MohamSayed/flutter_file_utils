// dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'exceptions.dart';
import 'file_system_utils.dart';
import 'filter.dart';
import 'sorting.dart';

final String permissionMessage = '''
    \n
    Try to add thes lines to your AndroidManifest.xml file

          `<uses-permission android:name='android.permission.WRITE_EXTERNAL_STORAGE'/>`
          `<uses-permission android:name='android.permission.READ_EXTERNAL_STORAGE'/>`

    and grant storage permissions to your applicaion from app settings
    \n
''';

class FileManager {
  // The start point .
  Directory root;

  FileFilter filter;

  FileManager({@required this.root, this.filter}) : assert(root != null);

  /// * This function returns a [List] of [int howMany] of type [File] of recently created files.
  /// * [excludeHidded] if [true] hidden files will not be returned
  /// * sortedBy: [Sorting]
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<FileSystemEntity>> recentFilesAndDirs(int count,
      {List<String> extensions,
      List<String> excludedPaths,
      bool excludeHidden = false,
      FlutterFileUtilsSorting sortedBy,
      bool reversed = false}) async {
    var filesPaths = await filesTree(
        excludedPaths: excludedPaths,
        extensions: extensions,
        excludeHidden: excludeHidden);

    // note: in case that number of recent files are not sufficient, we limit the [howMany]
    // to the number of the found ones
    if (filesPaths.length < count) count = filesPaths.length;

    var _sorted =
        sortBy(filesPaths, FlutterFileUtilsSorting.Date, reversed: true);

    // decrease length to howMany
    _sorted = _sorted.getRange(0, count).toList();

    if (sortedBy != null) {
      _sorted = sortBy(filesPaths, sortedBy, reversed: reversed);
      _sorted = _sorted.getRange(0, count).toList();
    }

    return _sorted;
  }

  /// Return list tree of directories.
  /// You may exclude some directories from the list.
  /// * [excludedPaths] will excluded paths and their subpaths from the final [list]
  /// * sortedBy: [FlutterFileUtilsSorting]
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<FileSystemEntity>> dirsTree(
      {List<String> excludedPaths,
      bool followLinks = false,
      bool excludeHidden = false,
      FlutterFileUtilsSorting sortedBy}) async {
    var dirs = <Directory>[];

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
                  if (!fileOrDir.absolute.path.contains(RegExp(r'\.[\w]+'))) {
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
              // '.file' in pathe
              if (!fileOrDir.absolute.path.contains(RegExp(r'\.[\w]+'))) {
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
  /// * sortedBy: [Sorting]
  /// * [bool] reversed: in case parameter sortedBy is used
  Future<List<FileSystemEntity>> filesTree(
      {List<String> extensions,
      List<String> excludedPaths,
      bool excludeHidden = false,
      bool reversed = false,
      FlutterFileUtilsSorting sortedBy}) async {
    var files = <FileSystemEntity>[];

    var dirs = await dirsTree(
        excludedPaths: excludedPaths, excludeHidden: excludeHidden);

    dirs.insert(0, Directory(root.path));

    if (extensions != null) {
      for (var dir in dirs) {
        for (var file
            in await listFiles(dir.absolute.path, extensions: extensions)) {
          if (excludeHidden) {
            if (!file.path.startsWith('.')) {
              files.add(file);
            } else {
              print('Excluded: ${file.path}');
            }
          } else {
            files.add(file);
          }
        }
      }
    } else {
      for (var dir in dirs) {
        for (var file in await listFiles(dir.absolute.path)) {
          if (excludeHidden) {
            if (!file.path.startsWith('.')) {
              files.add(file);
            } else {
              print('Excluded: ${file.path}');
            }
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

  /// Return tree [List] of files starting from the root of type [File].
  ///
  /// This function uses filter
  Stream<FileSystemEntity> walk({bool followLinks = false}) async* {
    if (filter != null) {
      try {
        yield* Directory(root.path)
            .list(recursive: true, followLinks: followLinks)
            .transform(StreamTransformer.fromHandlers(
                handleData: (FileSystemEntity fileOrDir, EventSink eventSink) {
          if (filter.isValid(fileOrDir.absolute.path, root.absolute.path)) {
            eventSink.add(fileOrDir);
          }
        }));
      } catch (error) {
        throw FileManagerError(permissionMessage + error.toString());
      }
    } else {
      print('Flutter File Manager: walk: No filter');
      yield* Directory(root.path)
          .list(recursive: true, followLinks: followLinks);
    }
  }

  /// Returns a list of found items of [Directory] or [File] type or empty list.
  /// You may supply `Regular Expression` e.g: '*\.png', instead of string.
  /// * [filesOnly] if set to [true] return only files
  /// * [dirsOnly] if set to [true] return only directories
  /// * You can set both to [true]
  /// * sortedBy: [Sorting]
  /// * [bool] reversed: in case parameter sortedBy is used
  /// * Example:
  /// * List<String> imagesPaths = await FileManager.search('myFile.png');
  Future<List<FileSystemEntity>> searchFuture(
    String keyword, {
    List<String> excludedPaths,
    bool filesOnly = false,
    bool dirsOnly = false,
    List<String> extensions,
    bool reversed = false,
    FlutterFileUtilsSorting sortedBy,
  }) async {
    print('Searching for: $keyword');
    // files that will be returned
    var founds = <FileSystemEntity>[];

    if (keyword.isEmpty || keyword == null) {
      throw Exception('search keyword == null');
    }

    var dirs = await dirsTree(excludedPaths: excludedPaths);
    var files =
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
  /// You may supply `Regular Expression` e.g: '*\.png', instead of string.
  /// * [filesOnly] if set to [true] return only files
  /// * [dirsOnly] if set to [true] return only directories
  /// * You can set both to [true]
  /// * sortedBy: [FlutterFileUtilsSorting]
  /// * [bool] reverse: in case parameter sortedBy is used
  /// * Example:
  /// * `List<String> imagesPaths = await FileManager.search('myFile.png').toList();`
  Stream<FileSystemEntity> search(
    String keyword, {
    FileFilter searchFilter,
    FlutterFileUtilsSorting sortedBy,
  }) async* {
    try {
      if (keyword.isEmpty || keyword == null) {
        throw FileManagerError('search keyword == null');
      }
      if (searchFilter != null) {
        print('Using default filter');
        yield* root.list(recursive: true, followLinks: true).where((test) {
          if (searchFilter.isValid(test.absolute.path, root.absolute.path)) {
            return getBaseName(test.path, extension: true).contains(keyword);
          }
          return false;
        });
      } else if (filter != null) {
        print('Using default filter');
        yield* root.list(recursive: true, followLinks: true).where((test) {
          if (filter.isValid(test.absolute.path, root.absolute.path)) {
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
}
