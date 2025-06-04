import 'dart:typed_data';

// This file is used when running on the web platform
import 'dart:html' as html;

export 'dart:html';
export 'package:universal_html/html.dart';

// Define a File class that mimics the dart:io File class for web
class File {
  final String path;

  File(this.path);

  // Web implementation for readAsBytes
  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('Direct file reading not supported on web');
  }

  // Web implementation for writeAsBytes
  Future<void> writeAsBytes(List<int> bytes) async {
    throw UnsupportedError('Direct file writing not supported on web');
  }
}
