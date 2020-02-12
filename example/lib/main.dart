// framework
import 'dart:async';

import 'package:flutter/material.dart';

// packages
import 'package:flutter_file_utils/flutter_file_utils.dart';
import 'package:flutter_file_utils/utils.dart';

import 'package:path/path.dart' as p;

void main() => runApp(new MyApp());

@immutable
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text("Flutter File Manager Demo"),
          ),
          body: FutureBuilder(
            future: _search(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return Center(child: Text('Press button to start.'));
                case ConnectionState.active:
                  return Center(child: Text('Active'));
                case ConnectionState.waiting:
                  return Center(child: Text('Awaiting result...'));
                case ConnectionState.done:
                  if (snapshot.hasError)
                    return Text('Error: ${snapshot.error}');
                  return snapshot.data != null
                      ? ListView.builder(
                          itemCount: snapshot.data.length,
                          itemBuilder: (context, index) => Card(
                                  child: ListTile(
                                title: Column(children: [
                                  Text('Size: ' +
                                      snapshot.data[index]
                                          .statSync()
                                          .size
                                          .toString()),
                                  Text('Path: ' +
                                      snapshot.data[index].path.toString()),
                                  Text('Date: ' +
                                      snapshot.data[index]
                                          .statSync()
                                          .modified
                                          .toUtc()
                                          .toString())
                                ]),

                                subtitle: Text(
                                    "Extension: ${p.extension(snapshot.data[index].absolute.path).replaceFirst('.', '')}"), // getting extension
                              )))
                      : Center(
                          child: Text("Nothing!"),
                        );
              }
              return null; // unreachable
            },
          )),
    );
  }

  Future _search() async {
    var root = await getStorageList();
    var fm = FileManager(
      root: root[1],
    );

    List founds = await fm
        .search(
          // search keyword
          "android",
          sortedBy: FlutterFileUtilsSorting.Size,
        )
        .toList();
    return founds;
  }
}
