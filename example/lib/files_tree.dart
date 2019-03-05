import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_file_manager/flutter_file_manager.dart';
import 'package:path_provider/path_provider.dart';

class MyFiles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("External Storage: video files"),
        ),
        body: FutureBuilder(
            future: buildImages(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  primary: false,
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                        title: Container(
                            decoration: BoxDecoration(
                                border: Border(bottom: BorderSide())),
                            child: Text(snapshot.data[index])));
                  },
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Text("Loading");
              }
            }),
      ),
    );
  }
 // get all files that match these extensions
  Future buildImages() async {
    var root = await getExternalStorageDirectory();
    List<String> files = await FileManager(root: root)
        .filesTree(extensions: ["txt", "3gp", "zip", "png"]);
    return files;
  }
}
