class FileManagerError extends Error {
  final String message;
  FileManagerError(this.message);

  @override
  String toString() {
    return message;
  }
}

class NotValidExtensionError extends Error {
  final String message;
  NotValidExtensionError(this.message);

  @override
  String toString() {
    return "Not valid extension: $message";
  }
}
