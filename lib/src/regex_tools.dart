import 'dart:async';

class RegexTools {
  static bool checkExtension(String ext, String path) {
    /// return true if the path includes ext value
    RegExp exp = new RegExp(ext);
    Iterable<Match> matches = exp.allMatches(path);
    try {
      if (matches.first.group(0).length > 0) {
        return true;
      }
    } catch (e) {
      //print("# RegexTools->checkExtension: $e");
      return false;
    }
    return false;
  }

  static bool listInString(String string, List strings) {
    for (var s in strings) {
      if (string.contains(s)) return true;
    }
    return false;
  }

  static bool deeperPathCheckAll(String mainPath, List<String> deeperPath) {
    //print(mainPath);
    /*RegExp exp = RegExp(mainPath);

    for (var path in deeperPath) {
      try {
        if (exp.allMatches(path).first.group(0).length > 0) return true;
      } catch (e) {}
    }*/
    for (var path in deeperPath) {
      if (path.allMatches(mainPath).length > 0) return true;
    }
    return false;
  }

  static bool searchCheck(String searchIn, searchFor) {
      return searchIn.contains(RegExp(searchFor));
  }

  static bool deeperPathCheck(String mainPath, String deeperPath) {
    return deeperPath.contains(mainPath) ? true : false;
  }

  static String makeExtensionPattern(String name) {
    return "\.$name\$";
  }

  static Future<List<String>> makeExtensionPatternList(List<String> names) async{
    List<String> extensionsPatterns = [];
    for (var extension in names) {
      extensionsPatterns.add(RegexTools.makeExtensionPattern(extension));
    }
    return extensionsPatterns;
  }
}

main(List<String> args) {
  // print(RegexTools.listInString("android", [
  //   "\flutter_file_manager\android"
  // ]));
  // print(RegexTools.deeperPathCheckAll(Directory.current.path, [
  //   r"d:\Projects\Coding\Library\android\flutter\flutter_file_manager\android\app"
  // ]));
}


