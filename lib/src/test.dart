import 'dart:io';

import 'package:path/path.dart' as p;

main(List<String> args) {
  //print(p.isWithin("/hello/world/","/hello/world/welcome/" ));
  //print(p.isAbsolute("/hello/world"));
  //print(p.join("/hello/world", "//hello\\world/welcome"));
  var ss = File("ss");
  print(ss.path); 
  //ss.writeAsStringSync("S");
  ///print(p.normalize("dataf/../data"));

}