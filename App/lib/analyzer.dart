import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

// Import dart:io only on non-web platforms
import 'platform_file.dart' if (dart.library.html) 'platform_file_web.dart';

// Updated helper methods for file handling
Future<Uint8List> _readFileAsBytes(String path) async {
  if (kIsWeb) {
    throw Exception('File path access is not supported on web');
  } else {
    // Use dart:io File on mobile/desktop
    return await File(path).readAsBytes();
  }
}

Future<void> _writeToFile(String path, List<int> bytes) async {
  if (kIsWeb) {
    throw Exception('File path access is not supported on web');
  } else {
    final file = File(path);
    await file.writeAsBytes(bytes);
  }
}

class DocumentAnalyzerPage extends StatefulWidget {
  const DocumentAnalyzerPage({Key? key}) : super(key: key);

  @override
  _DocumentAnalyzerPageState createState() => _DocumentAnalyzerPageState();
}

class Message {
  final String text;
  final bool isUser;

  Message(this.text, this.isUser);
}

class _DocumentAnalyzerPageState extends State<DocumentAnalyzerPage> {
  bool _isLoading = false;
  String _extractedText = '';
  String _generatedContent = '';
  String _fileName = '';
  String _fileType = '';

  // Chat state
  List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _showChat = false;
  bool _fileUploaded = false;

  // User preferences
  String _techStack = '';
  String _projectPurpose = '';
  String _testingPreference = '';

  // Hardcoded Mistral API key - Replace with your actual API key
  final String _mistralApiKey = '0zjmsSJLjr0dvpgoN7l0ivkBCDQ5DgtL';

