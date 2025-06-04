// Platform-independent stubs for File and Directory for web platform compatibility

class File {
  final String path;

  File(this.path);

  Future<File> writeAsBytes(List<int> bytes) async {
    return this;
  }

  Future<File> writeAsString(String contents) async {
    return this;
  }
}

class Directory {
  final String path;

  Directory(this.path);
}
