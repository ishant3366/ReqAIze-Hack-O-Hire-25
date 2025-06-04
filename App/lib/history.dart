import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // To check if running on Web
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart'; // To launch URLs

// --- Firebase Options (Replace with your actual config) ---
// It's generally recommended to use Firebase CLI for configuration files,
// but defining options directly is fine for web or specific cases.
const FirebaseOptions webFirebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyBo7wqKnzZdcNOTWJda2wThgbQlilJWl_w", // Replace if necessary
    authDomain: "reqaize-698c3.firebaseapp.com",
    projectId: "reqaize-698c3",
    storageBucket:
        "reqaize-698c3.appspot.com", // Ensure this matches your bucket name
    messagingSenderId: "1082633324628",
    appId: "1:1082633324628:web:11740576b9bafa7d9385c1",
    measurementId: "G-TG5LCDJB5L");
// --- End Firebase Options ---

// --- Main Application Entry Point ---
void main() async {
  // Ensure Flutter bindings are initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (kIsWeb) {
    // For web, initialize with specific options
    await Firebase.initializeApp(options: webFirebaseOptions);
  } else {
    // For mobile (Android/iOS), use default initialization
    // Assumes you have google-services.json / GoogleService-Info.plist setup
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}
// --- End Main Application Entry Point ---

// --- Root Application Widget ---
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase File Lister',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FileListScreen(), // Set the FileListScreen as the home screen
    );
  }
}
// --- End Root Application Widget ---

// --- Helper Class to Hold File Info ---
class StorageFileInfo {
  final Reference ref;
  final FullMetadata metadata;

  StorageFileInfo({required this.ref, required this.metadata});
}
// --- End Helper Class ---

// --- File List Screen Widget ---
class FileListScreen extends StatefulWidget {
  // *** IMPORTANT: Set your Firebase Storage directory path here ***
  // Use "" for the root directory or "foldername/" for a specific folder.
  final String storagePath = "excel_files/"; // <--- CHANGE THIS

  @override
  _FileListScreenState createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  late Future<List<StorageFileInfo>> _filesFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching files when the widget is first created
    _filesFuture = _fetchFilesAndMetadata();
  }

  // Fetches the list of files and their metadata
  Future<List<StorageFileInfo>> _fetchFilesAndMetadata() async {
    // Ensure the path ends with '/' if it's not empty, otherwise use root
    final String path =
        widget.storagePath.isEmpty || widget.storagePath.endsWith('/')
            ? widget.storagePath
            : '${widget.storagePath}/';
    final storageRef = FirebaseStorage.instance.ref().child(path);

    List<StorageFileInfo> fileInfos = [];

    try {
      final ListResult result = await storageRef.listAll();

      // Fetch metadata for each file item
      // Using Future.wait for potentially faster fetching (parallel requests)
      final metadataFutures = result.items
          .map((ref) => ref
                  .getMetadata()
                  .then((metadata) =>
                      StorageFileInfo(ref: ref, metadata: metadata))
                  .catchError((e) {
                // Handle error fetching metadata for a specific file
                print("Error getting metadata for ${ref.name}: $e");
                return null; // Return null or a default object if metadata fails
              }))
          .toList();

      final results = await Future.wait(metadataFutures);

      // Filter out any nulls that resulted from errors
      fileInfos = results.whereType<StorageFileInfo>().toList();

      // Sort files by creation time (newest first)
      fileInfos.sort((a, b) {
        final timeA =
            a.metadata.timeCreated ?? DateTime(0); // Handle null timeCreated
        final timeB = b.metadata.timeCreated ?? DateTime(0);
        return timeB.compareTo(timeA); // Newest first
      });

      return fileInfos;
    } on FirebaseException catch (e) {
      print("Error listing files in path '${widget.storagePath}': $e");
      // Handle errors, e.g., permissions, path not found
      // Rethrow or return empty list to show error in UI
      throw Exception(
          "Failed to load files: ${e.message}"); // Throw to be caught by FutureBuilder
    } catch (e) {
      print("An unexpected error occurred: $e");
      throw Exception("An unexpected error occurred while loading files.");
    }
  }

  // Attempts to open the file using its download URL
  Future<void> _openFile(BuildContext context, Reference fileRef) async {
    try {
      final String downloadUrl = await fileRef.getDownloadURL();
      final Uri url = Uri.parse(downloadUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode
              .externalApplication, // Try to open in a relevant app if possible
        );
      } else {
        print("Could not launch $url");
        _showErrorSnackbar(context,
            "Could not open file. No application found to handle this URL.");
      }
    } on FirebaseException catch (e) {
      print("Error getting download URL for ${fileRef.name}: $e");
      _showErrorSnackbar(context, "Error getting file URL: ${e.message}");
    } catch (e) {
      print("Error launching URL for ${fileRef.name}: $e");
      _showErrorSnackbar(
          context, "An error occurred while trying to open the file.");
    }
  }

  // Helper to show error messages
  void _showErrorSnackbar(BuildContext context, String message) {
    if (mounted) {
      // Check if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Files in /${widget.storagePath}"),
        actions: [
          // Optional: Add a refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _filesFuture = _fetchFilesAndMetadata(); // Re-fetch the files
              });
            },
            tooltip: "Refresh List",
          )
        ],
      ),
      body: FutureBuilder<List<StorageFileInfo>>(
        future: _filesFuture,
        builder: (context, snapshot) {
          // --- Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // --- Error State ---
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error loading files: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          // --- No Data State ---
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No files found in this directory."));
          }
          // --- Data Loaded State ---
          else {
            final files = snapshot.data!;
            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final fileInfo = files[index];
                final metadata = fileInfo.metadata;

                // Format the DateTime? to a readable string
                final formattedDate = metadata.timeCreated != null
                    ? DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(metadata.timeCreated!)
                    : 'Date unknown'; // Fallback for null date

                // Optional: Format file size
                String fileSize = 'Size unknown';
                if (metadata.size != null) {
                  if (metadata.size! < 1024) {
                    fileSize = "${metadata.size} B";
                  } else if (metadata.size! < 1024 * 1024) {
                    fileSize =
                        "${(metadata.size! / 1024).toStringAsFixed(1)} KB";
                  } else {
                    fileSize =
                        "${(metadata.size! / (1024 * 1024)).toStringAsFixed(1)} MB";
                  }
                }

                return ListTile(
                  leading: Icon(Icons.insert_drive_file_outlined), // File icon
                  title: Text(
                    metadata.name, // Display file name
                    overflow: TextOverflow
                        .ellipsis, // Prevent long names breaking layout
                  ),
                  subtitle: Text(
                      "Uploaded: $formattedDate | Size: $fileSize"), // Display formatted date/time and size
                  trailing: Icon(Icons.open_in_new,
                      color: Theme.of(context)
                          .colorScheme
                          .primary), // Icon indicating 'open' action
                  onTap: () {
                    // Handle opening the file when the tile is tapped
                    _openFile(context, fileInfo.ref);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
// --- End File List Screen Widget ---
