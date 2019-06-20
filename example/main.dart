import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_manager/flutter_file_manager.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Flutter File Manager Example App"),
        ),
        body: FutureBuilder(
            future: buildImages(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return ListView.builder(
                  itemCount: snapshot?.data?.length ?? 0,
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

  Future buildImages() async {
    var root = await getExternalStorageDirectory();
    var files = await FileManager(root: root).walk();
    return files;
  }
}
