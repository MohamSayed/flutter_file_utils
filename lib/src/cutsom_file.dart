import 'dart:convert';
import 'dart:io';

main(List<String> args) {
  var cf = CustomFile("s.dart");
  cf.writeAsString("ss", mode: FileMode.writeOnly );
  print(cf.readAsBytesSync());
  
}

class CustomFile implements File {
  String _path;
  CustomFile(String path) {
    _path = path;
  }

  @override
  // TODO: implement absolute
  File get absolute => File(path);

  @override
  Future<File> copy(String newPath) {
    // TODO: implement copy
    return null;
  }

  @override
  File copySync(String newPath) {
    // TODO: implement copySync
    return null;
  }

  @override
  Future<File> create({bool recursive = false}) {
    // TODO: implement create
    return null;
  }

  @override
  void createSync({bool recursive = false}) {
    // TODO: implement createSync
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) {
    // TODO: implement delete
    return null;
  }

  @override
  void deleteSync({bool recursive = false}) {
    // TODO: implement deleteSync
  }

  @override
  Future<bool> exists() {
    // TODO: implement exists
    return null;
  }

  @override
  bool existsSync() {
    // TODO: implement existsSync
    return null;
  }

  @override
  // TODO: implement isAbsolute
  bool get isAbsolute => null;

  @override
  Future<DateTime> lastAccessed() {
    // TODO: implement lastAccessed
    return null;
  }

  @override
  DateTime lastAccessedSync() {
    // TODO: implement lastAccessedSync
    return null;
  }

  @override
  Future<DateTime> lastModified() {
    // TODO: implement lastModified
    return null;
  }

  @override
  DateTime lastModifiedSync() {
    // TODO: implement lastModifiedSync
    return null;
  }

  @override
  Future<int> length() {
    // TODO: implement length
    return null;
  }

  @override
  int lengthSync() {
    // TODO: implement lengthSync
    return null;
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) {
    // TODO: implement open
    return null;
  }

  @override
  Stream<List<int>> openRead([int start, int end]) {
    // TODO: implement openRead
    return null;
  }

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) {
    // TODO: implement openSync
    return null;
  }

  @override
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) {
    // TODO: implement openWrite
    return null;
  }

  @override
  // TODO: implement parent
  Directory get parent => null;

  @override
  // TODO: implement path
  String get path => _path;

  @override
  Future<List<int>> readAsBytes() {
    // TODO: implement readAsBytes
    return File(path).readAsBytes();
  }

  @override
  List<int> readAsBytesSync() {
    // TODO: implement readAsBytesSync
    return File(path).readAsBytesSync();
  }

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) {
    // TODO: implement readAsLines
    return File(path).readAsLines();
  }

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) {
    // TODO: implement readAsLinesSync
    return File(path).readAsLinesSync();
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    // TODO: implement readAsString
    return File(path).readAsString();
  }

  @override
  String readAsStringSync({Encoding encoding = utf8}) {
    // TODO: implement readAsStringSync
    return File(path).readAsStringSync();
  }

  @override
  Future<File> rename(String newPath) {
    // TODO: implement rename
    return File(path).rename(newPath);
  }

  @override
  File renameSync(String newPath) {
    // TODO: implement renameSync
    return File(path).renameSync(newPath);
  }

  @override
  Future<String> resolveSymbolicLinks() {
    // TODO: implement resolveSymbolicLinks
    return File(path).resolveSymbolicLinks();
  }

  @override
  String resolveSymbolicLinksSync() {
    return File(path).resolveSymbolicLinksSync();
  }

  @override
  Future setLastAccessed(DateTime time) {
    // TODO: implement setLastAccessed
    return File(path).setLastAccessed(time);
  }

  @override
  void setLastAccessedSync(DateTime time) {
    // TODO: implement setLastAccessedSync
    File(path).setLastAccessedSync(time);
  }

  @override
  Future setLastModified(DateTime time) {
    // TODO: implement setLastModified
    return File(path).setLastModified(time);
  }

  @override
  void setLastModifiedSync(DateTime time) {
    // TODO: implement setLastModifiedSync
    File(path).setLastModifiedSync(time);
  }

  @override
  Future<FileStat> stat() {
    // TODO: implement stat
    return stat();
  }

  @override
  FileStat statSync() {
    // TODO: implement statSync
    return statSync();
  }

  @override
  // TODO: implement uri
  Uri get uri => Uri(path: path);

  @override
  Stream<FileSystemEvent> watch(
      {int events = FileSystemEvent.all, bool recursive = false}) {
    // TODO: implement watch
    return watch(events: events, recursive: recursive);
  }

  @override
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) {
    // TODO: implement writeAsBytes
    return writeAsBytes(bytes);
  }

  @override
  void writeAsBytesSync(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) {
    // TODO: implement writeAsBytesSync
    writeAsBytesSync(bytes);

  }

  @override
  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false}) {
    // TODO: implement writeAsString
    return null;
  }

  @override
  void writeAsStringSync(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false}) {
    // TODO: implement writeAsStringSync
  }
}
