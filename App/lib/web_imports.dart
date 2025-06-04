// This file is used when running on the web platform
import 'dart:html' as html;
import 'dart:typed_data'; // Added import for Uint8List

export 'dart:html';
export 'package:universal_html/html.dart';

// Define a File class that mimics the dart:io File class for web
class File {
  final String path;

  File(this.path);

  // This is a stub. In web, we'll use other methods to read files
  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('Direct file reading not supported on web');
  }

  Future<void> writeAsBytes(List<int> bytes) async {
    throw UnsupportedError('Direct file writing not supported on web');
  }
}
