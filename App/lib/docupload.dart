import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui'; // Needed for ImageFilter
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:animated_background/animated_background.dart';
import 'package:reqaize/requirements_qa_screen.dart';

// --- Main Application Setup ---
class DocuMindAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocuMind AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF6366F1),
        scaffoldBackgroundColor: Color(0xFFF8FAFC),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        useMaterial3: true,
      ),
      home: DocuMindHomePage(),
    );
  }
}

// --- Helper Widgets (GlassContainer, GradientText, FeatureCard, AnimatedFAB, NavBarItem) ---
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle? style;

  const GradientText(
    this.text, {
    Key? key,
    required this.gradient,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const FeatureCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const AnimatedFAB({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon),
      backgroundColor: Color(0xFF6366F1),
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    );
  }
}

class NavBarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const NavBarItem({
    Key? key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Color(0xFF6366F1) : Color(0xFF64748B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Home Page Implementation ---
class DocuMindHomePage extends StatefulWidget {
  @override
  _DocuMindHomePageState createState() => _DocuMindHomePageState();
}

class _DocuMindHomePageState extends State<DocuMindHomePage>
    with TickerProviderStateMixin {
  // Use TickerProviderStateMixin for AnimatedBackground
  final String _mistralApiKey = '0zjmsSJLjr0dvpgoN7l0ivkBCDQ5DgtL';

  int _currentNavIndex = 0;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  late AnimationController _fabAnimationController;

  // Only keep the requirements extraction result
  String _extractedText = '';

  bool _isLoading = false; // For API calls and PDF generation
  bool _isExtracting = false; // For file/web content extraction
  Uint8List? _selectedFileBytes;
  String _selectedFileName = '';
  String _selectedFileType = '';
  String _fileContent = ''; // Holds combined content for analysis
  String _statusMessage = '';

  // Definition for AnimatedBackground particles
  ParticleOptions particles = const ParticleOptions(
    baseColor: Color(0xFF6366F1), // Match theme color
    spawnOpacity: 0.0,
    opacityChangeRate: 0.25,
    minOpacity: 0.1,
    maxOpacity: 0.3, // Slightly more subtle
    particleCount: 40, // Adjusted count
    spawnMaxRadius: 15.0,
    spawnMaxSpeed: 80.0, // Slower speed
    spawnMinSpeed: 20,
    spawnMinRadius: 5.0,
  );

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _urlController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF6366F1).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _statusMessage = 'Opening file picker...';
      _isExtracting = true; // Indicate loading during file pick/read
    });
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
        withData: true,
      );
      if (result != null) {
        String fileName = result.files.single.name;
        String fileExtension = fileName.split('.').last.toLowerCase();

        // Handle unsupported types early
        if (fileExtension != 'pdf' && fileExtension != 'txt') {
          _showSnackBar(
              'Unsupported file type: .$fileExtension. Please use PDF or TXT.');
          setState(() {
            _statusMessage = 'Unsupported file type selected';
            _isExtracting = false;
          });
          return;
        }

        String fileType = '.$fileExtension';
        Uint8List? fileBytes = result.files.single.bytes;

        if (fileBytes != null) {
          setState(() {
            _selectedFileBytes = fileBytes;
            _selectedFileName = fileName;
            _selectedFileType = fileType;
            // Reset previous results and content when a new file is picked
            _fileContent = '';
            _extractedText = '';
            _statusMessage = 'Extracting text from $fileName...';
          });
          await _extractTextFromFileBytes(fileBytes, fileType);
        } else {
          _showSnackBar('Could not read file content for $fileName');
          setState(() {
            _isExtracting = false;
            _statusMessage = 'File reading failed';
          });
        }
      } else {
        // User canceled the picker
        setState(() {
          _isExtracting = false;
          _statusMessage = ''; // Clear status message
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e');
      if (mounted) {
        setState(() {
          _isExtracting = false;
          _statusMessage = 'Error picking file';
        });
      }
    } finally {
      // Ensure extraction state is false if it hasn't been set elsewhere
      if (mounted &&
          _isExtracting &&
          _statusMessage != 'Extracting text from $_selectedFileName...') {
        setState(() => _isExtracting = false);
      }
    }
  }

  Future<void> _extractTextFromFileBytes(
      Uint8List bytes, String fileType) async {
    String content = '';
    try {
      switch (fileType) {
        case '.pdf':
          final PdfDocument document = PdfDocument(inputBytes: bytes);
          StringBuilder textBuilder = StringBuilder();
          for (int i = 0; i < document.pages.count; i++) {
            String text = PdfTextExtractor(document)
                .extractText(startPageIndex: i, endPageIndex: i);
            textBuilder.append(text);
            if (i < document.pages.count - 1) {
              textBuilder.append('\n\n--- Page Break ---\n\n');
            }
          }
          content = textBuilder.toString();
          document.dispose();
          break;
        case '.txt':
          // Try UTF-8 first, fallback to Latin1
          try {
            content = utf8.decode(bytes);
          } catch (e) {
            print("UTF-8 decoding failed, trying Latin1: $e");
            content = latin1.decode(bytes);
          }
          break;
        default:
          content =
              'Unsupported file type: $fileType. Please upload a PDF or TXT file.';
          _showSnackBar('Unsupported file type: $fileType');
      }

      if (mounted) {
        setState(() {
          _fileContent = content; // Store extracted content
          _isExtracting = false; // Extraction finished
          _statusMessage =
              content.startsWith('Unsupported') || content.startsWith('Error')
                  ? 'Text extraction failed'
                  : 'Text extraction complete. Ready to analyze.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fileContent = 'Error extracting text: $e';
          _isExtracting = false;
          _statusMessage = 'Error in text extraction';
        });
      }
      _showSnackBar('Error extracting text: $e');
    }
  }

  Future<void> _fetchWebContent() async {
    if (_urlController.text.isEmpty) {
      _showSnackBar('Please enter a URL');
      return;
    }
    String url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
      _urlController.text = url; // Update the text field
    }

    setState(() {
      _isExtracting = true; // Use same flag for web fetching
      _statusMessage = 'Fetching web content from $url...';
    });

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        String body;
        try {
          body = utf8.decode(response.bodyBytes);
        } catch (_) {
          body = latin1.decode(response.bodyBytes);
        }

        // Basic HTML tag removal
        String textContent = body.replaceAll(
            RegExp(r'<script[^>]*>.*?</script>',
                multiLine: true, caseSensitive: false),
            ' ');
        textContent = textContent.replaceAll(
            RegExp(r'<style[^>]*>.*?</style>',
                multiLine: true, caseSensitive: false),
            ' ');
        textContent = textContent.replaceAll(RegExp(r'<[^>]*>'), ' ');
        textContent = textContent.replaceAll(RegExp(r'\s+'), ' ').trim();

        setState(() {
          String webContent = '--- Web Content from $url ---\n\n$textContent';
          // Append web content to existing content (or replace if empty)
          _fileContent = _fileContent.isEmpty
              ? webContent
              : '$_fileContent\n\n$webContent';
          _statusMessage = 'Web content fetched and added successfully.';
        });
      } else {
        _showSnackBar(
            'Failed to load web content: Status code ${response.statusCode}');
        _statusMessage =
            'Failed to fetch web content (Code: ${response.statusCode})';
      }
    } on TimeoutException {
      _showSnackBar('Error fetching web content: Request timed out.');
      _statusMessage = 'Error fetching web content: Timeout';
    } catch (e) {
      _showSnackBar('Error fetching web content: $e');
      _statusMessage = 'Error fetching web content';
    } finally {
      if (mounted) {
        setState(() {
          _isExtracting = false; // Turn off loading state
        });
      }
    }
  }

  Future<void> _analyzeData() async {
    String combinedInput = _fileContent; // Start with file/web content
    if (_emailController.text.isNotEmpty) {
      // Append email text if provided
      combinedInput += "\n\n--- Email Text ---\n\n${_emailController.text}";
    }

    if (combinedInput.trim().isEmpty) {
      _showSnackBar(
          'Please provide some content (upload file, fetch URL, or paste email text) for analysis.');
      return;
    }

    // Basic check for placeholder API key
    if (_mistralApiKey == 'YOUR_MISTRAL_API_KEY' || _mistralApiKey.isEmpty) {
      _showSnackBar('Error: Please set your Mistral API Key in the code.');
      return;
    }

    setState(() {
      _isLoading = true;
      // Clear previous results before new analysis
      _extractedText = '';
      _statusMessage = 'Analyzing data with Mistral AI...';
    });

    try {
      // Run the analysis (fetches requirements only)
      await _analyzeMistral(combinedInput);

      if (mounted && _extractedText.isNotEmpty) {
        // Check if requirements were actually found/extracted
        setState(() =>
            _statusMessage = 'Analysis complete. Navigating to results...');
        // Short delay before navigation to allow user to see status update
        await Future.delayed(Duration(milliseconds: 300));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequirementsQAScreen(
              extractedRequirements: _extractedText, // Pass the main result
              mistralApiKey: _mistralApiKey, // Pass key for potential Q&A
            ),
          ),
        );
      } else if (mounted) {
        // Handle case where analysis finished but no requirements were extracted
        _statusMessage =
            'Analysis complete, but no specific requirements were extracted.';
        // Optionally show a dialog or keep the message on the home screen
        _showSnackBar(
            'Analysis complete. No requirements found to display in detail.');
      }
    } catch (e) {
      _showSnackBar('Error during analysis: $e');
      _statusMessage = 'Analysis failed: ${e.toString()}';
      print('Analysis error: $e');
    } finally {
      // Ensure loading indicator stops regardless of outcome
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Optimized Mistral API Interaction ---
  Future<void> _analyzeMistral(String inputText) async {
    try {
      const basePrompt =
          "You are an expert requirements analyst. Analyze the following document content meticulously.";

      // Only keep the requirements extraction prompt
      String reqPrompt =
          "$basePrompt\n\nDocument Content:\n\"\"\"\n$inputText\n\"\"\"\n\nTask: Extract and list all functional and non-functional requirements or specifications mentioned in the document. Each requirement must be on its own line. Format the output as a bullet point list using dash (-) as the bullet character. Clearly label each one as either functional or non-functional at the beginning of the requirement text. If none are found, explicitly state 'No requirements found.'.";

      // Only perform one API call instead of four
      if (mounted)
        setState(
            () => _statusMessage = 'Analyzing: Extracting requirements...');

      String reqResult = await _runMistralApiCall(reqPrompt);
      setState(() => _extractedText = reqResult);
    } catch (e) {
      print("Error in _analyzeMistral: $e");
      rethrow;
    }
  }

  Future<String> _runMistralApiCall(String prompt) async {
    final url = Uri.parse('https://api.mistral.ai/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_mistralApiKey',
    };
    final body = jsonEncode({
      'model': 'mistral-large-latest',
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.2,
      'max_tokens': 1500,
    });

    try {
      print("--- Sending API Request ---");

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(Duration(seconds: 90));

      final responseBody = utf8.decode(response.bodyBytes);
      print("--- Received API Response ---");
      print("Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);
        if (data.containsKey('choices') &&
            data['choices'] is List &&
            data['choices'].isNotEmpty &&
            data['choices'][0] is Map &&
            data['choices'][0].containsKey('message') &&
            data['choices'][0]['message'] is Map &&
            data['choices'][0]['message'].containsKey('content')) {
          String content =
              data['choices'][0]['message']['content']?.trim() ?? '';
          print("Extracted Content Length: ${content.length}");
          return content;
        } else {
          print(
              "Error: Unexpected API response format. Full response: $responseBody");
          throw Exception('Unexpected API response format.');
        }
      } else {
        // Handle API errors more gracefully
        String errorMessage = 'API Error ${response.statusCode}.';
        try {
          final errorData = json.decode(responseBody);
          // Try common error message structures
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage += ' ${errorData['message']}';
          } else if (errorData is Map &&
              errorData.containsKey('error') &&
              errorData['error'] is Map &&
              errorData['error'].containsKey('message')) {
            errorMessage += ' ${errorData['error']['message']}';
          } else {
            errorMessage += ' Could not parse error details.';
          }
        } catch (e) {
          errorMessage +=
              ' Raw response snippet: ${responseBody.substring(0, (responseBody.length > 200 ? 200 : responseBody.length))}...';
        }
        print("API Error: $errorMessage");
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      print("Error: API request timed out.");
      throw Exception('The analysis request timed out. Please try again.');
    } catch (e) {
      print("Error during API call: $e");
      String errorMsg = e.toString();
      // Clean up exception message if needed
      if (e is Exception && errorMsg.startsWith("Exception: ")) {
        errorMsg = errorMsg.substring("Exception: ".length);
      }
      // Rethrow specific errors or a generic one
      if (errorMsg.startsWith('API Error') ||
          errorMsg.contains('timed out') ||
          errorMsg.contains('Unexpected API response format')) {
        throw Exception(errorMsg);
      } else {
        throw Exception('Failed to communicate with AI service: $errorMsg');
      }
    }
  }

  // --- Fixed PDF Export for Mobile compatibility ---
  Future<void> _exportResults() async {
    // Check if there's anything to export
    if (_extractedText.isEmpty) {
      _showSnackBar('No analysis results available to export.');
      return;
    }
    setState(() {
      _isLoading = true;
      _statusMessage = 'Generating PDF report...';
    });

    try {
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();
      final PdfGraphics graphics = page.graphics;

      // Define fonts
      final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18,
          style: PdfFontStyle.bold);
      final PdfFont headingFont = PdfStandardFont(PdfFontFamily.helvetica, 14,
          style: PdfFontStyle.bold);
      final PdfFont normalFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
      final PdfFont italicFont = PdfStandardFont(PdfFontFamily.helvetica, 10,
          style: PdfFontStyle.italic);
      final PdfFont listFont = PdfStandardFont(PdfFontFamily.helvetica, 11);

      double currentY = 0; // Track Y position

      // Helper function to draw text
      Future<double> drawText(String text, PdfFont font, double y,
          {PdfBrush? brush,
          PdfTextAlignment alignment = PdfTextAlignment.left,
          double indent = 0}) async {
        PdfTextElement element = PdfTextElement(
            text: text,
            font: font,
            brush: brush ?? PdfBrushes.black,
            format: PdfStringFormat(
                alignment: alignment, lineSpacing: 2, paragraphIndent: indent));

        // Use draw method which provides layout info
        PdfLayoutResult layoutResult = element.draw(
            page: page, // Draw on the current page
            bounds: Rect.fromLTWH(indent, y, pageSize.width - (indent * 2),
                0) // Layout within bounds
            )!; // Assert non-null
        return layoutResult
            .bounds.bottom; // Return the Y position after drawing
      }

      // --- PDF Content ---
      currentY = await drawText('Document Analysis Report', titleFont, currentY,
          alignment: PdfTextAlignment.center);
      currentY += 10;
      final DateTime now = DateTime.now();
      final String dateStr =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      currentY = await drawText('Generated on: $dateStr', normalFont, currentY);
      currentY += 20;

      // Only include the extracted requirements section
      if (_extractedText.isNotEmpty) {
        currentY =
            await drawText('Extracted Requirements', headingFont, currentY);
        currentY += 5;
        currentY = await drawText(_extractedText, normalFont, currentY);
        currentY += 15;
      }

      // --- Save and Download ---
      final List<int> bytes = await document.save();
      document.dispose();
      const String fileName = 'DocuMind_Analysis_Report.pdf';

      if (kIsWeb) {
        // For web, we cannot directly use dart:html here
        // This is intentionally left empty - you would implement
        // web-specific code in a separate conditional import file
        _showSnackBar('Web PDF export not available in mobile version.');
      } else {
        // Mobile/Desktop save (attempt Documents, fallback to Temp)
        try {
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName';
          final file = io.File(filePath);
          await file.writeAsBytes(bytes);
          _showSnackBar('Report saved to Documents: $fileName');
          print('Report saved to: $filePath');
        } catch (e) {
          print("Error saving file to Documents: $e");
          try {
            final directory = await getTemporaryDirectory();
            final filePath = '${directory.path}/$fileName';
            final file = io.File(filePath);
            await file.writeAsBytes(bytes);
            _showSnackBar('Report saved to temporary location: $fileName');
            print('Report saved to Temp: $filePath');
          } catch (e2) {
            print("Error saving file to temp: $e2");
            _showSnackBar('Failed to save report locally. Check permissions?');
          }
        }
      }

      setState(() {
        _statusMessage = 'Report exported successfully';
        _isLoading = false; // Stop loading indicator
      });
    } catch (e) {
      print('Error exporting report: $e');
      _showSnackBar('Error exporting report: $e');
      setState(() {
        _statusMessage = 'Export failed';
        _isLoading = false; // Stop loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    bool isWideScreen = screenSize.width > 800;
    int crossAxisCount = isWideScreen ? 4 : 2;
    double horizontalPadding = isWideScreen ? 48.0 : 16.0;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(options: particles),
            child: Container(),
          ),

          // Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  // --- App Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            /* Icon container */
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF6366F1).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          GradientText(
                            /* App Title */
                            'DocuMind AI',
                            gradient: LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        /* Action Buttons */
                        children: [
                          IconButton(
                            /* Help Button */
                            icon: Icon(Icons.help_outline_rounded),
                            onPressed: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                    title: Text("Help"),
                                    content: Text(
                                        "Upload a PDF/TXT, paste email text, or enter a URL. Then click 'Analyze Document' to extract requirements and view results on the next screen. Use the PDF icon to export results after analysis."))),
                            color: Color(0xFF6366F1),
                          ),
                          IconButton(
                            /* Export Button */
                            icon: Icon(Icons.picture_as_pdf_outlined),
                            tooltip: 'Export Results as PDF',
                            // Enable only if NOT loading AND there are results to export
                            onPressed: (_isLoading || _extractedText.isEmpty)
                                ? null
                                : _exportResults,
                            color: Color(0xFF6366F1),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // --- Welcome Message ---
                  GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to DocuMind AI',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload documents, paste text, or fetch web content to extract requirements and analyze using AI.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // --- Input Sections (File, Email, URL) ---
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool showSideBySide = constraints.maxWidth > 600;
                      if (showSideBySide) {
                        return Row(
                          /* Side-by-side for wide screens */
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildFileUploadSection()),
                            SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildEmailInputSection(),
                                  SizedBox(height: 16),
                                  _buildUrlInputSection(),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          /* Stacked for narrow screens */
                          children: [
                            _buildFileUploadSection(),
                            SizedBox(height: 16),
                            _buildEmailInputSection(),
                            SizedBox(height: 16),
                            _buildUrlInputSection(),
                          ],
                        );
                      }
                    },
                  ),
                  SizedBox(height: 24),

                  // --- Analysis Button Section ---
                  GlassContainer(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to Analyze?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Click below to process the provided content and view results.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            // Disable if loading, extracting, OR no content provided
                            onPressed: (_isLoading ||
                                    _isExtracting ||
                                    (_fileContent.trim().isEmpty &&
                                        _emailController.text.trim().isEmpty))
                                ? null
                                : _analyzeData,
                            icon: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.auto_awesome),
                            label: Text(
                              _isLoading
                                  ? 'Analyzing...'
                                  : 'Analyze & View Results',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Color(0xFFa5b4fc),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Status Message Display ---
                  if (_statusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: GlassContainer(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            // Show progress indicator only when actively loading/extracting
                            if (_isLoading || _isExtracting)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF6366F1),
                                  strokeWidth: 2,
                                ),
                              )
                            else // Show icon based on status message content
                              Icon(
                                _statusMessage
                                            .toLowerCase()
                                            .contains('error') ||
                                        _statusMessage
                                            .toLowerCase()
                                            .contains('fail')
                                    ? Icons.error_outline
                                    : (_statusMessage
                                                .toLowerCase()
                                                .contains('complete') ||
                                            _statusMessage
                                                .toLowerCase()
                                                .contains('success') ||
                                            _statusMessage
                                                .toLowerCase()
                                                .contains('ready'))
                                        ? Icons.check_circle_outline
                                        : Icons
                                            .info_outline, // Default info icon
                                color: _statusMessage
                                            .toLowerCase()
                                            .contains('error') ||
                                        _statusMessage
                                            .toLowerCase()
                                            .contains('fail')
                                    ? Colors.redAccent
                                    : (_statusMessage
                                                .toLowerCase()
                                                .contains('complete') ||
                                            _statusMessage
                                                .toLowerCase()
                                                .contains('success') ||
                                            _statusMessage
                                                .toLowerCase()
                                                .contains('ready'))
                                        ? Colors.green
                                        : Color(0xFF6366F1), // Default color
                                size: 20,
                              ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _statusMessage
                                              .toLowerCase()
                                              .contains('error') ||
                                          _statusMessage
                                              .toLowerCase()
                                              .contains('fail')
                                      ? Colors.redAccent
                                          .shade700 // Darker red for better readability
                                      : (_statusMessage
                                                  .toLowerCase()
                                                  .contains('complete') ||
                                              _statusMessage
                                                  .toLowerCase()
                                                  .contains('success') ||
                                              _statusMessage
                                                  .toLowerCase()
                                                  .contains('ready'))
                                          ? Colors
                                              .green.shade700 // Darker green
                                          : Color(
                                              0xFF1E293B), // Default text color
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 24),

                  // --- Feature cards ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Features Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 16),
                      GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: 4,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final featureData = [
                            {
                              'title': 'Extract Requirements',
                              'subtitle':
                                  'Identify functional & non-functional specs',
                              'icon': Icons.format_list_bulleted,
                              'colors': [Color(0xFF6366F1), Color(0xFF8B5CF6)]
                            },
                            {
                              'title': 'Analyze Issues',
                              'subtitle':
                                  'Detect ambiguities & potential problems',
                              'icon': Icons.warning_amber_outlined,
                              'colors': [Color(0xFF8B5CF6), Color(0xFFA78BFA)]
                            },
                            {
                              'title': 'Get Suggestions',
                              'subtitle':
                                  'Receive AI-powered improvement ideas',
                              'icon': Icons.lightbulb_outline,
                              'colors': [Color(0xFFA78BFA), Color(0xFFEC4899)]
                            },
                            {
                              'title': 'Export Reports',
                              'subtitle': 'Download analysis as PDF documents',
                              'icon': Icons.picture_as_pdf_outlined,
                              'colors': [Color(0xFFEC4899), Color(0xFFF43F5E)]
                            },
                          ];
                          final item = featureData[index];
                          return FeatureCard(
                            title: item['title'] as String,
                            subtitle: item['subtitle'] as String,
                            icon: item['icon'] as IconData,
                            gradientColors: item['colors'] as List<Color>,
                            onTap: () =>
                                _showSnackBar("Feature: ${item['title']}"),
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      // --- Floating Action Button (Help) ---
      floatingActionButton: AnimatedFAB(
        icon: Icons.help_outline,
        tooltip: 'Help',
        onPressed: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: Text("Help"),
                content: Text(
                    "Upload a PDF/TXT, paste email text, or enter a URL. Then click 'Analyze Document' to extract requirements and view results on the next screen. Use the PDF icon in the header to export results after analysis."))),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // --- Bottom Navigation Bar (Glass Effect) ---
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(16).copyWith(bottom: 20),
        decoration: BoxDecoration(
          /* Shadow */
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            /* Glass effect */
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: 68,
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                /* Gradient background */
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.75),
                    Colors.white.withOpacity(0.65)
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1.0),
              ),
              child: Row(
                /* Nav Bar Items */
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  NavBarItem(
                    label: 'Home',
                    icon: Icons.home_rounded,
                    isActive: _currentNavIndex == 0,
                    onTap: () => setState(() => _currentNavIndex = 0),
                  ),
                  NavBarItem(
                      label: 'Analysis',
                      icon: Icons.analytics_outlined,
                      isActive: _currentNavIndex == 1,
                      onTap: () {
                        setState(() => _currentNavIndex = 1);
                        // If content is available, trigger analysis (navigates on success)
                        if (!_isLoading &&
                            !_isExtracting &&
                            (_fileContent.isNotEmpty ||
                                _emailController.text.isNotEmpty)) {
                          _analyzeData();
                        } else if (!_isLoading && !_isExtracting) {
                          _showSnackBar(
                              "Upload a document or add text first to analyze.");
                        }
                      }),
                  NavBarItem(
                      label: 'Export',
                      icon: Icons.picture_as_pdf_outlined,
                      isActive: _currentNavIndex == 2,
                      onTap: () {
                        setState(() => _currentNavIndex = 2);
                        // Trigger export if results are available
                        if (!_isLoading && _extractedText.isNotEmpty) {
                          _exportResults();
                        } else if (!_isLoading) {
                          _showSnackBar(
                              "Analyze a document first to export results.");
                        }
                      }),
                  NavBarItem(
                      label: 'Settings',
                      icon: Icons.settings_outlined,
                      isActive: _currentNavIndex == 3,
                      onTap: () {
                        setState(() => _currentNavIndex = 3);
                        _showSnackBar("Settings not implemented yet.");
                      }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets for Input Sections ---
  Widget _buildFileUploadSection() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Upload Document (PDF/TXT)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 12),
          Container(
            /* File Drop Area Styling */
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedFileName.isEmpty
                    ? Colors.grey.withOpacity(0.3)
                    : Color(0xFF6366F1).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedFileName.isEmpty
                      ? Icons.upload_file_outlined
                      : (_selectedFileType == '.pdf'
                          ? Icons.picture_as_pdf_outlined
                          : Icons.text_snippet_outlined),
                  color: _selectedFileName.isEmpty
                      ? Color(0xFF64748B)
                      : Color(0xFF6366F1),
                  size: 40,
                ),
                SizedBox(height: 12),
                Text(
                  _selectedFileName.isEmpty
                      ? 'Drag & drop or browse'
                      : _selectedFileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: _selectedFileName.isEmpty
                        ? Color(0xFF64748B)
                        : Color(0xFF6366F1),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                if (_selectedFileName.isEmpty)
                  Text(
                    'Supports PDF and TXT files',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  /* Browse/Change Button */
                  onPressed: _isLoading || _isExtracting ? null : _pickFile,
                  icon: Icon(Icons.file_upload_outlined, size: 18),
                  label: Text(_selectedFileName.isEmpty ? 'Browse' : 'Change'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Color(0xFFa5b4fc),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
          if (_selectedFileName.isNotEmpty &&
              !_statusMessage.toLowerCase().contains(
                  'error')) // Show status if file selected and no error
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(
                      _isExtracting
                          ? Icons.hourglass_top_rounded
                          : Icons.check_circle,
                      color: _isExtracting ? Colors.orangeAccent : Colors.green,
                      size: 16),
                  SizedBox(width: 8),
                  Text(
                    _isExtracting ? 'Extracting text...' : 'File ready',
                    style: TextStyle(
                      color: _isExtracting ? Colors.orangeAccent : Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmailInputSection() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email_outlined, color: Color(0xFF8B5CF6), size: 18),
              SizedBox(width: 8),
              Text(
                '2. Paste Email Text (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Paste email content here...',
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              filled: true,
              fillColor: Colors.white.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 4,
            style: TextStyle(fontSize: 14),
            enabled: !_isLoading && !_isExtracting,
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInputSection() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language_outlined, color: Color(0xFF8B5CF6), size: 18),
              SizedBox(width: 8),
              Text(
                '3. Fetch Web URL (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'Enter website URL...',
                    hintStyle:
                        TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: TextStyle(fontSize: 14),
                  enabled: !_isLoading && !_isExtracting,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                /* Fetch Button */
                onPressed:
                    _isLoading || _isExtracting ? null : _fetchWebContent,
                child: Icon(Icons.download_outlined, size: 20),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Color(0xFFc4b5fd),
                  padding: EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(48, 48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- StringBuilder Class ---
class StringBuilder {
  final StringBuffer _buffer = StringBuffer();
  void append(String part) => _buffer.write(part);
  @override
  String toString() => _buffer.toString();
}
