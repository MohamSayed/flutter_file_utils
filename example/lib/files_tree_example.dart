import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_file_utils/flutter_file_utils.dart';
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
            future: _getSpecificFileTypes(),
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
                            child: Text(snapshot.data[index].path)));
                  },
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Text("Loading");
              }
              return Container();
            }),
      ),
    );
  }
 // get all files that match these extensions
  Future _getSpecificFileTypes() async {
    var root = await getExternalStorageDirectory();
    var files = await FileManager(root: root)
        .filesTree(extensions: ["txt", "3gp", "zip", "png"]);
    return files;
  }
}
