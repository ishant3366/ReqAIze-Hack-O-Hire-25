import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:excel/excel.dart'
    hide
        Border,
        Color; // Import Excel package, hide Color to avoid conflict with Material Color
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; // Import Syncfusion Charts
import 'package:file_picker/file_picker.dart'; // For picking Excel files (If needed, currently not used for import)
import 'package:firebase_core/firebase_core.dart'; // Firebase Core
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage

// Conditional import for web platform
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' if (dart.library.io) 'dart:io' as html;

// Initialize Firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Configure Firebase for your project (firebase_options.dart or manual)
  // See: https://firebase.flutter.dev/docs/overview#initialization
  // Make sure to add platform-specific configurations (android/ios/web setup).
  await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform, // Use if firebase_options.dart is configured
      );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Requirements Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueGrey, brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system, // Or ThemeMode.light / ThemeMode.dark
      home: RequirementsManager(
        // --- Sample Initial Data ---
        requirementsData: [
          {
            'reqId': 'F-001',
            'priority': 'M',
            'type': 'Functional',
            'requirement': 'User login with email and password.',
            'notes': 'Standard authentication.',
            'status': 'Updated'
          },
          {
            'reqId': 'F-002',
            'priority': 'S',
            'type': 'Functional',
            'requirement': 'Password reset functionality via email.',
            'notes': 'Requires email service integration.',
            'status': 'Pending'
          },
          {
            'reqId': 'NF-001',
            'priority': 'M',
            'type': 'Non-Functional',
            'requirement':
                'System must respond to login requests within 2 seconds.',
            'notes': 'Performance requirement.',
            'status': 'Updated'
          },
          {
            'reqId': 'F-003',
            'priority': 'C',
            'type': 'Functional',
            'requirement': 'Display user dashboard after login.',
            'notes': '',
            'status': 'New'
          },
          {
            'reqId': 'NF-002',
            'priority': 'W',
            'type': 'Non-Functional',
            'requirement': 'Support dark mode theme.',
            'notes': 'Visual enhancement.',
            'status': 'Pending'
          },
          {
            'reqId': 'F-004',
            'priority': 'S',
            'type': 'Functional',
            'requirement': 'Allow users to update their profile information.',
            'notes': 'Includes name, email (read-only).',
            'status': 'Updated'
          },
        ],
      ),
    );
  }
}

class RequirementsManager extends StatefulWidget {
  final List<Map<String, dynamic>> requirementsData;

  const RequirementsManager({super.key, required this.requirementsData});

  @override
  _RequirementsManagerState createState() => _RequirementsManagerState();
}

class _RequirementsManagerState extends State<RequirementsManager> {
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _columns = [];
  bool _isExporting = false;
  bool _isUploading = false;
  bool _isGeneratingBRD = false; // Renamed from _isGeneratingPRD
  bool _isSaved = true;