  @override
  void initState() {
    super.initState();
    _addBotMessage(
        "Welcome! Please upload a PDF or Excel file to begin analysis.");
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(Message(message, true));
    });
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add(Message(message, false));
    });
  }

  Future<void> _pickAndProcessFile() async {
    setState(() {
      _isLoading = true;
      _extractedText = '';
      _generatedContent = '';
      // Reset previous state on new upload
      _messages = [];
      _showChat = false;
      _fileUploaded = false;
      _techStack = '';
      _projectPurpose = '';
      _testingPreference = '';
      _addBotMessage(
          "Welcome! Please upload a PDF or Excel file to begin analysis.");
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'xlsx', 'xls'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        _fileName = file.name;
        _fileType = file.extension?.toLowerCase() ?? '';

        if (_fileType == 'pdf') {
          await _extractTextFromPdf(file);
        } else if (_fileType == 'xlsx' || _fileType == 'xls') {
          await _extractTextFromExcel(file);
        }

        if (_extractedText.isNotEmpty) {
          setState(() {
            _fileUploaded = true;
            _showChat = true;
          });

          _addBotMessage(
              "Great! I've analyzed your ${_fileType.toUpperCase()} file: $_fileName");
          _addBotMessage(
              "What technology stack would you like to use for code generation? (e.g., Flutter, React, Python, Java, etc.)");
        } else if (_fileName.isNotEmpty) {
          // Handle case where file was picked but text extraction failed
          _addBotMessage(
              "Sorry, I couldn't extract text from $_fileName. Please try a different file.");
          setState(() {
            _fileUploaded = false;
            _showChat = false;
          });
        }
      } else {
        // User canceled the picker
        _addBotMessage("File selection cancelled.");
      }
    } catch (e) {
      _showSnackBar('Error processing file: $e');
      _addBotMessage(
          "An error occurred while processing the file. Please try again.");
      setState(() {
        _fileUploaded = false;
        _showChat = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _extractTextFromPdf(PlatformFile file) async {
    try {
      // Web-compatible approach
      Uint8List? fileBytes;
      if (file.bytes != null) {
        // Web will provide bytes directly
        fileBytes = file.bytes;
      } else if (file.path != null && !kIsWeb) {
        // Mobile/desktop need to read from path
        fileBytes = await _readFileAsBytes(file.path!);
      } else {
        throw Exception('Could not access file data');
      }

      if (fileBytes != null) {
        // Use SyncFusion PDF for both web and mobile
        PdfDocument document = PdfDocument(inputBytes: fileBytes);
        PdfTextExtractor extractor = PdfTextExtractor(document);
        String text = extractor.extractText();
        setState(() {
          _extractedText = text;
        });
        document.dispose();
      } else {
        _extractedText = '';
        _showSnackBar('Could not access PDF file data.');
      }
    } catch (e) {
      _extractedText = '';
      _showSnackBar('Error extracting text from PDF: $e');
    }
  }

  Future<void> _extractTextFromExcel(PlatformFile file) async {
    try {
      StringBuffer buffer = StringBuffer();
      Uint8List? fileBytes;

      if (file.bytes != null) {
        // Web will provide bytes directly
        fileBytes = file.bytes;
      } else if (file.path != null && !kIsWeb) {
        // Mobile/desktop need to read from path
        fileBytes = await _readFileAsBytes(file.path!);
      } else {
        throw Exception('Could not access file data');
      }

      if (fileBytes != null) {
        var excelFile = Excel.decodeBytes(fileBytes);
        for (var table in excelFile.tables.keys) {
          buffer.writeln('Sheet: $table');
          var sheet = excelFile.tables[table];
          if (sheet != null) {
            for (var i = 0; i < sheet.maxRows; i++) {
              List<String> rowCells = [];
              List<Data?> row = sheet.row(i);
              for (var cell in row) {
                rowCells.add(cell?.value?.toString() ?? '');
              }
              buffer.writeln(rowCells.join(' | '));
            }
          }
          buffer.writeln();
        }
        setState(() {
          _extractedText = buffer.toString();
        });
      } else {
        _extractedText = '';
        _showSnackBar('Could not access Excel file data.');
      }
    } catch (e) {
      _extractedText = '';
      _showSnackBar('Error extracting text from Excel: $e');
    }
  }

  // Helper method for cross-platform file reading
  Future<Uint8List> _readFileAsBytes(String path) async {
    if (kIsWeb) {
      throw Exception('File path access is not supported on web');
    } else {
      // Use dart:io File on mobile/desktop
      return await File(path).readAsBytes();
    }
  }

  void _handleUserInput(String text) {
    if (text.trim().isEmpty) return;

    _addUserMessage(text);
    _textController.clear();

    // Handle conversation flow based on what we've collected so far
    if (_techStack.isEmpty) {
      _techStack = text;
      _addBotMessage(
          "Thanks! What is the main purpose of your project? (e.g., web app, mobile app, data analysis, etc.)");
    } else if (_projectPurpose.isEmpty) {
      _projectPurpose = text;
      _addBotMessage(
          "What level of testing would you prefer? (basic, comprehensive, or minimal)");
    } else if (_testingPreference.isEmpty) {
      _testingPreference = text;
      _addBotMessage(
          "Great! I have all the information I need. Generating your content now...");
      _generateContent();
    } else {
      // If we already have all the info but user sends another message
      _addBotMessage(
          "I'm working on generating your content. If you want to start over, please upload a new file or press the refresh button.");
    }
  }

  Future<void> _generateContent() async {
    setState(() {
      _isLoading = true;
      _generatedContent = '';
    });

    if (_mistralApiKey == 'YOUR_MISTRAL_API_KEY_HERE' ||
        _mistralApiKey.isEmpty) {
      _showSnackBar('Error: Mistral API key is not set.');
      _addBotMessage(
          "Error: API Key is missing. Please configure the API key in the source code.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Limit extracted text size to avoid exceeding API limits
      const maxTextLength = 3000;
      String truncatedText = _extractedText.length > maxTextLength
          ? _extractedText.substring(0, maxTextLength) + "..."
          : _extractedText;

      final response = await http.post(
        Uri.parse('https://api.mistral.ai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_mistralApiKey',
        },
        body: jsonEncode({
          'model': 'mistral-large-latest',
          'messages': [
            {
              'role': 'system',
              'content': '''
              You are an AI assistant specialized in software development and data analysis.
              Generate detailed content based on document analysis and user preferences.
              Format your response clearly using Markdown for headings, lists, and code blocks.
              '''
            },
            {
              'role': 'user',
              'content': '''
              I've uploaded a ${_fileType.toUpperCase()} file named "$_fileName".
              Extracted content (potentially truncated):
              ```
              $truncatedText
              ```

              Based on this content, please generate the following:

              1.  **Automated Code Generation**: Provide starter code snippets or structure for $_techStack.
              2.  **Test Cases**: Create ${_testingPreference.toLowerCase()} level test cases for the generated code.
              3.  **Test Coverage Calculation Methodology**: Briefly explain how test coverage would be measured for this project.
              4.  **Data Quality Assessment**: Analyze the provided data snippet for potential quality issues (e.g., missing values, inconsistencies).
              5.  **Data Lineage Information**: Based *only* on the provided text, infer or suggest possible data sources or transformations if evident. If not evident, state that.

              Project Purpose: $_projectPurpose

              Please format each section clearly using Markdown.
              '''
            }
          ],
          'temperature': 0.7,
          'max_tokens': 4000,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final content = jsonResponse['choices'][0]['message']['content'];
        setState(() {
          _generatedContent = content;
        });
        _addBotMessage(
            "I've generated your content! You can view it in the Results tab and export it.");
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        _showSnackBar(
            'Error from Mistral API: ${response.statusCode} - $errorBody');
        _addBotMessage(
            "I'm sorry, I encountered an error (${response.statusCode}) while generating your content. Please check the API key and try again.");
      }
    } catch (e) {
      _showSnackBar('Error generating content: $e');
      _addBotMessage(
          "I'm sorry, I encountered an error while generating your content. Please try again.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToText() async {
    if (_generatedContent.isEmpty) {
      _showSnackBar('No content to export');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Format content and prepare for export
      final textContent = _generatedContent;
      final bytes = utf8.encode(textContent);

      if (kIsWeb) {
        // Web export implementation
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute(
              'download', 'analysis_${_fileName.split('.').first}.txt')
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar('File exported successfully');
      } else {
        // Mobile/desktop export using FilePicker
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Analysis Document',
          fileName: 'analysis_${_fileName.split('.').first}.txt',
          allowedExtensions: ['txt'],
          type: FileType.custom,
        );

        if (outputFile != null) {
          if (!outputFile.toLowerCase().endsWith('.txt')) {
            outputFile += '.txt';
          }
          await _writeToFile(outputFile, bytes);
          _showSnackBar('File exported successfully to $outputFile');
        } else {
          _showSnackBar('Export cancelled');
        }
      }
      _addBotMessage("Your document has been exported as a text file!");
    } catch (e) {
      print('Export Error: $e');
      _showSnackBar('Error exporting file: $e');
      _addBotMessage(
          "I encountered an error while exporting your document. Please try again.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method for cross-platform file writing
  Future<void> _writeToFile(String path, List<int> bytes) async {
    if (kIsWeb) {
      throw Exception('File path access is not supported on web');
    } else {
      final file = File(path);
      await file.writeAsBytes(bytes);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _resetApp() {
    setState(() {
      _isLoading = false;
      _extractedText = '';
      _generatedContent = '';
      _fileName = '';
      _fileType = '';
      _messages = [];
      _showChat = false;
      _fileUploaded = false;
      _techStack = '';
      _projectPurpose = '';
      _testingPreference = '';
      _textController.clear();
    });
    _addBotMessage(
        "Welcome! Please upload a PDF or Excel file to begin analysis.");
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Interactive Document Analyzer'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat), text: 'Chat'),
              Tab(icon: Icon(Icons.description), text: 'Results'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetApp,
              tooltip: 'Start Over',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Chat Tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _fileUploaded
                      ? Chip(
                          avatar: Icon(_fileType == 'pdf'
                              ? Icons.picture_as_pdf
                              : Icons.table_chart),
                          label: Text('File: $_fileName'),
                          backgroundColor: Colors.green[100],
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload PDF or Excel File'),
                          onPressed: _isLoading ? null : _pickAndProcessFile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 24.0),
                          ),
                        ),
                ),
                if (_isLoading)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: LinearProgressIndicator(),
                  ),
                Expanded(
                  child: ListView.builder(
                    reverse: false,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 8.0),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 14.0),
                          decoration: BoxDecoration(
                              color: message.isUser
                                  ? Theme.of(context).primaryColorLight
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                topLeft:
                                    Radius.circular(message.isUser ? 12.0 : 0),
                                topRight:
                                    Radius.circular(message.isUser ? 0 : 12.0),
                                bottomLeft: const Radius.circular(12.0),
                                bottomRight: const Radius.circular(12.0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ]),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Text(message.text),
                        ),
                      );
                    },
                  ),
                ),
                // Input Area
                if (_showChat)
                  Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, -2),
                          )
                        ]),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: 'Type your response...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 10.0),
                            ),
                            onSubmitted: _isLoading ? null : _handleUserInput,
                            textInputAction: TextInputAction.send,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _isLoading
                              ? null
                              : () => _handleUserInput(_textController.text),
                          color: Theme.of(context).primaryColor,
                          tooltip: 'Send Message',
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Results Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_generatedContent.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Generated Content',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Export as TXT'),
                          onPressed: _isLoading ? null : _exportToText,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: SingleChildScrollView(
                            child: SelectionArea(
                          child: Text(_generatedContent),
                        )),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _isLoading
                                ? 'Generating content...'
                                : _fileUploaded
                                    ? 'Complete the chat steps to generate content.'
                                    : 'Upload a file and complete the chat to see results here.',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
