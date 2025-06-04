import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart' as excel_package;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:universal_html/html.dart' as html;

// Hardcoded API key
const String MISTRAL_API_KEY = "0zjmsSJLjr0dvpgoN7l0ivkBCDQ5DgtL";

// Data model for a requirement
class Requirement {
  final String reqNo;
  final String type;
  final String description;
  final String moscow;
  final String status;

  Requirement({
    required this.reqNo,
    required this.type,
    required this.description,
    required this.moscow,
    required this.status,
  });

  factory Requirement.fromJson(Map<String, dynamic> json) {
    return Requirement(
      reqNo: json['reqNo'] ?? '',
      type: json['type'] ?? 'Functional',
      description: json['description'] ?? '',
      moscow: json['moscow'] ?? 'Must Have',
      status: json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reqNo': reqNo,
      'type': type,
      'description': description,
      'moscow': moscow,
      'status': status,
    };
  }
}

// Singleton to share requirements between tabs
class RequirementsState {
  static final RequirementsState _instance = RequirementsState._internal();
  static RequirementsState get instance => _instance;
  RequirementsState._internal();

  List<Requirement> _requirements = [];

  List<Requirement> get requirements => List.unmodifiable(_requirements);

  void updateRequirements(List<Requirement> newRequirements) {
    _requirements = List.from(newRequirements);
  }

  void addRequirement(Requirement requirement) {
    _requirements.add(requirement);
  }

  void updateRequirement(int index, Requirement requirement) {
    if (index >= 0 && index < _requirements.length) {
      _requirements[index] = requirement;
    }
  }

  void removeRequirement(int index) {
    if (index >= 0 && index < _requirements.length) {
      _requirements.removeAt(index);
    }
  }
}

// Service class for requirements operations
class RequirementsService {
  // Get mock requirements for testing
  static List<Requirement> getMockRequirements() {
    return [
      Requirement(
        reqNo: "REQ-MOCK-001",
        type: "Functional",
        description: "User should be able to login with username and password",
        moscow: "Must Have",
        status: "Pending",
      ),
      Requirement(
        reqNo: "REQ-MOCK-002",
        type: "Non-Functional",
        description: "System should respond within 3 seconds",
        moscow: "Should Have",
        status: "Pending",
      ),
    ];
  }