  // Firebase storage reference
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _initializeTableData();
  }

  void _initializeTableData() {
    // Define table columns including 'priority'
    _columns = [
      {
        "title": 'Req ID',
        'widthFactor': 0.10,
        'key': 'reqId',
        'editable': false
      },
      {
        "title": 'Priority',
        'widthFactor': 0.10,
        'key': 'priority',
      },
      {
        "title": 'Type',
        'widthFactor': 0.14,
        'key': 'type',
      },
      {"title": 'Requirement', 'widthFactor': 0.36, 'key': 'requirement'},
      {"title": 'Notes', 'widthFactor': 0.18, 'key': 'notes'},
      {
        "title": 'Status',
        'widthFactor': 0.12,
        'key': 'status',
      },
    ];

    // Create a deep copy to allow editing without modifying original widget data
    _rows = List<Map<String, dynamic>>.from(
        widget.requirementsData.map((row) => Map<String, dynamic>.from(row)));

    // Ensure all expected keys exist in each row, setting defaults if needed
    for (var row in _rows) {
      for (var col in _columns) {
        row.putIfAbsent(col['key'], () => null);
      }
      // Ensure priority has a default and is uppercase if present
      var priority = row['priority']?.toString().toUpperCase();
      if (priority == null || !['M', 'S', 'C', 'W'].contains(priority)) {
        row['priority'] = 'C'; // Default if invalid or null
      } else {
        row['priority'] = priority; // Ensure uppercase
      }
    }
  }

  // Called when any cell edit is submitted
  void _notifyChange() {
    if (_isSaved && mounted) {
      setState(() {
        _isSaved = false;
      });
    }
  }

  // Saves the current state of the editable table to the _rows list
  void _saveChanges() {
    if (mounted) {
      setState(() {
        _isSaved = true;
      });
      _showSnackBar('Changes saved locally. Ready to export or view analytics.',
          isError: false);
    }
  }

  // Exports the current _rows data to an Excel file
  Future<void> _exportToExcel() async {
    if (!_isSaved) {
      _showUnsavedChangesDialog();
      return;
    }
    if (_rows.isEmpty) {
      _showSnackBar('No requirements data to export.',
          isError: false, isWarning: true);
      return;
    }
    if (mounted) setState(() => _isExporting = true);

    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Requirements'];

      // --- Styling ---
      var headerStyle = CellStyle(
          bold: true,
          fontSize: 11,
          backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
          verticalAlign: VerticalAlign.Center,
          horizontalAlign: HorizontalAlign.Center);
      var dataCellStyle = CellStyle(
          verticalAlign: VerticalAlign.Top,
          textWrapping: TextWrapping.WrapText);

      // --- Headers ---
      List<String> headerTitles =
          _columns.map((col) => col['title'].toString()).toList();
      sheet.appendRow(
          headerTitles.map((title) => TextCellValue(title)).toList());
      for (var i = 0; i < headerTitles.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      // --- Column Widths ---
      try {
        sheet.setColumnWidth(0, 12); // Req ID
        sheet.setColumnWidth(1, 10); // Priority
        sheet.setColumnWidth(2, 18); // Type
        sheet.setColumnWidth(3, 55); // Requirement
        sheet.setColumnWidth(4, 35); // Notes
        sheet.setColumnWidth(5, 18); // Status
      } catch (e) {
        print("Note: Could not set column widths. $e");
      }

      // --- Data Rows ---
      int rowIndex = 1;
      for (var row in _rows) {
        List<CellValue> rowData = _columns.map((col) {
          String key = col['key'];
          dynamic value = row[key];
          return TextCellValue(value?.toString() ?? ''); // Handle nulls
        }).toList();
        sheet.appendRow(rowData);
        for (var i = 0; i < rowData.length; i++) {
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: i, rowIndex: rowIndex))
              .cellStyle = dataCellStyle;
        }
        rowIndex++;
      }

      // --- Save/Share Logic ---
      final List<int>? bytes = excel.save(fileName: 'requirements.xlsx');
      if (bytes == null) throw Exception("Failed to generate Excel byte data.");
      const String excelFileName = 'requirements.xlsx';

      if (kIsWeb) {
        // Web download
        final blob = html.Blob(
            [Uint8List.fromList(bytes)],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'native');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', excelFileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar('Export successful! Check downloads.', isError: false);
      } else {
        // Mobile/Desktop share
        try {
          final directory = await getTemporaryDirectory();
          final path = '${directory.path}/$excelFileName';
          final file = io.File(path);
          await file.writeAsBytes(bytes, flush: true);

          final result = await Share.shareXFiles([XFile(path)],
              text: 'Here is the requirements Excel file.');
          if (result.status == ShareResultStatus.success) {
            _showSnackBar('File shared successfully!', isError: false);
          } else {
            _showSnackBar(
                'File saved locally in temp files. Sharing was ${result.status.name}.',
                isError: false);
          }
        } catch (e, stack) {
          print("Error saving/sharing file: $e\n$stack");
          throw Exception('Error saving/sharing file on device: $e');
        }
      }
    } catch (e, stacktrace) {
      print("Excel Export Error: $e\n$stacktrace");
      _showSnackBar('Error exporting Excel file: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // Upload Excel file to Firebase Storage
  Future<void> _uploadToFirebase() async {
    if (!_isSaved) {
      _showUnsavedChangesDialog(uploadToFirebaseAfterSave: true);
      return;
    }

    if (_rows.isEmpty) {
      _showSnackBar('No requirements data to upload.',
          isError: false, isWarning: true);
      return;
    }

    if (mounted) setState(() => _isUploading = true);

    try {
      // Generate the Excel file
      var excel = Excel.createExcel();
      Sheet sheet = excel['Requirements'];

      // --- Headers ---
      List<String> headerTitles =
          _columns.map((col) => col['title'].toString()).toList();
      sheet.appendRow(
          headerTitles.map((title) => TextCellValue(title)).toList());

      // --- Data Rows ---
      for (var row in _rows) {
        List<CellValue> rowData = _columns.map((col) {
          String key = col['key'];
          dynamic value = row[key];
          return TextCellValue(value?.toString() ?? '');
        }).toList();
        sheet.appendRow(rowData);
      }

      // Save Excel to bytes
      final List<int>? bytes = excel.save(fileName: 'requirements.xlsx');
      if (bytes == null) throw Exception("Failed to generate Excel byte data.");

      // Generate a timestamp for unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'requirements_$timestamp.xlsx';

      if (kIsWeb) {
        // Handle web upload
        final data = Uint8List.fromList(bytes);

        // Create storage reference
        final ref = _storage.ref().child('excel_files/$fileName');

        // Upload the file
        final uploadTask = ref.putData(
            data,
            SettableMetadata(
                contentType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'));

        // Wait for the upload to complete
        await uploadTask.whenComplete(() {});

        // Get the download URL (optional)
        // final downloadUrl = await ref.getDownloadURL();

        _showSnackBar('Excel file uploaded to Firebase!', isError: false);
      } else {
        // Handle mobile/desktop upload
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/requirements.xlsx';
        final file = io.File(path);
        await file.writeAsBytes(bytes, flush: true);

        // Create storage reference
        final ref = _storage.ref().child('excel_files/$fileName');

        // Upload the file
        final uploadTask = ref.putFile(file);

        // Wait for the upload to complete
        await uploadTask.whenComplete(() {});

        // Get the download URL (optional)
        final downloadUrl = await ref.getDownloadURL();
        print('Download URL: $downloadUrl');

        _showSnackBar('Excel file uploaded to Firebase!', isError: false);
      }
    } catch (e, stacktrace) {
      print("Firebase Upload Error: $e\n$stacktrace");
      _showSnackBar('Error uploading to Firebase: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Import Excel from Firebase Storage
  Future<void> _importFromFirebase() async {
    if (!_isSaved) {
      _showSnackBar('Please save changes before importing.',
          isError: false, isWarning: true);
      return;
    }

    try {
      // List all files in the 'excel_files' directory
      final ListResult result =
          await _storage.ref().child('excel_files').listAll();

      if (result.items.isEmpty) {
        _showSnackBar('No Excel files found in Firebase Storage.',
            isError: false, isWarning: true);
        return;
      }

      // Show dialog to select a file
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Excel File to Import'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: result.items.length,
              itemBuilder: (context, index) {
                final Reference ref = result.items[index];
                return ListTile(
                  title: Text(ref.name),
                  onTap: () async {
                    Navigator.pop(context);
                    await _downloadAndProcessExcel(ref);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Error listing Firebase files: $e', isError: true);
    }
  }

  // Helper for downloading and processing Excel from Firebase
  Future<void> _downloadAndProcessExcel(Reference ref) async {
    try {
      if (mounted)
        setState(
            () => _isUploading = true); // Use uploading state for simplicity

      // Download the file
      Uint8List? data;
      io.File? tempFile;

      if (kIsWeb) {
        // Web download
        data = await ref.getData();
      } else {
        // Mobile/desktop download
        final directory = await getTemporaryDirectory();
        tempFile = io.File('${directory.path}/${ref.name}');
        await ref.writeToFile(tempFile);
        data = await tempFile.readAsBytes();
      }

      // Parse Excel data - FIX: Ensure data is not null before using it
      if (data == null) {
        throw Exception("Failed to download file data");
      }

      final excel = Excel.decodeBytes(data);

      if (!excel.tables.containsKey('Requirements')) {
        throw Exception("Excel file doesn't contain a 'Requirements' sheet");
      }

      Sheet sheet = excel['Requirements'];

      // Extract headers to map columns
      List<String> headers = [];
      for (var cell in sheet.row(0)) {
        headers.add(cell?.value.toString() ?? '');
      }

      // Map column indices based on titles defined in _columns
      Map<String, int> columnMap = {};
      for (int i = 0; i < headers.length; i++) {
        for (var col in _columns) {
          if (col['title'] == headers[i]) {
            columnMap[col['key']] = i;
            break; // Found match, move to next header
          }
        }
      }

      // Validate that all required columns are present in the Excel file
      for (var col in _columns) {
        if (!columnMap.containsKey(col['key'])) {
          throw Exception(
              "Missing required column header in Excel: '${col['title']}'");
        }
      }

      // Process data rows
      List<Map<String, dynamic>> importedRows = [];
      for (int r = 1; r < sheet.maxRows; r++) {
        var row = sheet.row(r);
        // Skip empty rows (where all cells are null or empty)
        if (row.isEmpty ||
            row.every((cell) =>
                cell?.value == null || cell?.value.toString().trim() == ''))
          continue;

        Map<String, dynamic> rowData = {};
        for (var col in _columns) {
          String key = col['key'];
          int? colIndex = columnMap[key];
          if (colIndex != null && colIndex < row.length) {
            rowData[key] = row[colIndex]?.value?.toString() ?? '';
          } else {
            rowData[key] =
                ''; // Assign empty string if column is missing in the row
          }
        }

        // Validate and normalize priority after loading
        var priority = rowData['priority']?.toString().toUpperCase();
        if (priority == null || !['M', 'S', 'C', 'W'].contains(priority)) {
          rowData['priority'] = 'C'; // Default if invalid or null
        } else {
          rowData['priority'] = priority; // Ensure uppercase
        }

        importedRows.add(rowData);
      }

      if (importedRows.isEmpty && sheet.maxRows > 1) {
        _showSnackBar(
            "No valid data rows found after header in the Excel file.",
            isError: false,
            isWarning: true);
        // Don't throw an exception, just inform the user. Allow empty import if the file structure is correct but has no data.
      }

      // Update state with imported data
      if (mounted) {
        setState(() {
          _rows = importedRows;
          _isSaved = true; // Mark as saved since we just imported
        });
        _showSnackBar('Successfully imported data from Firebase',
            isError: false);
      }
    } catch (e) {
      _showSnackBar('Error importing Excel: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Adds a new empty requirement row to the table
  void _addNewRequirement() {
    if (!mounted) return;

    // Generate a new unique 'F-' ID
    int highestF = 0;
    for (var row in _rows) {
      String? reqId = row['reqId']?.toString();
      if (reqId != null && reqId.startsWith('F-')) {
        int num = int.tryParse(reqId.substring(2)) ?? 0;
        if (num > highestF) highestF = num;
      }
    }
    String newId = 'F-${(highestF + 1).toString().padLeft(3, '0')}';

    // Create new row with default values
    Map<String, dynamic> newRow = {
      for (var col in _columns) col['key']: null // Initialize all keys
    };
    newRow.addAll({
      'reqId': newId,
      'priority': 'C', // Default Priority
      'type': 'Functional', // Default Type
      'requirement': 'Enter new requirement details...',
      'notes': '',
      'status': 'New', // Default Status
    });

    setState(() {
      _rows.add(newRow);
      _isSaved = false; // Mark as unsaved
    });

    // Show edit dialog for the new row
    _editRow(newRow);
  }

  // Edit an existing row - Using Chips and Radio buttons
  void _editRow(Map<String, dynamic> row) {
    // Create a copy of the row for editing
    Map<String, dynamic> editedRow = Map<String, dynamic>.from(row);

    // Controllers for text fields
    TextEditingController requirementController =
        TextEditingController(text: editedRow['requirement'] ?? '');
    TextEditingController notesController =
        TextEditingController(text: editedRow['notes'] ?? '');

    // State variables for the dialog's selections
    String selectedPriority = editedRow['priority'] ?? 'C';
    String selectedType = editedRow['type'] ?? 'Functional';
    String selectedStatus = editedRow['status'] ?? 'New';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Text('Edit Requirement ${editedRow['reqId']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority selection with FilterChips
                const Text('Priority:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildPriorityChip('M', 'Must Have', selectedPriority,
                        (val) {
                      setDialogState(() => selectedPriority = val);
                    }),
                    _buildPriorityChip('S', 'Should Have', selectedPriority,
                        (val) {
                      setDialogState(() => selectedPriority = val);
                    }),
                    _buildPriorityChip('C', 'Could Have', selectedPriority,
                        (val) {
                      setDialogState(() => selectedPriority = val);
                    }),
                    _buildPriorityChip('W', 'Won\'t Have', selectedPriority,
                        (val) {
                      setDialogState(() => selectedPriority = val);
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Type selection with RadioListTiles
                const Text('Type:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Functional'),
                        value: 'Functional',
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedType = value);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Non-Functional'),
                        value: 'Non-Functional',
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedType = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Requirement text field
                const Text('Requirement:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: requirementController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter requirement details',
                  ),
                ),
                const SizedBox(height: 16),

                // Notes text field
                const Text('Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Optional notes',
                  ),
                ),
                const SizedBox(height: 16),

                // Status selection with FilterChips
                const Text('Status:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildStatusChip('New', selectedStatus, (val) {
                      setDialogState(() => selectedStatus = val);
                    }),
                    _buildStatusChip('Updated', selectedStatus, (val) {
                      setDialogState(() => selectedStatus = val);
                    }),
                    _buildStatusChip('Pending', selectedStatus, (val) {
                      setDialogState(() => selectedStatus = val);
                    }),
                    _buildStatusChip('Completed', selectedStatus, (val) {
                      setDialogState(() => selectedStatus = val);
                    }),
                    _buildStatusChip('Rejected', selectedStatus, (val) {
                      setDialogState(() => selectedStatus = val);
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update the editedRow map with the final values
                editedRow['requirement'] = requirementController.text;
                editedRow['notes'] = notesController.text;
                editedRow['priority'] = selectedPriority;
                editedRow['type'] = selectedType;
                editedRow['status'] = selectedStatus;

                // Find the index of the original row in the main _rows list
                int index =
                    _rows.indexWhere((r) => r['reqId'] == editedRow['reqId']);
                if (index != -1) {
                  // Update the row in the main state
                  setState(() {
                    _rows[index] = editedRow;
                    _isSaved = false; // Mark changes as unsaved
                  });
                }
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }

  // Helper widget for priority selection FilterChip
  Widget _buildPriorityChip(String value, String label, String selectedValue,
      Function(String) onSelected) {
    final bool isSelected = selectedValue == value;
    final Color chipColor = _getPriorityColor(value); // Get color from helper

    return FilterChip(
      label: Text('$value - $label'),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      backgroundColor: chipColor.withOpacity(0.2),
      selectedColor: chipColor.withOpacity(0.7),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white, // Ensure checkmark is visible
      showCheckmark: true,
    );
  }

  // Helper widget for status selection FilterChip
  Widget _buildStatusChip(
      String value, String selectedValue, Function(String) onSelected) {
    final bool isSelected = selectedValue == value;

    Color chipColor; // Define color based on status
    switch (value) {
      case 'New':
        chipColor = Colors.green;
        break;
      case 'Updated':
        chipColor = Colors.blue;
        break;
      case 'Pending':
        chipColor = Colors.orange;
        break;
      case 'Completed':
        chipColor = Colors.teal;
        break;
      case 'Rejected':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.blueGrey;
    }

    return FilterChip(
      label: Text(value),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      backgroundColor: chipColor.withOpacity(0.2),
      selectedColor: chipColor.withOpacity(0.7),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white, // Ensure checkmark is visible
      showCheckmark: true,
    );
  }

  // Delete a row
  void _deleteRow(Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete requirement ${row['reqId']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _rows.removeWhere((r) => r['reqId'] == row['reqId']);
                _isSaved = false; // Mark as unsaved
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Generate BRD Word document including RAID Analysis
  Future<void> _generateBRDDocument() async {
    if (!_isSaved) {
      _showUnsavedChangesDialog(generateBRDAfterSave: true); // Use new flag
      return;
    }

    if (_rows.isEmpty) {
      _showSnackBar('No requirements data to generate BRD.',
          isError: false, isWarning: true);
      return;
    }

    if (mounted) setState(() => _isGeneratingBRD = true);

    try {
      // --- Placeholder: Actual DOCX Document Creation ---
      // In a real implementation, you would initialize your chosen DOCX library here.
      // e.g., using 'docx_template' or a cloud service like Aspose.Words Cloud [4].
      // Example using a hypothetical library:
      // var docx = DocxGenerator();
      // docx.addHeading1('Business Requirements Document');

      // --- Use StringBuffer to build the text content structure ---
      // This will be saved as a .docx file, but its content will be plain text
      // until a proper DOCX library is integrated.
      StringBuffer docContent = StringBuffer();

      // --- BRD Sections ---
      docContent.writeln('Business Requirements Document');
      docContent.writeln('=' * 30); // Separator

      // 1. Executive Summary
      docContent.writeln('\n## 1. Executive Summary');
      docContent.writeln(
          'This document outlines the business requirements and objectives for the project. It details the functional needs, constraints, stakeholders, and expected outcomes. This summary provides a high-level overview.');
      docContent.writeln(
          '(Write this section last, summarizing the key points below)');

      // 2. Objectives
      docContent.writeln('\n## 2. Project Objectives');
      docContent.writeln('The primary objectives of this project are:');
      docContent.writeln(
          '- Objective 1: [Specify measurable goal, e.g., Increase user engagement by 15%]');
      docContent.writeln(
          '- Objective 2: [Specify measurable goal, e.g., Reduce processing time by 20%]');
      docContent.writeln(
          '- Objective 3: [Specify measurable goal, e.g., Launch the new feature by Q3]');
      docContent.writeln(
          '(Ensure objectives are SMART: Specific, Measurable, Achievable, Relevant, Time-bound)');

      // 3. Stakeholders
      docContent.writeln('\n## 3. Key Stakeholders');
      docContent
          .writeln('- Stakeholder 1: [Name/Role - e.g., Project Sponsor]');
      docContent
          .writeln('- Stakeholder 2: [Name/Role - e.g., Product Manager]');
      docContent.writeln('- Stakeholder 3: [Name/Role - e.g., Lead Developer]');
      docContent.writeln('- Stakeholder 4: [Name/Role - e.g., End User Group]');

      // 4. Functional Requirements (Extracted from _rows)
      docContent.writeln('\n## 4. Functional Requirements');
      List<Map<String, dynamic>> functionalReqs =
          _rows.where((row) => row['type'] == 'Functional').toList();
      if (functionalReqs.isEmpty) {
        docContent.writeln('No functional requirements defined.');
      } else {
        functionalReqs.sort((a, b) =>
            (a['reqId'] ?? '').compareTo(b['reqId'] ?? '')); // Sort by ID
        for (var req in functionalReqs) {
          docContent.writeln('\n### ${req['reqId'] ?? 'N/A'}');
          docContent
              .writeln('- **Requirement:** ${req['requirement'] ?? 'N/A'}');
          docContent.writeln(
              '- **Priority:** ${_getMoscowLabel(req['priority'])} (${req['priority'] ?? 'N/A'})');
          docContent.writeln('- **Status:** ${req['status'] ?? 'N/A'}');
          if (req['notes'] != null && req['notes'].toString().isNotEmpty) {
            docContent.writeln('- **Notes:** ${req['notes']}');
          }
        }
      }
      // TODO: Optionally add Non-Functional Requirements similarly if needed

      // 5. Constraints
      docContent.writeln('\n## 5. Project Constraints');
      docContent.writeln('- Budget: [Specify budget limitations]');
      docContent.writeln(
          '- Timeline: [Specify overall deadline or key phase deadlines]');
      docContent.writeln(
          '- Resources: [Specify limitations on personnel, equipment, etc.]');
      docContent.writeln(
          '- Technology: [Specify required tech stack or limitations]');

      // 6. Timeline and Deadlines
      docContent.writeln('\n## 6. Timeline and Deadlines');
      docContent.writeln('- Phase 1 (Discovery): [Start Date] - [End Date]');
      docContent.writeln('- Phase 2 (Development): [Start Date] - [End Date]');
      docContent.writeln('- Phase 3 (Testing): [Start Date] - [End Date]');
      docContent.writeln('- Phase 4 (Deployment): [Start Date] - [End Date]');
      docContent.writeln('- Key Milestone 1: [Description] - [Due Date]');
      docContent.writeln('- Key Milestone 2: [Description] - [Due Date]');

      // 7. Budget
      docContent.writeln('\n## 7. Budget / Cost-Benefit Analysis');
      docContent
          .writeln('Estimated Project Cost: [Specify total or breakdown]');
      docContent.writeln(
          'Expected Benefits: [Describe qualitative and quantitative benefits]');
      docContent.writeln(
          'Return on Investment (ROI) Estimate: [Provide calculation or summary]');

      // 8. Project Phases (May overlap with Timeline)
      docContent.writeln('\n## 8. Project Phases');
      docContent.writeln('- Detailed description of Phase 1...');
      docContent.writeln('- Detailed description of Phase 2...');
      // ... add more phases as needed

      docContent.writeln('\n' + '=' * 30 + '\n'); // Separator

      // --- RAID Analysis Section ---
      docContent.writeln('RAID Analysis');
      docContent.writeln('=' * 30);

      // Risks
      docContent.writeln('\n## Risks');
      docContent.writeln(
          '(Potential events that could negatively impact the project)');
      docContent.writeln(
          '- Risk 1: [Description, e.g., Key personnel unavailability]');
      docContent.writeln(
          '- Risk 2: [Description, e.g., Third-party integration delays]');
      docContent.writeln('- Risk 3: [Description, e.g., Scope creep]');

      // Assumptions
      docContent.writeln('\n## Assumptions');
      docContent.writeln(
          '(Factors believed to be true for the project plan to hold)');
      docContent.writeln(
          '- Assumption 1: [Description, e.g., Stable requirements during development phase]');
      docContent.writeln(
          '- Assumption 2: [Description, e.g., Required hardware available on schedule]');
      docContent.writeln(
          '- Assumption 3: [Description, e.g., Timely stakeholder feedback]');

      // Issues
      docContent.writeln('\n## Issues');
      docContent
          .writeln('(Current problems or challenges impacting the project)');
      docContent.writeln(
          '- Issue 1: [Description, e.g., Unresolved requirement F-005]');
      docContent.writeln(
          '- Issue 2: [Description, e.g., Performance bottleneck identified in module X]');

      // Dependencies
      docContent.writeln('\n## Dependencies');
      docContent.writeln(
          '(Tasks/items the project relies on, or that rely on the project)');
      docContent.writeln(
          '- Dependency 1: [Description, e.g., Completion of API documentation by Team B]');
      docContent.writeln(
          '- Dependency 2: [Description, e.g., User training materials dependent on final UI]');
      docContent.writeln(
          '- Dependency 3: [Description, e.g., Project C requires output from this project]');

      // --- Placeholder: Generate Actual DOCX Bytes ---
      // Here you would use your chosen library (e.g., docx_template, Aspose.Words Cloud SDK [4])
      // to convert the structured `docContent` (or build the document programmatically)
      // into actual DOCX format bytes.
      // final List<int>? bytes = await generateActualDocxBytes(docContent.toString()); // Replace with real implementation

      // --- For Demonstration: Save the StringBuffer content as a "fake" .docx file ---
      final String textContentForDemo = docContent.toString();
      // Convert the text string to bytes (UTF-8 encoding)
      final List<int> bytes = textContentForDemo.codeUnits;
      const String docxFileName =
          'BRD_RAID_Document.docx'; // Use .docx extension for the output file name

      if (bytes.isEmpty) throw Exception("Failed to generate document data.");

      // --- Save/Share Logic (Adapted from _exportToExcel) ---
      if (kIsWeb) {
        // Web download
        final blob = html.Blob(
            [Uint8List.fromList(bytes)],
            // Use the correct MIME type for DOCX even though the content is text for now
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'native');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', docxFileName) // Use .docx name
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar('BRD & RAID document generated! Check downloads.',
            isError: false);
      } else {
        // Mobile/Desktop share
        try {
          final directory = await getTemporaryDirectory();
          final path = '${directory.path}/$docxFileName'; // Use .docx name
          final file = io.File(path);
          await file.writeAsBytes(bytes, flush: true);

          final result = await Share.shareXFiles([XFile(path)],
              text:
                  'Here is the Business Requirements Document with RAID analysis.');
          if (result.status == ShareResultStatus.success) {
            _showSnackBar('BRD & RAID document shared successfully!',
                isError: false);
          } else {
            _showSnackBar(
                'BRD document saved locally. Sharing was ${result.status.name}.',
                isError: false);
          }
        } catch (e, stack) {
          print("Error saving/sharing BRD: $e\n$stack");
          throw Exception('Error saving/sharing BRD on device: $e');
        }
      }
    } catch (e, stacktrace) {
      print("BRD Generation Error: $e\n$stacktrace");
      _showSnackBar('Error generating BRD document: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingBRD = false);
    }
  }

  // Shows the analytics screen
  void _navigateToAnalytics() {
    if (!_isSaved) {
      _showUnsavedChangesDialog(navigateToAnalyticsAfterSave: true);
      return;
    }
    if (_rows.isEmpty) {
      _showSnackBar('No data available to analyze.',
          isError: false, isWarning: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsScreen(
            requirementsData:
                List<Map<String, dynamic>>.from(_rows)), // Pass a copy
      ),
    );
  }

  // Helper for showing SnackBars
  void _showSnackBar(String message,
      {required bool isError, bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
      backgroundColor: isError
          ? Colors.redAccent
          : (isWarning ? Colors.orangeAccent : Colors.green),
    ));
  }

  // Dialog for unsaved changes confirmation
  void _showUnsavedChangesDialog({
    bool navigateToAnalyticsAfterSave = false,
    bool uploadToFirebaseAfterSave = false,
    bool generateBRDAfterSave = false, // Updated parameter name
  }) {
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                  'You have unsaved changes. Please save them first.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _saveChanges();
                      // Optionally navigate, upload or generate BRD after saving
                      if (navigateToAnalyticsAfterSave && _isSaved) {
                        _navigateToAnalytics();
                      }
                      if (uploadToFirebaseAfterSave && _isSaved) {
                        _uploadToFirebase();
                      }
                      if (generateBRDAfterSave && _isSaved) {
                        // Updated condition
                        _generateBRDDocument();
                      }
                    },
                    child: const Text('Save Changes')),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    // Updated condition to include BRD generation state
    final bool canExportOrAnalyze =
        _isSaved && !_isExporting && !_isUploading && !_isGeneratingBRD;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requirements Manager'),
        actions: [
          // --- Three dots menu (Upload/Import only) ---
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Actions',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'upload',
                child: ListTile(
                  leading: Icon(Icons.cloud_upload),
                  title: Text('Upload to Firebase'),
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.cloud_download),
                  title: Text('Import from Firebase'),
                ),
              ),
              // PRD option removed
            ],
            onSelected: (value) {
              if (value == 'upload') {
                _uploadToFirebase();
              } else if (value == 'import') {
                _importFromFirebase();
              }
            },
          ),

          // --- Analytics Button ---
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View Analytics',
            onPressed: canExportOrAnalyze ? _navigateToAnalytics : null,
          ),

          // --- BRD/RAID Export Button ---
          IconButton(
            icon: const Icon(Icons.description_outlined), // Or Icons.article
            tooltip: 'Export BRD & RAID (.docx)',
            onPressed: canExportOrAnalyze ? _generateBRDDocument : null,
          ),

          // --- Add New Requirement Button ---
          IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add New Requirement Row',
              onPressed: _addNewRequirement),

          // --- Save Button ---
          IconButton(
            icon: Icon(_isSaved ? Icons.check_circle : Icons.save_outlined,
                color: _isSaved
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary),
            tooltip: _isSaved ? 'Changes Saved' : 'Save Changes Locally',
            // Updated condition to include BRD generation state
            onPressed:
                (_isSaved || _isExporting || _isUploading || _isGeneratingBRD)
                    ? null
                    : _saveChanges,
          ),

          // --- Progress Indicator / Export Excel Button ---
          // Updated condition to show progress for BRD generation as well
          _isExporting || _isUploading || _isGeneratingBRD
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download_outlined), // Excel Icon
                  tooltip: 'Export to Excel (.xlsx)',
                  onPressed: canExportOrAnalyze ? _exportToExcel : null,
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        _isSaved
                            ? 'Changes saved. Ready to export or upload.'
                            : 'Save changes before exporting or uploading.',
                        style: const TextStyle(fontSize: 14))),
                if (!_isSaved)
                  const Tooltip(
                    message: 'Unsaved changes',
                    child: Icon(Icons.warning_amber_rounded,
                        color: Colors.orangeAccent, size: 20),
                  )
              ],
            ),
          ),

          // Mobile-friendly ListView for requirements
          Expanded(
            child: _rows.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.table_rows_outlined,
                            size: 40, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No requirements loaded.',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Requirement'),
                          onPressed: _addNewRequirement,
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(row['priority']),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  row['reqId'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  row['requirement'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Text('${row['type'] ?? 'Unknown'} • '),
                              Text('Priority: ${row['priority'] ?? 'C'} • '),
                              Text('Status: ${row['status'] ?? 'New'}'),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Requirement:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall),
                                  Text(row['requirement'] ?? ''),
                                  const SizedBox(height: 8),
                                  if (row['notes'] != null &&
                                      row['notes'].toString().isNotEmpty) ...[
                                    Text('Notes:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall),
                                    Text(row['notes']),
                                    const SizedBox(height: 8),
                                  ],
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit'),
                                        onPressed: () => _editRow(row),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        label: const Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onPressed: () => _deleteRow(row),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // Bottom app bar with Upload button only
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                // Upload button takes full width now
                child: ElevatedButton.icon(
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                      _isUploading ? 'Uploading...' : 'Upload to Firebase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  // Disable if uploading OR if changes are unsaved
                  onPressed:
                      (_isUploading || !_isSaved) ? null : _uploadToFirebase,
                ),
              ),
              // PRD button was removed here previously, keep it removed.
            ],
          ),
        ),
      ),
      // FAB for adding new requirements
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRequirement,
        tooltip: 'Add New Requirement',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Helper to get color based on priority
  Color _getPriorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'M':
        return Colors.red;
      case 'S':
        return Colors.orange;
      case 'C':
        return Colors.blue;
      case 'W':
        return Colors.grey;
      default:
        return Colors.blueGrey; // Default color for null or unknown
    }
  }

  // Helper to get full MoSCoW label (needed for BRD)
  String _getMoscowLabel(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'M':
        return 'Must Have';
      case 'S':
        return 'Should Have';
      case 'C':
        return 'Could Have';
      case 'W':
        return 'Won\'t Have';
      default:
        return 'Unknown';
    }
  }
}

