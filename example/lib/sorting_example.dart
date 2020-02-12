// framework
import 'package:flutter/material.dart';

// packages
import 'package:flutter_file_utils/flutter_file_utils.dart';
import 'package:path_provider/path_provider.dart';
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
            future: _files(), // a previously-obtained Future<String> or null
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return Text('Press button to start.');
                case ConnectionState.active:
                case ConnectionState.waiting:
                  return Text('Awaiting result...');
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
                                  Text('Path' +
                                      snapshot.data[index].path.toString()),
                                  Text('Date' +
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

  _files() async {
    var root = await getExternalStorageDirectory();
    var fm = FileManager(root: root);

    List founds = await fm.recentFilesAndDirs(20,
        sortedBy: FlutterFileUtilsSorting.Size, reversed: false);

    return founds;
  }
}