  // Get requirements from Mistral AI API
  static Future<Map<String, dynamic>> getRequirementsFromMistral(
      String userPrompt, String modelName, double temperature) async {
    final apiUrl = "https://api.mistral.ai/v1/chat/completions";

    final prompt = '''
      Analyze the following task description. Generate:
      1. A list of functional and non-functional requirements. For each requirement, specify: Requirement number (REQ-XXX), Type, Description, MoSCoW Priority (Must Have, Should Have, Could Have, Won't Have), and Status (Default: Pending).
      2. Basic test case ideas/scenarios relevant to the core requirements.
      3. Simple conceptual code snippets (e.g., function signatures, pseudo-code, basic class structure) related to implementing key requirements.

      Task: $userPrompt

      Format the requirements list as a JSON array within triple backticks like this:
      ```
      [
        {
          "reqNo": "REQ-001",
          "type": "Functional",
          "description": "Description here",
          "moscow": "Must Have",
          "status": "Pending"
        },
        ...
      ]
      ```

      Present the test case ideas and code snippets as separate text blocks *after* the JSON block. Use clear headings like "## Test Case Ideas" and "## Conceptual Code Snippets".
      ''';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $MISTRAL_API_KEY',
      },
      body: jsonEncode({
        'model': modelName,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': temperature,
        'max_tokens': 3000,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final content =
          jsonResponse['choices']?[0]?['message']?['content'] as String? ??
              "Error: Could not extract content from API response.";

      List<Requirement> requirements = [];
      String additionalInfo = content;

      final jsonRegex = RegExp(r'``````');
      final jsonMatch = jsonRegex.firstMatch(content);

      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(1)!;
        try {
          final List<dynamic> requirementsJson = jsonDecode(jsonStr);
          requirements = requirementsJson
              .map((json) => Requirement.fromJson(json))
              .toList();
          final matchEndIndex = jsonMatch.end;
          additionalInfo = content.substring(matchEndIndex).trim();
        } catch (e) {
          additionalInfo =
              "Warning: Failed to parse JSON requirements block. Raw API response follows.\n\n$content";
        }
      } else {
        final simpleJsonMatch =
            RegExp(r'(\[[\s\S]*?\])', multiLine: true).firstMatch(content);
        if (simpleJsonMatch != null) {
          final jsonStr = simpleJsonMatch.group(1)!;
          try {
            final List<dynamic> requirementsJson = jsonDecode(jsonStr);
            requirements = requirementsJson
                .map((json) => Requirement.fromJson(json))
                .toList();
            additionalInfo = content.substring(simpleJsonMatch.end).trim();
          } catch (e) {
            additionalInfo =
                "Warning: Could not find standard JSON block, and failed to parse a fallback [...] block. Raw API response follows.\n\n$content";
          }
        } else {
          additionalInfo =
              "Warning: Could not find any JSON requirements block. Raw API response follows.\n\n$content";
        }
      }

      if (requirements.isEmpty && !content.contains("REQ-")) {
        requirements = getMockRequirements();
        additionalInfo =
            "Warning: Failed to parse requirements from API response. Using Mock Data.\n\nAPI Response:\n$content";
      }

      return {
        'requirements': requirements,
        'additionalInfo': additionalInfo,
      };
    } else {
      throw Exception(
          'Failed to get response from Mistral API: ${response.statusCode} - ${response.body}');
    }
  }

  // Create documents from requirements
  static Future<Map<String, dynamic>?> createDocuments(
      List<Requirement> requirements, String additionalInfo) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      final excelBytes = await createExcelBytes(requirements);
      if (excelBytes == null) {
        return null;
      }

      final markdownContent =
          generateMarkdownContent(requirements, additionalInfo);

      if (kIsWeb) {
        final Map<String, Uint8List> webFiles = {};
        webFiles['requirements_$timestamp.xlsx'] = excelBytes;
        webFiles['requirements_doc_$timestamp.md'] =
            Uint8List.fromList(utf8.encode(markdownContent));
        return {'webFiles': webFiles};
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final dirPath = directory.path;

        final excelPath = '$dirPath/requirements_$timestamp.xlsx';
        final excelFile = File(excelPath);
        await excelFile.writeAsBytes(excelBytes, flush: true);

        final docPath = '$dirPath/requirements_doc_$timestamp.md';
        final docFile = File(docPath);
        await docFile.writeAsString(markdownContent, flush: true);

        return {
          'filePaths': [excelPath, docPath]
        };
      }
    } catch (e) {
      print("Error during document creation: $e");
      return null;
    }
  }

  // Create Excel bytes
  static Future<Uint8List?> createExcelBytes(
      List<Requirement> requirements) async {
    try {
      final excel = excel_package.Excel.createExcel();
      final excel_package.Sheet sheet = excel['Requirements'];

      final excel_package.CellStyle headerStyle = excel_package.CellStyle(
        bold: true,
      );

      // Set Headers
      sheet
          .cell(excel_package.CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: 0))
          .value = excel_package.TextCellValue('Req No');
      sheet
          .cell(excel_package.CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: 0))
          .cellStyle = headerStyle;
      sheet
          .cell(excel_package.CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: 0))
          .value = excel_package.TextCellValue('Type');
      sheet
          .cell(excel_package.CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: 0))
          .cellStyle = headerStyle;
      sheet
          .cell(excel_package.CellIndex.indexByColumnRow(
              columnIndex: 2, rowIndex: 0))
          .value = excel_package.TextCellValue('Description');
      sheet
          .cell(excel_package.CellIndex.indexByColumnRow(
              columnIndex: 2, rowIndex: 0))
          .cellStyle = headerStyle;
      sheet
          .cell(excel_package.CellIndex.indexByColumnRow(
              columnIndex: 3, rowIndex: 0))
          .value = excel_package.TextCellValue('MoSCoW');
      sheet
          .cell(excel_package.CellIndex.indexByColumnRow(
              columnIndex: 3, rowIndex: 0))
          .cellStyle = headerStyle;
      sheet
          .cell(excel_package.CellIndex.indexByColumnRow(
              columnIndex: 4, rowIndex: 0))
          .value = excel_package.TextCellValue('Status');
      sheet
          .cell(excel_package.CellIndex.indexByColumnRow(
              columnIndex: 4, rowIndex: 0))
          .cellStyle = headerStyle;

      // Add data rows
      for (int i = 0; i < requirements.length; i++) {
        int rowIndex = i + 1;
        final req = requirements[i];
        sheet
            .cell(excel_package.CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: rowIndex))
            .value = excel_package.TextCellValue(req.reqNo);
        sheet
            .cell(excel_package.CellIndex.indexByColumnRow(
                columnIndex: 1, rowIndex: rowIndex))
            .value = excel_package.TextCellValue(req.type);
        sheet
            .cell(excel_package.CellIndex.indexByColumnRow(
                columnIndex: 2, rowIndex: rowIndex))
            .value = excel_package.TextCellValue(req.description);
        sheet
            .cell(excel_package.CellIndex.indexByColumnRow(
                columnIndex: 3, rowIndex: rowIndex))
            .value = excel_package.TextCellValue(req.moscow);
        sheet
            .cell(excel_package.CellIndex.indexByColumnRow(
                columnIndex: 4, rowIndex: rowIndex))
            .value = excel_package.TextCellValue(req.status);
      }

      // Adjust column widths
      sheet.setColumnAutoFit(0);
      sheet.setColumnAutoFit(1);
      sheet.setColumnWidth(2, 50);
      sheet.setColumnAutoFit(3);
      sheet.setColumnAutoFit(4);

      final List<int>? encodedBytes = excel.save();
      if (encodedBytes != null) {
        return Uint8List.fromList(encodedBytes);
      } else {
        return null;
      }
    } catch (e) {
      print("Error creating Excel bytes: $e");
      return null;
    }
  }

  // Generate markdown content
  static String generateMarkdownContent(List<Requirement> requirements,
      [String additionalInfo = ""]) {
    final buffer = StringBuffer();

    buffer.writeln('# Requirements Document\n');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}\n');
    buffer.writeln('## Requirements List\n');
    if (requirements.isEmpty) {
      buffer.writeln('No requirements were generated or parsed successfully.');
    } else {
      buffer.writeln(
          '| Req No | Type | Description | Priority (MoSCoW) | Status |');
      buffer.writeln('|---|---|---|---|---|');
      for (final req in requirements) {
        final safeDescription =
            req.description.replaceAll('|', r'\|').replaceAll('\n', '<br>');
        buffer.writeln(
            '| ${req.reqNo} | ${req.type} | $safeDescription | ${req.moscow} | ${req.status} |');
      }
    }

    if (additionalInfo.isNotEmpty) {
      buffer.writeln('\n## Additional Information from AI\n');
      buffer.writeln(additionalInfo);
    }

    buffer.writeln('\n--- End of Document ---');

    return buffer.toString();
  }

  // Download files in web environment
  static void downloadWebFiles(
      Map<String, dynamic> result, Function(String) onError) {
    if (result['webFiles'] == null) {
      onError("Error preparing files for download.");
      return;
    }

    final webFiles = result['webFiles'] as Map<String, Uint8List>;

    webFiles.forEach((fileName, fileData) {
      String mimeType;
      if (fileName.endsWith('.xlsx')) {
        mimeType =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      } else if (fileName.endsWith('.md')) {
        mimeType = 'text/markdown';
      } else if (fileName.endsWith('.json')) {
        mimeType = 'application/json';
      } else if (fileName.endsWith('.csv')) {
        mimeType = 'text/csv';
      } else if (fileName.endsWith('.html')) {
        mimeType = 'text/html';
      } else {
        mimeType = 'application/octet-stream';
      }

      try {
        final blob = html.Blob([fileData], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = fileName;

        html.document.body?.children.add(anchor);

        try {
          anchor.click();
        } catch (e) {
          onError("Could not trigger download. Check browser permissions.");
        } finally {
          if (html.document.body?.contains(anchor) ?? false) {
            html.document.body?.children.remove(anchor);
          }
          html.Url.revokeObjectUrl(url);
        }
      } catch (e) {
        onError("Error preparing file '$fileName' for download: $e");
      }
    });
  }

  // Get color for MoSCoW priority
  static Color getMoscowColor(String moscow) {
    switch (moscow) {
      case 'Must Have':
        return Colors.red;
      case 'Should Have':
        return Colors.orange;
      case 'Could Have':
        return Colors.blue;
      case 'Won\'t Have':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  // Get color for requirement status
  static Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.grey.shade300;
      case 'In Progress':
        return Colors.amber.shade200;
      case 'Completed':
        return Colors.green.shade200;
      case 'Rejected':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade300;
    }
  }

  // Build validation summary widget
  static Widget buildValidationSummary(List<Requirement> requirements) {
    int emptyDescriptions = 0;
    int shortDescriptions = 0;
    int duplicateIds = 0;

    // Find duplicate IDs
    final reqIds = requirements.map((r) => r.reqNo).toList();
    final uniqueIds = reqIds.toSet().toList();
    duplicateIds = reqIds.length - uniqueIds.length;

    // Check descriptions
    for (final req in requirements) {
      if (req.description.isEmpty) {
        emptyDescriptions++;
      } else if (req.description.split(' ').length < 5) {
        shortDescriptions++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(
            duplicateIds > 0 ? Icons.error : Icons.check_circle,
            color: duplicateIds > 0 ? Colors.red : Colors.green,
          ),
          title: Text('Duplicate Requirement IDs'),
          subtitle: Text(duplicateIds > 0
              ? 'Found $duplicateIds duplicate IDs'
              : 'No duplicate IDs found'),
        ),
        ListTile(
          leading: Icon(
            emptyDescriptions > 0 ? Icons.error : Icons.check_circle,
            color: emptyDescriptions > 0 ? Colors.red : Colors.green,
          ),
          title: Text('Empty Descriptions'),
          subtitle: Text(emptyDescriptions > 0
              ? 'Found $emptyDescriptions requirements with empty descriptions'
              : 'No empty descriptions found'),
        ),
        ListTile(
          leading: Icon(
            shortDescriptions > 0 ? Icons.warning : Icons.check_circle,
            color: shortDescriptions > 0 ? Colors.orange : Colors.green,
          ),
          title: Text('Short Descriptions'),
          subtitle: Text(shortDescriptions > 0
              ? 'Found $shortDescriptions requirements with potentially too short descriptions'
              : 'All descriptions have adequate length'),
        ),
      ],
    );
  }
}