// --- Chart Data Structure ---
class ChartData {
  ChartData(this.x, this.y, [this.color]);
  final String x; // Category Name (e.g., 'Functional', 'Must Have', 'Pending')
  final double y; // Value (e.g., count or percentage)
  final Color? color; // Optional color for slices/bars
}

// --- Analytics Screen Widget ---
class AnalyticsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> requirementsData;
  const AnalyticsScreen({super.key, required this.requirementsData});

  // Helper to get MoSCoW label from priority key
  String _getMoscowLabel(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'M':
        return 'Must Have';
      case 'S':
        return 'Should Have';
      case 'C':
        return 'Could Have';
      case 'W':
        return 'Won\'t Have';
      default:
        return 'Unknown';
    }
  }

  // Helper to get color for MoSCoW chart slices
  Color _getMoscowColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'M':
        return Colors.redAccent;
      case 'S':
        return Colors.orangeAccent;
      case 'C':
        return Colors.lightBlueAccent;
      case 'W':
        return Colors.grey;
      default:
        return Colors.grey.shade400;
    }
  }

  // Helper to get color for Status chart bars (Example colors)
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'New':
        return Colors.green;
      case 'Updated':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.teal;
      case 'Rejected':
        return Colors.redAccent;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Data Processing for Charts ---
    int functionalCount = 0;
    int nonFunctionalCount = 0;
    Map<String, int> moscowCounts = {'M': 0, 'S': 0, 'C': 0, 'W': 0};
    Map<String, int> statusCounts = {};

    for (var req in requirementsData) {
      // Functional vs Non-Functional
      String? type = req['type']?.toString();
      if (type == 'Functional') {
        functionalCount++;
      } else if (type == 'Non-Functional') {
        nonFunctionalCount++;
      }

      // MoSCoW
      String? priority = req['priority']?.toString().toUpperCase();
      if (moscowCounts.containsKey(priority)) {
        moscowCounts[priority!] = moscowCounts[priority]! + 1;
      }

      // Status
      String? status = req['status']?.toString();
      if (status != null && status.isNotEmpty) {
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
    }

    int totalReqs = requirementsData.length;

    // Prepare data lists for charts
    final List<ChartData> funcNFuncData = [];
    if (totalReqs > 0) {
      if (functionalCount > 0) {
        funcNFuncData.add(ChartData(
            'Functional', (functionalCount / totalReqs) * 100, Colors.teal));
      }
      if (nonFunctionalCount > 0) {
        funcNFuncData.add(ChartData('Non-Functional',
            (nonFunctionalCount / totalReqs) * 100, Colors.deepOrangeAccent));
      }
      // Handle case where types might be other values or missing
      int otherCount = totalReqs - functionalCount - nonFunctionalCount;
      if (otherCount > 0) {
        funcNFuncData.add(ChartData(
            'Other/Unset', (otherCount / totalReqs) * 100, Colors.grey));
      }
    }

    final List<ChartData> moscowData = moscowCounts.entries
        .where(
            (entry) => entry.value > 0) // Only include priorities with counts
        .map((entry) => ChartData(_getMoscowLabel(entry.key),
            entry.value.toDouble(), _getMoscowColor(entry.key)))
        .toList();

    final List<ChartData> statusData = statusCounts.entries
        .map((entry) => ChartData(entry.key, entry.value.toDouble(),
            _getStatusColor(entry.key))) // Pass color here
        .toList();
    // Sort status data alphabetically by status name for consistent chart display
    statusData.sort((a, b) => a.x.compareTo(b.x));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requirements Analytics'),
      ),
      body: requirementsData.isEmpty
          ? const Center(child: Text('No data available for analysis.'))
          : SingleChildScrollView(
              // Allow scrolling if charts overflow
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildChartCard(
                    title: '% Functional vs Non-Functional',
                    chart: SfCircularChart(
                      legend: const Legend(
                          isVisible: true, position: LegendPosition.bottom),
                      series: <CircularSeries<ChartData, String>>[
                        PieSeries<ChartData, String>(
                          dataSource: funcNFuncData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          pointColorMapper: (ChartData data, _) => data.color,
                          dataLabelMapper: (ChartData data, _) =>
                              '${data.y.toStringAsFixed(1)}%', // Show percentage
                          dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              textStyle: TextStyle(fontSize: 12)),
                          // Optional: explodeOnClick: true,
                          selectionBehavior: SelectionBehavior(enable: true),
                        )
                      ],
                      tooltipBehavior: TooltipBehavior(
                          enable: true, format: 'point.x: point.y%'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildChartCard(
                    title: 'MoSCoW Priority Breakdown',
                    chart: SfCircularChart(
                      legend: const Legend(
                          isVisible: true, position: LegendPosition.bottom),
                      series: <CircularSeries<ChartData, String>>[
                        DoughnutSeries<ChartData, String>(
                          // Changed to Doughnut
                          dataSource: moscowData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          pointColorMapper: (ChartData data, _) => data.color,
                          dataLabelMapper: (ChartData data, _) =>
                              '${data.y.toInt()}', // Show count
                          dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              textStyle: TextStyle(fontSize: 12)),
                          explode: true, // Enable explode effect
                          explodeAll: false,
                          explodeIndex:
                              -1, // Explodes on tap by default with selectionBehavior
                          selectionBehavior: SelectionBehavior(enable: true),
                          innerRadius: '40%', // Make it a doughnut chart
                        )
                      ],
                      tooltipBehavior: TooltipBehavior(
                          enable: true, format: 'point.x: point.y'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildChartCard(
                    title: 'Requirements Status',
                    chart: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(
                        labelIntersectAction: AxisLabelIntersectAction
                            .rotate45, // Rotate labels if they overlap
                        majorGridLines: MajorGridLines(
                            width: 0), // Hide vertical grid lines
                      ),
                      primaryYAxis: const NumericAxis(
                        minimum: 0, // Ensure Y-axis starts at 0
                        majorTickLines:
                            MajorTickLines(size: 0), // Hide Y-axis ticks
                        axisLine: AxisLine(width: 0), // Hide Y-axis line
                        labelFormat: '{value}', // Show integer labels
                      ),
                      plotAreaBorderWidth: 0, // Hide plot area border
                      series: <CartesianSeries<ChartData, String>>[
                        ColumnSeries<ChartData, String>(
                          // Or BarSeries for horizontal
                          dataSource: statusData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          pointColorMapper: (ChartData data, _) =>
                              data.color, // Use status color
                          dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              textStyle: TextStyle(fontSize: 11)),
                          borderRadius: const BorderRadius.all(
                              Radius.circular(5)), // Rounded corners
                          // Optional: Add gradient fill
                          // gradient: LinearGradient(...)
                        )
                      ],
                      tooltipBehavior: TooltipBehavior(enable: true),
                      // Zooming/Panning disabled by default, enable if needed:
                      // zoomPanBehavior: ZoomPanBehavior(enablePanning: true, enablePinching: true),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper widget to create consistent card styling for charts
  Widget _buildChartCard({required String title, required Widget chart}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            // Constrain chart height - adjust as needed
            SizedBox(
                height: 300, // Give charts a fixed height within the card
                child: chart)
          ],
        ),
      ),
    );
  }
}
