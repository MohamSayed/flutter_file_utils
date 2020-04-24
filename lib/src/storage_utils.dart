// dart sdk
import 'dart:io';

import 'package:package_info/package_info.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';

/// Return all **paths**
Future<List<Directory>> getStorageList() async {
  var paths = await getExternalStorageDirectories();
  var filteredPaths = <Directory>[];
  for (var dir in paths) {
    filteredPaths
        .add(await getExternalStorageWithoutDataDir(dir.absolute.path));
  }
  return filteredPaths;
}

/// This function aims to get path like: `/storage/emulated/0/`
/// not like `/storage/emulated/0/Android/data/package.name.example/files`
Future<Directory> getExternalStorageWithoutDataDir(
    String unfilteredPath) async {
  var packageInfo = await PackageInfo.fromPlatform();
  print('storage_helper->getExternalStorageWithoutDataDir: ' +
      packageInfo.packageName);
  var subPath =
      pathlib.join('Android', 'data', packageInfo.packageName, 'files');
  if (unfilteredPath.contains(subPath)) {
    var filteredPath = unfilteredPath.split(subPath).first;
    print('storage_helper->getExternalStorageWithoutDataDir: ' + filteredPath);
    return Directory(filteredPath);
  } else {
    return Directory(unfilteredPath);
  }
}
