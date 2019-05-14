class TimeTools {
  static String timeNormalize(DateTime dateTime) {
    return dateTime.toUtc().toString().split(".")[0];
  }
}
