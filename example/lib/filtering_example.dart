// dart files
import 'dart:async';
import 'dart:io';

// framework
import 'package:flutter/material.dart';

// packages
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_manager/flutter_file_manager.dart';
import 'package:simple_permissions/simple_permissions.dart';

void main() => runApp(new HomePage());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomePage();
  }
}

class HomePage extends StatefulWidget {
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    SimplePermissions.requestPermission(Permission.ReadExternalStorage);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Flutter File Manager Example"),
        ),
        body: FutureBuilder(
            future: getFilteredPaths().toList(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return ListView.builder(
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(snapshot.data[index].path.split('/').last),
                    );
                  },
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Text("Loading"));
              }
            }),
      ),
    );
  }

  Stream<FileSystemEntity> getFilteredPaths() async* {
    var root = await getExternalStorageDirectory();
    yield* FileManager(
            root: root,
            filter: SimpleFileFilter(
                allowedExtensions: ["png", 'apk'], hidden: false))
        .walk();
  }

  Future _search() async {
    var root = await getExternalStorageDirectory();
    var fm = FileManager(
      root: root,
    );

    List founds = await fm
        .search(
          // search keyword
          "android",
          searchFilter:
              SimpleFileFilter(allowedExtensions: ['png'], fileOnly: true),
          sortedBy: FileManagerSorting.Size,
        )
        .toList();

    return founds;
  }
}
