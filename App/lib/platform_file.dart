// File: platform_file.dart
// This file will be imported conditionally based on platform

// For non-web platforms (using dart:io)
import 'dart:typed_data';

// Export the actual File class from dart:io
export 'dart:io' show File;
