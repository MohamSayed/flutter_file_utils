// dart sdk
import 'dart:io';

// packages
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as pathlib;

/// Return all **paths**
Future<List<Directory>> getStorageList() async {
  List<Directory> paths = await getExternalStorageDirectories();
  List<Directory> filteredPaths = List<Directory>();
  for (Directory dir in paths) {
    filteredPaths
        .add(await getExternalStorageWithoutDataDir(dir.absolute.path));
  }
  return filteredPaths;
}

/// This function aims to get path like: `/storage/emulated/0/`
/// not like `/storage/emulated/0/Android/data/package.name.example/files`
Future<Directory> getExternalStorageWithoutDataDir(
    String unfilteredPath) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  print("storage_helper->getExternalStorageWithoutDataDir: " +
      packageInfo.packageName);
  String subPath =
      pathlib.join("Android", "data", packageInfo.packageName, "files");
  if (unfilteredPath.contains(subPath)) {
    String filteredPath = unfilteredPath.split(subPath).first;
    print("storage_helper->getExternalStorageWithoutDataDir: " + filteredPath);
    return Directory(filteredPath);
  } else {
    return Directory(unfilteredPath);
  }
}
