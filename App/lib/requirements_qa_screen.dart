import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
// Removed kIsWeb import and conditional dart:html imports
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border, Color; // Excel package
import 'package:share_plus/share_plus.dart'; // For sharing files
import 'package:path_provider/path_provider.dart'; // For finding temp directory
import 'package:syncfusion_flutter_charts/charts.dart'; // For charts
// Removed file_picker as it's not used in the core Firebase import flow
import 'package:firebase_core/firebase_core.dart'; // Firebase core
import 'package:firebase_storage/firebase_storage.dart'; // Firebase storage
import 'package:http/http.dart' as http; // For HTTP requests (Mistral API)

// Initialize Firebase
void main() async {
  // Ensure Flutter bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Requirements Manager',
      // Light theme settings
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true, // Use Material 3 design
      ),
      // Dark theme settings
      darkTheme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
        useMaterial3: true, // Use Material 3 design
      ),
      themeMode: ThemeMode.system, // Use system theme preference
      // --- Initial Screen ---
      // Start with the Q&A screen to refine requirements extracted from text.
      // Replace 'YOUR_MISTRAL_API_KEY' with your actual key or load it securely.
      // If no API key is provided, AI features will be disabled.
      home: RequirementsQAScreen(
        extractedRequirements: """
        - Functional: User login with email and password.
        - Functional: Password reset functionality via email. (Requires email service)
        - Non-functional: System must respond to login requests within 2 seconds. (Performance)
        - Display user dashboard after login.
        - (Non-functional) Support dark mode theme.
        - Allow users to update their profile information (name, email read-only).
        """,
        mistralApiKey:
            "0zjmsSJLjr0dvpgoN7l0ivkBCDQ5DgtL", // TODO: Replace or load securely!
      ),
      // --- Alternative Start Screen (Directly to Manager) ---
      // Uncomment below to skip Q&A and start directly with predefined data.
      // home: RequirementsManager(
      //   requirementsData: [
      //     {
      //       'reqId': 'F-001', 'priority': 'M', 'type': 'Functional',
      //       'requirement': 'User login with email and password.',
      //       'notes': 'Standard authentication.', 'status': 'Updated'
      //     },
      //     // Add more initial data as needed
      //   ],
      // ),
    );
  }
}

// --- ChatMessage Widget for QA Screen ---
// Represents a single message bubble in the chat interface.
class ChatMessage extends StatelessWidget {
  final String text; // The content of the message
  final bool isUserMessage; // True if the message is from the user
  final bool? isSystemMessage; // True if the message is a system notification

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUserMessage,
    this.isSystemMessage = false, // Default to not being a system message
  });

  @override
  Widget build(BuildContext context) {
    // Determine message alignment and styling based on sender
    final alignment =
        isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start;
    final avatar = isUserMessage
        ? CircleAvatar(
            // User avatar
            backgroundColor: Theme.of(context).colorScheme.secondary,
            radius: 16,
            child: const Icon(Icons.person_outline,
                color: Colors.black87, size: 16),
          )
        : CircleAvatar(
            // AI or System avatar
            backgroundColor: isSystemMessage == true
                ? Colors.grey.shade700 // System message color
                : Theme.of(context).colorScheme.primary, // AI message color
            radius: 16,
            child: Icon(
              isSystemMessage == true
                  ? Icons.info_outline
                  : Icons.smart_toy_outlined,
              color: Colors.white,
              size: 16,
            ),
          );
    final messageColor = isUserMessage
        ? Theme.of(context).colorScheme.primaryContainer
        : (isSystemMessage == true
            ? Colors.grey.shade200
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7));
    final textColor = isUserMessage
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : (isSystemMessage == true
            ? Colors.black87
            : Theme.of(context).colorScheme.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align avatars to the top
        children: [
          // Show avatar on the left for AI/System messages
          if (!isUserMessage) ...[avatar, const SizedBox(width: 8)],
          // Flexible container for the message text
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: messageColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUserMessage
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.5)
                      : Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              // Make message text selectable
              child: SelectableText(
                text,
                style: TextStyle(color: textColor, fontSize: 15),
              ),
            ),
          ),
          // Show avatar on the right for User messages
          if (isUserMessage) ...[const SizedBox(width: 8), avatar],
        ],
      ),
    );
  }
}

// --- RequirementsQAScreen Widget ---
// Screen for interacting with an AI to refine extracted requirements.
class RequirementsQAScreen extends StatefulWidget {
  final String extractedRequirements; // Raw text containing requirements
  final String mistralApiKey; // API key for the Mistral AI service

  const RequirementsQAScreen({
    super.key,
    required this.extractedRequirements,
    required this.mistralApiKey,
  });

  @override
  State<RequirementsQAScreen> createState() => _RequirementsQAScreenState();
}

class _RequirementsQAScreenState extends State<RequirementsQAScreen> {
  final List<ChatMessage> _messages = []; // List to store chat messages
  List<Map<String, dynamic>> _requirementsData = []; // Parsed requirements data
  final TextEditingController _messageController =
      TextEditingController(); // Input field controller
  final ScrollController _scrollController =
      ScrollController(); // List view scroll controller
  bool _isLoading = false; // Indicates if an AI operation is in progress
  bool _isInitializing =
      true; // Indicates if the screen is initially loading/parsing
  String _currentReqId = ''; // ID of the requirement currently being discussed
  int _currentQuestionIndex = 0; // Index of the requirement being reviewed

  @override
  void initState() {
    super.initState();
    // Check for API key on initialization
    _checkApiKeyAndInitialize();
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Checks if the API key is provided and starts the initialization process.
  Future<void> _checkApiKeyAndInitialize() async {
    _addSystemMessage("Checking API key and initializing...");
    // Check if API key is missing or is the placeholder value
    if (widget.mistralApiKey.isEmpty ||
        widget.mistralApiKey == "YOUR_MISTRAL_API_KEY") {
      _addSystemMessage(
          "Warning: Mistral API key is missing or uses the default placeholder. AI features (priority assignment, Q&A refinement) will be disabled. Please set the API key in main.dart.");
      // Parse requirements without AI priority assignment
      await _parseAndInitializeRequirements(assignPrioritiesWithAI: false);
      // Inform user and finish initialization
      _addAIMessage(
          "API key missing. Skipping AI refinement. You can proceed to Edit & Export.");
      if (mounted) {
        setState(() => _isInitializing = false); // Allow skipping
      }
    } else {
      // If API key seems valid, parse and assign priorities using AI
      await _parseAndInitializeRequirements(assignPrioritiesWithAI: true);
    }
  }

  // Parses the raw requirements string, optionally assigns priorities using AI.
  Future<void> _parseAndInitializeRequirements(
      {bool assignPrioritiesWithAI = true}) async {
    // Set initializing state only if not already done (e.g., after API key warning)
    if (mounted && _isInitializing) setState(() => _isInitializing = true);
    if (assignPrioritiesWithAI) {
      _addSystemMessage(
          "Parsing requirements and assigning initial priorities using AI...");
    } else {
      _addSystemMessage("Parsing requirements (AI priorities disabled)...");
    }

    try {
      // Split input text into lines and filter out empty ones
      List<String> rawRequirements = widget.extractedRequirements
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      int funcCounter = 1; // Counter for Functional requirement IDs
      int nonFuncCounter = 1; // Counter for Non-Functional requirement IDs
      List<Map<String, dynamic>> tempRequirements =
          []; // Temporary list to build data

      // Process each line to extract requirement details
      for (String req in rawRequirements) {
        String cleanReq = req.trim();
        // Remove common list markers (-, *, numbers)
        if (cleanReq.startsWith('- ') ||
            cleanReq.startsWith(
                '• ') || // Handle potential encoding issues like 'â€¢'
            cleanReq.startsWith('* ') ||
            RegExp(r'^\d+\.\s').hasMatch(cleanReq)) {
          // Match "1. ", "2. ", etc.
          cleanReq = cleanReq.substring(cleanReq.indexOf(' ') + 1).trim();
        }

        // Attempt to determine requirement type (Functional/Non-Functional)
        bool isFunctional = true; // Default to Functional
        String typePrefix = "";
        // Check for explicit prefixes
        if (cleanReq.toLowerCase().startsWith('functional:')) {
          typePrefix = 'functional:';
          isFunctional = true;
        } else if (cleanReq.toLowerCase().startsWith('non-functional:') ||
            cleanReq.toLowerCase().startsWith('nonfunctional:')) {
          // Capture the exact prefix used (e.g., "non-functional:")
          typePrefix =
              cleanReq.substring(0, cleanReq.toLowerCase().indexOf(':') + 1);
          isFunctional = false;
        }
        // Check for keywords within the text (often in parentheses)
        else if (cleanReq.toLowerCase().contains('non-functional') ||
            cleanReq.toLowerCase().contains('nonfunctional')) {
          isFunctional = false;
          // Remove the type indicator if found in parentheses, e.g., "(non-functional)"
          cleanReq = cleanReq
              .replaceAll(
                  RegExp(r'\((non-functional|nonfunctional)\)',
                      caseSensitive: false),
                  '')
              .trim();
        }

        // Remove the detected prefix (e.g., "Functional: ") from the requirement text
        if (typePrefix.isNotEmpty) {
          cleanReq = cleanReq.substring(typePrefix.length).trim();
        }

        // Generate a unique ID based on type and counter
        String reqId = isFunctional
            ? 'F-${funcCounter.toString().padLeft(3, '0')}' // e.g., F-001
            : 'NF-${nonFuncCounter.toString().padLeft(3, '0')}'; // e.g., NF-001

        // Increment the appropriate counter
        if (isFunctional) {
          funcCounter++;
        } else {
          nonFuncCounter++;
        }

        // Add the parsed requirement to the temporary list
        tempRequirements.add({
          'reqId': reqId,
          'type': isFunctional ? 'Functional' : 'Non-functional',
          'requirement': cleanReq,
          'notes': 'Initial extraction', // Default note
          'status': 'Pending QA', // Default status
          'priority':
              assignPrioritiesWithAI ? '?' : 'C', // Placeholder or default 'C'
        });
      }

      // Handle case where no requirements were extracted from the input text
      if (tempRequirements.isEmpty) {
        tempRequirements.add({
          'reqId': 'F-001', // Default ID
          'type': 'Functional', // Default type
          'requirement':
              'No specific requirements extracted. Please add manually or review input.',
          'notes': 'No requirements found',
          'status': 'Pending QA',
          'priority': 'C', // Default priority
        });
      }

      // Assign priorities using AI if enabled and requirements were found
      if (assignPrioritiesWithAI &&
          tempRequirements.isNotEmpty &&
          tempRequirements[0]['requirement']
                  ?.toLowerCase()
                  .contains('no specific requirements') !=
              true) {
        _addSystemMessage(
            "Assigning MoSCoW priorities (M/S/C/W)... This may take a moment.");
        List<Future<void>> priorityFutures =
            []; // List to hold async operations

        // Call AI for each requirement to get priority, with slight delay between calls
        for (int i = 0; i < tempRequirements.length; i++) {
          priorityFutures
              .add(Future.delayed(Duration(milliseconds: i * 150), () async {
            // Increased delay
            try {
              String priority = await _getRequirementPriority(
                  tempRequirements[i]['requirement'],
                  tempRequirements[i]['type']);
              tempRequirements[i]['priority'] = priority;
            } catch (e) {
              // If AI call fails, default to 'C' and notify user
              tempRequirements[i]['priority'] = 'C';
              _addSystemMessage(
                  "Could not assign priority for ${tempRequirements[i]['reqId']}, defaulting to 'C'. Error: ${e.toString().split(':').first}"); // Show concise error
            }
          }));
        }
        await Future.wait(priorityFutures); // Wait for all AI calls to complete
        _addSystemMessage('Initial priorities assigned by AI.');
      } else if (tempRequirements.isNotEmpty &&
          tempRequirements[0]['requirement']
                  ?.toLowerCase()
                  .contains('no specific requirements') !=
              true) {
        // If AI is disabled but reqs exist, notify that priorities defaulted to 'C'
        _addSystemMessage(
            "Defaulting all priorities to 'C' (AI assignment disabled).");
      }

      _requirementsData = tempRequirements; // Store the processed data

      _addSystemMessage(
          'Initial parsing complete. Displaying requirements list:');
      _displayRequirementsTable(); // CORRECTED: Ensure this call happens if desired (it was commented out)

      // Delay slightly before starting the interactive Q&A process
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return; // Check if widget is still mounted

      // Handle different scenarios after parsing
      if (_requirementsData.isNotEmpty &&
          _requirementsData[0]['requirement']
              ?.toLowerCase()
              .contains('no specific requirements')) {
        // Case: No requirements found in input
        _addAIMessage(
            "No requirements were extracted. Proceed to 'Edit & Export' to add them manually.");
      } else if (_requirementsData.isNotEmpty && assignPrioritiesWithAI) {
        // Case: Requirements found, AI enabled -> Start Q&A
        _askNextQuestion();
      } else if (_requirementsData.isNotEmpty && !assignPrioritiesWithAI) {
        // Case: Requirements found, AI disabled -> Skip Q&A
        _addAIMessage(
            "Skipping AI refinement (API key missing/invalid). Proceed to 'Edit & Export'.");
      }
      // Finish the initialization phase
      setState(() => _isInitializing = false);
    } catch (e, stacktrace) {
      // Handle any errors during initialization
      _addSystemMessage('Error initializing requirements: $e');
      print('Requirements initialization error: $e\n$stacktrace');
      if (mounted) {
        setState(() => _isInitializing =
            false); // Ensure initialization state is turned off
      }
    }
  }

  // Calls the Mistral API to determine the MoSCoW priority for a requirement.
  Future<String> _getRequirementPriority(
      String requirementText, String type) async {
    // Prevent API call if key is missing (already checked in calling function, but double-check)
    if (widget.mistralApiKey.isEmpty ||
        widget.mistralApiKey == "YOUR_MISTRAL_API_KEY") {
      return 'C'; // Default if key is missing
    }

    // Construct the prompt for the AI
    final String prompt = """
You are an expert Product Manager applying the MoSCoW prioritization method.
Analyze the following requirement and assign a priority:
M = Must have (Critical, essential for the core purpose)
S = Should have (Important, but not critical for launch)
C = Could have (Nice-to-have, desirable but not necessary)
W = Won't have (Explicitly out of scope for this iteration/version)

Requirement Type: $type
Requirement Text: "$requirementText"

Based on common software development practices, determine the most likely MoSCoW priority. Consider the impact, necessity, and potential deferral of the requirement.

Return ONLY the single capital letter: M, S, C, or W. Do not add any other text or explanation.
""";

    try {
      String result = await _runMistralApiCall(prompt);
      // Clean the result to ensure only a single valid letter (M, S, C, W) is returned
      result = result.replaceAll(RegExp(r'[^MSCW]'), '').trim();

      // Validate the result and return, or default to 'C'
      if (result.length == 1 && 'MSCW'.contains(result)) {
        return result;
      } else {
        print(
            "Invalid priority response from AI: '$result', defaulting to 'C'");
        return 'C';
      }
    } catch (e) {
      // Handle API call errors, default to 'C'
      print("Error getting priority from AI: $e, defaulting to 'C'");
      return 'C';
    }
  }

  // Generates a Markdown formatted table and adds it as a system message.
  // This method was requested to be fixed, assuming it should be defined here.
  void _displayRequirementsTable() {
    if (!mounted) return;
    String markdownTable = _generateMarkdownTable();
    _addSystemMessage(markdownTable);
  }

  // Generates a Markdown formatted table string of the current requirements.
  String _generateMarkdownTable() {
    // Start table header
    String table = '**Current Requirements List:**\n\n';
    table +=
        '| Req ID | Priority | Type | Requirement Snippet | Notes | Status |\n';
    table +=
        '|:-------|:---------|:---------------|:------------------------|:-----------------------|:-----------|\n';

    // Add a row for each requirement
    for (var req in _requirementsData) {
      String reqText = req['requirement']?.toString() ?? '';
      String notesText = req['notes']?.toString() ?? '';
      // Truncate long text for display in the table
      if (reqText.length > 35) reqText = '${reqText.substring(0, 32)}...';
      if (notesText.length > 20) notesText = '${notesText.substring(0, 17)}...';
      // Escape pipe characters '|' to prevent breaking Markdown table format
      reqText = reqText.replaceAll('|', r'\|');
      notesText = notesText.replaceAll('|', r'\|');

      // Add row data
      table +=
          '| ${req['reqId']} | ${req['priority'] ?? '?'} | ${req['type']} | $reqText | $notesText | ${req['status']} |\n';
    }
    return table;
  }

  // Adds a system message (e.g., notifications, errors) to the chat.
  void _addSystemMessage(String message) {
    if (!mounted) return; // Check if widget is still in the tree
    setState(() => _messages.add(ChatMessage(
        text: message, isUserMessage: false, isSystemMessage: true)));
    _scrollToBottom(); // Scroll to show the new message
  }

  // Adds an AI message to the chat.
  void _addAIMessage(String message) {
    if (!mounted) return;
    setState(
        () => _messages.add(ChatMessage(text: message, isUserMessage: false)));
    _scrollToBottom();
  }

  // Adds a user message to the chat.
  void _addUserMessage(String message) {
    if (!mounted) return;
    setState(
        () => _messages.add(ChatMessage(text: message, isUserMessage: true)));
    _scrollToBottom();
  }

  // Scrolls the chat list to the bottom.
  void _scrollToBottom() {
    // Use addPostFrameCallback to ensure scroll happens after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Check if scroll controller is attached
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, // Scroll to the very end
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Asks the AI for a follow-up question about the current requirement.
  Future<void> _askNextQuestion() async {
    // Check API key validity before proceeding
    if (widget.mistralApiKey.isEmpty ||
        widget.mistralApiKey == "YOUR_MISTRAL_API_KEY") {
      // This case should ideally be handled by the initialization logic already
      _addAIMessage(
          "Cannot ask follow-up questions (API key missing). Proceed to Edit & Export.");
      if (mounted) setState(() => _isLoading = false);
      _navigateToExcelEditor(); // Navigate away as Q&A cannot proceed
      return;
    }

    // Check if all requirements have been reviewed
    if (_currentQuestionIndex >= _requirementsData.length) {
      _addAIMessage(
          'All requirements reviewed. Proceeding to the editor screen.');
      if (mounted) setState(() => _isLoading = false);
      _navigateToExcelEditor(); // Navigate to the next screen
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true); // Show loading indicator

    try {
      // Get the current requirement data
      Map<String, dynamic> currentReq =
          _requirementsData[_currentQuestionIndex];
      _currentReqId =
          currentReq['reqId']; // Store current ID for reply handling

      // Construct the prompt for the AI to generate a question
      String prompt = """
You are a requirements analyst focusing on creating SMART (Specific, Measurable, Achievable, Relevant, Time-bound) requirements.
Generate ONE specific, open-ended follow-up question about the requirement below to help clarify or improve it. Focus on ambiguities or missing details.

Requirement ID: ${currentReq['reqId']}
Type: ${currentReq['type']}
Priority: ${currentReq['priority']}
Requirement Text: "${currentReq['requirement']}"

Your question should aim to uncover ONE of the following:
- Missing specific details (e.g., What specific metrics define 'user-friendly'?)
- Ambiguities (e.g., What exactly constitutes 'fast' performance?)
- Acceptance criteria (e.g., How will we verify this is completed correctly?)
- Edge cases or constraints (e.g., Does this apply to all user roles?)

Return ONLY the specific question text. Do not add introductions like "Here's a question:" or explanations.
Keep the question concise and focused.
Examples of good questions:
- What specific response time threshold should be met?
- Under which specific conditions should this notification appear?
- How will 'ease of use' be measured or tested?
- Are there any user roles excluded from this functionality?

Question:
""";

      String question = await _runMistralApiCall(prompt);
      // Clean up potential prefix (like "Question:") from the AI response
      question = question
          .replaceFirst(RegExp(r'^Question:\s*', caseSensitive: false), "")
          .trim();
      // Ensure the question isn't empty after cleaning
      if (question.isEmpty)
        question = "Can you provide more details or clarify this requirement?";

      // Display the requirement context and the AI's question to the user
      _addAIMessage(
          'Requirement **${currentReq['reqId']}** (Priority: ${currentReq['priority']}):\n*\"${currentReq['requirement']}\"*\n\n$question');

      if (mounted) setState(() => _isLoading = false); // Hide loading indicator
    } catch (e) {
      // Handle errors during question generation
      if (mounted) setState(() => _isLoading = false);
      _addSystemMessage(
          'Error generating question for $_currentReqId: ${e.toString().split(':').first}. Moving to the next requirement.');
      // Move to the next requirement automatically on error
      _currentQuestionIndex++;
      Future.delayed(const Duration(seconds: 1), _askNextQuestion);
    }
  }

  // Processes the user's reply, updates the requirement using AI, and moves to the next question.
  Future<void> _sendUserReply(String message) async {
    if (message.trim().isEmpty) return; // Ignore empty messages
    _addUserMessage(message); // Add user's message to chat
    _messageController.clear(); // Clear the input field
    if (!mounted) return;

    // Check API key validity before proceeding with AI calls
    if (widget.mistralApiKey.isEmpty ||
        widget.mistralApiKey == "YOUR_MISTRAL_API_KEY") {
      _addAIMessage(
          "Cannot process reply with AI (API key missing). Moving to next step.");
      // Move to the next requirement without AI processing
      _currentQuestionIndex++;
      Future.delayed(const Duration(milliseconds: 500), _askNextQuestion);
      return;
    }

    setState(() => _isLoading = true); // Show loading indicator

    try {
      // Find the index of the requirement being discussed
      int reqIndex =
          _requirementsData.indexWhere((req) => req['reqId'] == _currentReqId);
      if (reqIndex == -1) {
        throw Exception(
            'Could not find the current requirement being updated ($_currentReqId)');
      }

      Map<String, dynamic> currentReq = _requirementsData[reqIndex];
      String oldRequirement = currentReq['requirement'];
      // Get the last question asked by the AI (to provide context)
      String lastAIQuestion = "Could you provide more detail?"; // Fallback
      // Find the last non-user, non-system message
      final aiMessages = _messages
          .where((m) => !m.isUserMessage && m.isSystemMessage != true)
          .toList();
      if (aiMessages.isNotEmpty) {
        // Extract the question part (usually after the context)
        final parts = aiMessages.last.text.split('\n\n');
        if (parts.length > 1) lastAIQuestion = parts.last;
      }

      // Prompt for integrating the user's reply into the requirement text
      String updatePrompt = """
You are a requirements analyst. A user has provided an answer/clarification to a question about a requirement.

Requirement ID: ${currentReq['reqId']}
Type: ${currentReq['type']}
Current Requirement Text: "${oldRequirement}"

Question Asked: "$lastAIQuestion"
User's Reply: "$message"

Task: Carefully integrate the user's reply into the current requirement text to make it more specific, clear, or complete.
- If the reply adds details, incorporate them smoothly.
- If the reply clarifies ambiguity, rephrase the relevant part.
- If the reply confirms something or says no change is needed, you can make minimal edits or return the original text if appropriate.
- Focus on improving the requirement based *only* on the user's reply.
- Maintain the original intent and format where possible.

Return ONLY the updated requirement text. Do not add explanations, introductions, or any other text.
""";

      String updatedRequirement = await _runMistralApiCall(updatePrompt);
      // Fallback to old requirement if the API returns empty or whitespace
      if (updatedRequirement.trim().isEmpty) {
        updatedRequirement = oldRequirement;
        _addSystemMessage(
            "AI returned empty update, keeping original requirement text.");
      }

      // Prompt for generating a concise note about the update based on the change
      String notePrompt = """
Analyze the change between the original and updated requirement based on the user's reply.
- Original: "${oldRequirement}"
- Reply: "$message"
- Updated: "$updatedRequirement"

Describe the main change concisely (5-10 words). Examples: "Added response time metric.", "Clarified user role.", "Specified data format.", "Confirmed existing details.", "No significant change made.".
Return ONLY the brief note.
""";
      String updateNote = "Updated based on Q&A"; // Default note
      // Only generate note if the requirement actually changed
      if (updatedRequirement.trim() != oldRequirement.trim()) {
        try {
          updateNote = await _runMistralApiCall(notePrompt);
          // Clean up potential prefixes
          updateNote = updateNote
              .replaceFirst(
                  RegExp(r'^(Note:|Update:|Confirmation:)\s*',
                      caseSensitive: false),
                  "")
              .trim();
          // Fallback if API returns empty note after cleaning
          if (updateNote.isEmpty) updateNote = "Updated based on Q&A";
        } catch (noteError) {
          print("Error generating update note: $noteError");
          // Use default note if generation fails
        }
      } else {
        updateNote = "Confirmed via Q&A"; // Note for no change
      }

      // Update the requirement data locally if the widget is still mounted
      if (!mounted) return;
      setState(() {
        _requirementsData[reqIndex]['requirement'] = updatedRequirement.trim();
        _requirementsData[reqIndex]['notes'] = updateNote.trim();
        _requirementsData[reqIndex]['status'] = 'Updated'; // Mark as updated
        _isLoading = false; // Hide loading indicator
      });

      // Confirm the update to the user
      _addAIMessage(
          'Requirement ${currentReq['reqId']} updated:\n*"${updatedRequirement.trim()}"*');
      // _displayRequirementsTable(); // Optional: Show updated table in chat

      // Move to the next requirement after a short delay
      _currentQuestionIndex++;
      Future.delayed(const Duration(milliseconds: 600), _askNextQuestion);
    } catch (e) {
      // Handle errors during reply processing
      if (mounted) setState(() => _isLoading = false);
      _addSystemMessage(
          'Error processing reply for $_currentReqId: ${e.toString().split(':').first}. Moving to the next requirement.');
      // Move to the next requirement automatically on error
      _currentQuestionIndex++;
      Future.delayed(const Duration(seconds: 1), _askNextQuestion);
    }
  }

  // Displays a temporary message at the bottom of the screen.
  void _showSnackBar(String message) {
    if (!mounted) return; // Check if widget is still mounted
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating, // Make it float
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(8)),
    );
  }

  // Makes an API call to the Mistral AI service.
  Future<String> _runMistralApiCall(String prompt) async {
    // Double-check API key validity
    if (widget.mistralApiKey.isEmpty ||
        widget.mistralApiKey == "YOUR_MISTRAL_API_KEY") {
      throw Exception("Mistral API Key is missing or invalid.");
    }
    // API endpoint
    final url = Uri.parse('https://api.mistral.ai/v1/chat/completions');
    // Request headers including Authorization
    final headers = {
      'Content-Type':
          'application/json; charset=utf-8', // Ensure UTF-8 encoding
      'Accept': 'application/json',
      'Authorization': 'Bearer ${widget.mistralApiKey}', // API Key
    };
    // Request body
    final body = jsonEncode({
      'model': 'mistral-small-latest', // Specify the Mistral model
      'messages': [
        {'role': 'user', 'content': prompt}
      ], // User prompt
      'temperature': 0.2, // Lower temperature for more deterministic output
      'max_tokens':
          200, // Increased token limit for potentially longer req text
      'response_format': {'type': 'text'}, // Request plain text response
    });

    try {
      // Make the POST request with a timeout
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 45));

      // Decode response body using UTF-8
      final responseBody = utf8.decode(response.bodyBytes);

      // Check response status code
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);
        // Safely extract the AI's message content from the response structure
        if (data.containsKey('choices') &&
            data['choices'] is List &&
            data['choices'].isNotEmpty &&
            data['choices'][0].containsKey('message') &&
            data['choices'][0]['message'].containsKey('content')) {
          return data['choices'][0]['message']['content'].trim();
        } else {
          // Handle unexpected successful response format
          print("Unexpected API response format (200 OK): $data");
          throw Exception('Unexpected API response format.');
        }
      } else {
        // Handle API errors (non-200 status codes)
        String errorMessage = 'Mistral API Error ${response.statusCode}.';
        try {
          // Attempt to parse error details from the response body
          final errorData = json.decode(responseBody);
          if (errorData.containsKey('error') &&
              errorData['error'] is Map &&
              errorData['error'].containsKey('message')) {
            errorMessage += ' ${errorData['error']['message']}';
          } else if (errorData.containsKey('message')) {
            // Sometimes error is directly in 'message'
            errorMessage += ' ${errorData['message']}';
          } else if (responseBody.isNotEmpty) {
            errorMessage +=
                ' Response: $responseBody'; // Include raw response if parsing fails
          }
        } catch (_) {
          // If error body parsing fails, include the raw response
          errorMessage += ' Could not decode error body. Raw: $responseBody';
        }
        print("API Error Details: $errorMessage"); // Log detailed error
        // Provide a more user-friendly error message, hiding specifics
        throw Exception(
            'Failed to get response from AI service (Code ${response.statusCode}). Please check your API key and connection.');
      }
    } on TimeoutException catch (_) {
      // Handle request timeout
      throw Exception('The AI request timed out. Please try again.');
    } on http.ClientException catch (e) {
      // Handle network/connection errors
      throw Exception('Network error connecting to AI service: ${e.message}');
    } catch (e) {
      // Catch any other unexpected errors
      String errorMsg = e.toString();
      // Mask API key if it appears in the error message
      errorMsg = errorMsg.replaceAll(widget.mistralApiKey, "[API_KEY_HIDDEN]");
      print("Unhandled API call error: $errorMsg"); // Log the error
      // Re-throw as a generic exception
      throw Exception(
          'An unexpected error occurred while communicating with the AI service.');
    }
  }

  // Skips the remaining Q&A and navigates to the editor screen.
  void _skipToExport() {
    if (!mounted) return;
    _addSystemMessage(
        "Skipping remaining Q&A. Navigating to the editor/export screen.");
    // Mark any remaining requirements with 'Pending QA' status as 'Skipped QA'
    for (int i = _currentQuestionIndex; i < _requirementsData.length; i++) {
      if (_requirementsData[i]['status'] == 'Pending QA') {
        _requirementsData[i]['status'] = 'Skipped QA';
      }
    }
    // Update state to reflect Q&A finished and navigate
    if (mounted) {
      setState(() {
        _isLoading = false; // Ensure loading indicator is off
        _currentQuestionIndex =
            _requirementsData.length; // Mark Q&A process as finished
      });
    }
    _navigateToExcelEditor(); // Navigate to the next screen
  }

  // Navigates to the RequirementsManager screen, replacing the current QA screen.
  void _navigateToExcelEditor() {
    if (!mounted) return;
    // Pass a deep copy of the potentially modified requirements data
    final currentData = List<Map<String, dynamic>>.from(
        _requirementsData.map((row) => Map<String, dynamic>.from(row)));
    // Use pushReplacement to remove the QA screen from the navigation stack
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                RequirementsManager(requirementsData: currentData)));
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the Q&A process is finished, skipped (due to missing API key), or still initializing
    final bool isQASkippedOrFinished =
        (_currentQuestionIndex >= _requirementsData.length ||
                (widget.mistralApiKey.isEmpty ||
                    widget.mistralApiKey == "YOUR_MISTRAL_API_KEY")) &&
            !_isInitializing;
    // Show input area only if Q&A is active (not finished/skipped and not initializing)
    final bool showInputArea = !isQASkippedOrFinished && !_isInitializing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requirements Q&A Refinement'),
        actions: [
          // Button to skip Q&A and go directly to the editor/export screen
          TextButton.icon(
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Edit & Export'),
            // Disable button during initialization
            onPressed: (_isInitializing) ? null : _skipToExport,
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Chat Message List ---
          Expanded(
            child: ListView.builder(
              controller:
                  _scrollController, // Controller for automatic scrolling
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _messages[index], // Build each message
            ),
          ),
          // --- Loading Indicator ---
          // Shown during initialization or when waiting for AI response
          if (_isLoading || _isInitializing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary))),
                  const SizedBox(width: 10),
                  Text(
                      _isInitializing
                          ? 'Initializing...'
                          : 'AI is thinking...', // Dynamic text
                      style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7),
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          // --- User Input Area ---
          // Shown only when Q&A is active
          if (showInputArea)
            Container(
              // Styling for the input area container
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                    top: BorderSide(
                        color: Theme.of(context).dividerColor, width: 1.0)),
              ),
              // Padding, including adjustment for keyboard/safe area at the bottom
              padding: EdgeInsets.only(
                  left: 16,
                  right: 8,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 8),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end, // Align items to bottom
                children: [
                  // --- Text Input Field ---
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isLoading
                            ? 'Waiting for AI...'
                            : 'Type your answer or clarification...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        // Style for borderless, filled input field
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.5),
                      ),
                      maxLines: 5, // Allow multi-line input up to 5 lines
                      minLines: 1,
                      textInputAction:
                          TextInputAction.newline, // Allow newline input
                      enabled:
                          !_isLoading, // Disable field while AI is processing
                      // Send message on keyboard submit action
                      onSubmitted: (value) {
                        if (!_isLoading && value.trim().isNotEmpty) {
                          _sendUserReply(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // --- Send Button ---
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 2), // Align with text field baseline
                    child: FloatingActionButton(
                      onPressed: _isLoading
                          ? null
                          : () => _sendUserReply(_messageController
                              .text), // Disable button while loading
                      elevation: 1,
                      mini: true, // Make button smaller
                      tooltip: 'Send Reply',
                      backgroundColor: _isLoading
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          // --- Proceed Button ---
          // Shown when Q&A is finished or skipped
          if (isQASkippedOrFinished && !_isInitializing)
            Padding(
              padding: EdgeInsets.all(16.0) +
                  EdgeInsets.only(
                      bottom: MediaQuery.of(context)
                          .padding
                          .bottom), // Padding + safe area
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_document),
                label: const Text('Proceed to Edit & Export'),
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, 50), // Full width button
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: _navigateToExcelEditor, // Navigate on press
              ),
            )
        ],
      ),
    );
  }
}

// --- MAIN REQUIREMENTS MANAGER SCREEN ---
// Screen for viewing, editing, filtering, sorting, exporting, and importing requirements.
class RequirementsManager extends StatefulWidget {
  final List<Map<String, dynamic>>
      requirementsData; // Initial data passed from QAScreen or main

  const RequirementsManager({super.key, required this.requirementsData});

  @override
  State<RequirementsManager> createState() => _RequirementsManagerState();
}

class _RequirementsManagerState extends State<RequirementsManager> {
  List<Map<String, dynamic>> _requirements =
      []; // Main list of all requirements
  List<Map<String, dynamic>> _filteredRequirements =
      []; // List displayed after filtering/sorting
  final TextEditingController _searchController =
      TextEditingController(); // Controller for search field
  String _searchQuery = ''; // Current search query
  bool _isExporting = false; // Loading state for export
  bool _isUploading = false; // Loading state for Firebase upload/import/listing
  bool _isSaved = true; // Tracks if there are unsaved changes
  String _filterType = 'All'; // Current type filter selection
  String _filterPriority = 'All'; // Current priority filter selection
  String _filterStatus = 'All'; // Current status filter selection
  String _sortBy = 'reqId'; // Column to sort by
  bool _sortAscending = true; // Sort direction

  // Firebase storage reference
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _initializeRequirementsData(); // Load and normalize initial data
    _searchController.addListener(() {
      // Update search query when controller changes
      if (mounted && _searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _applyFiltersAndSort();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose search controller
    super.dispose();
  }

  // Initializes and normalizes the requirements data received from the widget.
  void _initializeRequirementsData() {
    // Create a deep copy to avoid modifying the original widget data
    _requirements = List<Map<String, dynamic>>.from(
        widget.requirementsData.map((row) => Map<String, dynamic>.from(row)));

    // Ensure all required fields exist and have valid/default values
    for (var req in _requirements) {
      // --- Priority Validation ---
      var priority = req['priority']?.toString().toUpperCase();
      // Allow '?' temporarily if coming from QA, default to 'C' otherwise or if invalid
      if (priority == null || !['M', 'S', 'C', 'W', '?'].contains(priority)) {
        req['priority'] = 'C'; // Default for invalid/missing
      } else if (priority == '?') {
        req['priority'] = 'C'; // Convert placeholder '?' to 'C'
      } else {
        req['priority'] = priority; // Keep valid uppercase value
      }

      // --- Type Default ---
      req['type'] =
          req['type'] ?? 'Functional'; // Default to 'Functional' if missing

      // --- Status Default ---
      req['status'] = req['status'] ?? 'New'; // Default to 'New' if missing

      // --- Notes Default ---
      req['notes'] =
          req['notes'] ?? ''; // Ensure notes field exists (can be empty)
    }

    _applyFiltersAndSort(); // Apply initial filters and sorting
  }

  // Applies the current search query, filters, and sorting to the requirements list.
  void _applyFiltersAndSort() {
    // Start with the full list
    List<Map<String, dynamic>> filtered = List.from(_requirements);

    // --- Apply Search Query Filter --- (Case-insensitive)
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      filtered = filtered.where((req) {
        // Concatenate searchable fields into a single string for searching
        final content =
            '${req['reqId']} ${req['requirement']} ${req['notes']} ${req['type']} ${req['status']}'
                .toLowerCase();
        return content
            .contains(queryLower); // Check if content includes search query
      }).toList();
    }

    // --- Apply Type Filter ---
    if (_filterType != 'All') {
      filtered = filtered.where((req) => req['type'] == _filterType).toList();
    }

    // --- Apply Priority Filter ---
    if (_filterPriority != 'All') {
      filtered =
          filtered.where((req) => req['priority'] == _filterPriority).toList();
    }

    // --- Apply Status Filter ---
    if (_filterStatus != 'All') {
      filtered =
          filtered.where((req) => req['status'] == _filterStatus).toList();
    }

    // --- Apply Sorting ---
    filtered.sort((a, b) {
      var aValue = a[_sortBy]; // Value from item A for the sort column
      var bValue = b[_sortBy]; // Value from item B for the sort column

      // Handle potential null values during comparison (nulls first in ascending)
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return _sortAscending ? -1 : 1;
      if (bValue == null) return _sortAscending ? 1 : -1;

      int result;
      // Use case-insensitive comparison for strings
      if (aValue is String && bValue is String) {
        result = aValue.toLowerCase().compareTo(bValue.toLowerCase());
      }
      // Default comparison using toString() for other types
      else {
        result = aValue.toString().compareTo(bValue.toString());
      }

      // Apply sort direction (ascending or descending)
      return _sortAscending ? result : -result;
    });

    // Update the state with the filtered and sorted list if the widget is mounted
    if (mounted) {
      setState(() {
        _filteredRequirements = filtered;
      });
    }
  }

  // Adds a new, empty requirement row and opens the edit dialog.
  void _addNewRequirement() {
    // Generate a new unique requirement ID (simple increment based on type)
    int highestF = 0;
    int highestNF = 0;
    // Find the highest existing ID number for each type
    for (var row in _requirements) {
      String? reqId = row['reqId']?.toString();
      if (reqId != null) {
        if (reqId.startsWith('F-')) {
          int num = int.tryParse(reqId.substring(2)) ?? 0;
          if (num > highestF) highestF = num;
        } else if (reqId.startsWith('NF-')) {
          int num = int.tryParse(reqId.substring(3)) ?? 0;
          if (num > highestNF) highestNF = num;
        }
      }
    }
    // Create the next ID, defaulting to Functional type
    // TODO: Consider allowing user choice of type for new req
    String newId = 'F-${(highestF + 1).toString().padLeft(3, '0')}';

    // Create a new requirement map with default values
    Map<String, dynamic> newRequirement = {
      'reqId': newId,
      'priority': 'C', // Default priority: Could Have
      'type': 'Functional', // Default type
      'requirement': 'Enter new requirement details...', // Placeholder text
      'notes': '',
      'status': 'New', // Default status
    };

    // Show the edit dialog for this new requirement
    _showRequirementEditDialog(newRequirement, isNew: true);
  }

  // Opens the edit dialog for an existing requirement.
  void _editRequirement(Map<String, dynamic> requirement) {
    // Create a deep copy to avoid modifying the list directly until saved in the dialog
    final reqCopy = Map<String, dynamic>.from(requirement);
    _showRequirementEditDialog(reqCopy, isNew: false);
  }

  // Deletes a requirement after showing a confirmation dialog.
  void _deleteRequirement(Map<String, dynamic> requirement) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete requirement ${requirement['reqId']}? This cannot be undone.'),
        actions: [
          TextButton(
            // Cancel button
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            // Confirm delete button
            onPressed: () {
              Navigator.of(context).pop(); // Close the confirmation dialog
              if (mounted) {
                setState(() {
                  // Remove the requirement from the main list using its ID
                  _requirements.removeWhere(
                      (req) => req['reqId'] == requirement['reqId']);
                  _applyFiltersAndSort(); // Refresh the filtered/sorted list
                  _isSaved = false; // Mark that changes have been made
                });
              }
              _showSnackBar('Requirement deleted',
                  isError: false); // Show success message
            },
            // Style delete button text red for emphasis
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Shows a dialog to edit or create a requirement.
  void _showRequirementEditDialog(Map<String, dynamic> requirement,
      {required bool isNew}) {
    if (!mounted) return;
    // Create text controllers for editable fields, pre-filled with current data
    final requirementController = TextEditingController(
        text: requirement['requirement']?.toString() ?? '');
    final notesController =
        TextEditingController(text: requirement['notes']?.toString() ?? '');

    // Hold dropdown values locally within the dialog state using StatefulBuilder
    String priority = requirement['priority']?.toString() ?? 'C';
    String type = requirement['type']?.toString() ?? 'Functional';
    String status = requirement['status']?.toString() ?? 'New';

    showDialog(
      context: context,
      // Use StatefulBuilder to manage local state changes (like dropdown selections) within the dialog
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          // Dialog title depends on whether it's a new or existing requirement
          title: Text(isNew
              ? 'Add New Requirement'
              : 'Edit Requirement ${requirement['reqId']}'),
          // Use SingleChildScrollView to prevent overflow if content is tall
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Make column height fit content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Requirement ID (Read-only) ---
                Text('ID: ${requirement['reqId']}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // --- Priority Dropdown ---
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Priority', border: OutlineInputBorder()),
                  value: priority, // Current selection
                  items: const [
                    // MoSCoW options
                    DropdownMenuItem(value: 'M', child: Text('M - Must Have')),
                    DropdownMenuItem(
                        value: 'S', child: Text('S - Should Have')),
                    DropdownMenuItem(value: 'C', child: Text('C - Could Have')),
                    DropdownMenuItem(
                        value: 'W', child: Text('W - Won\'t Have')),
                  ],
                  // Update local dialog state when selection changes
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        priority = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // --- Type Dropdown ---
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Type', border: OutlineInputBorder()),
                  value: type,
                  items: const [
                    // Functional/Non-Functional options
                    DropdownMenuItem(
                        value: 'Functional', child: Text('Functional')),
                    DropdownMenuItem(
                        value: 'Non-Functional', child: Text('Non-Functional')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        type = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // --- Requirement Text Field ---
                TextField(
                  controller: requirementController, // Use controller
                  decoration: const InputDecoration(
                      labelText: 'Requirement',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true),
                  maxLines: 3, // Allow multiple lines
                  minLines: 1,
                ),
                const SizedBox(height: 16),

                // --- Notes Text Field ---
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true),
                  maxLines: 2,
                  minLines: 1,
                ),
                const SizedBox(height: 16),

                // --- Status Dropdown ---
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Status', border: OutlineInputBorder()),
                  value: status,
                  items: const [
                    // Status options
                    DropdownMenuItem(value: 'New', child: Text('New')),
                    DropdownMenuItem(value: 'Updated', child: Text('Updated')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'Completed', child: Text('Completed')),
                    DropdownMenuItem(
                        value: 'Rejected', child: Text('Rejected')),
                    DropdownMenuItem(
                        value: 'Skipped QA',
                        child: Text('Skipped QA')), // Status for skipped items
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        status = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              // Cancel button
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              // Save/Add button
              onPressed: () {
                // Update the requirement map with the final values from controllers/dropdowns
                requirement['priority'] = priority;
                requirement['type'] = type;
                requirement['requirement'] =
                    requirementController.text.trim(); // Trim whitespace
                requirement['notes'] = notesController.text.trim();
                requirement['status'] = status;

                // Check mount status before calling setState
                if (mounted) {
                  setState(() {
                    if (isNew) {
                      // Add the new requirement to the main list
                      _requirements.add(requirement);
                    } else {
                      // Find and update the existing requirement in the main list
                      int index = _requirements.indexWhere(
                          (req) => req['reqId'] == requirement['reqId']);
                      if (index >= 0) {
                        _requirements[index] =
                            requirement; // Replace with updated data
                      } else {
                        print(
                            "Error: Could not find requirement ${requirement['reqId']} to update.");
                        _requirements.add(
                            requirement); // Add if somehow missing (fallback)
                      }
                    }
                    _isSaved = false; // Mark that changes are unsaved
                  });
                }

                _applyFiltersAndSort(); // Refresh the list view
                Navigator.of(context).pop(); // Close the dialog
                _showSnackBar(
                    isNew ? 'New requirement added!' : 'Requirement updated',
                    isError: false); // Show confirmation
              },
              // Button label depends on whether adding or editing
              child: Text(isNew ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Marks the current state as saved (usually after user clicks save button).
  void _saveChanges() {
    if (mounted) {
      setState(() {
        _isSaved = true; // Set saved flag
      });
    }
    _showSnackBar('Changes marked as saved',
        isError: false); // Show confirmation
  }

  // Shows a dialog for selecting filter options (Type, Priority, Status).
  void _showFilterDialog() {
    if (!mounted) return;
    // Get unique values from the current requirements data for dropdown options
    // Start with 'All' option for each filter
    final Set<String> types = {
      'All',
      ..._requirements
          .map((req) => req['type'].toString())
          .where((t) => t.isNotEmpty)
    };
    final Set<String> statuses = {
      'All',
      ..._requirements
          .map((req) => req['status'].toString())
          .where((s) => s.isNotEmpty)
    };

    // Temporary variables to hold selected values within the dialog state
    String tempFilterType = _filterType;
    String tempFilterPriority = _filterPriority;
    String tempFilterStatus = _filterStatus;

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
              // Use StatefulBuilder for dialog's local state
              builder: (context, setDialogState) => AlertDialog(
                title: const Text('Filter Requirements'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Type Filter Dropdown ---
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: 'Filter by Type',
                            border: OutlineInputBorder()),
                        value: tempFilterType,
                        // Use dynamically generated list of unique types + 'All'
                        items: types
                            .map((type) => DropdownMenuItem(
                                value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              tempFilterType = value;
                            }); // Update dialog state
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- Priority Filter Dropdown ---
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: 'Filter by Priority',
                            border: OutlineInputBorder()),
                        value: tempFilterPriority,
                        // Fixed list of priorities + 'All'
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(
                              value: 'M', child: Text('M - Must Have')),
                          DropdownMenuItem(
                              value: 'S', child: Text('S - Should Have')),
                          DropdownMenuItem(
                              value: 'C', child: Text('C - Could Have')),
                          DropdownMenuItem(
                              value: 'W', child: Text('W - Won\'t Have')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              tempFilterPriority = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- Status Filter Dropdown ---
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: 'Filter by Status',
                            border: OutlineInputBorder()),
                        value: tempFilterStatus,
                        // Use dynamically generated list of unique statuses + 'All'
                        items: statuses
                            .map((status) => DropdownMenuItem(
                                value: status, child: Text(status)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              tempFilterStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    // Cancel button
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    // Apply filters button
                    onPressed: () {
                      // Apply the selected filters from the dialog to the main screen state
                      if (mounted) {
                        setState(() {
                          _filterType = tempFilterType;
                          _filterPriority = tempFilterPriority;
                          _filterStatus = tempFilterStatus;
                          // Filtering doesn't necessarily mean changes need saving, so _isSaved remains unchanged.
                        });
                      }
                      _applyFiltersAndSort(); // Refresh the list with new filters applied
                      Navigator.of(context).pop(); // Close the filter dialog
                    },
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ));
  }

  // Shows a dialog for selecting sorting options (column and direction).
  void _showSortDialog() {
    if (!mounted) return;
    // Temporary variables to hold selected sort options within the dialog
    String tempSortBy = _sortBy;
    bool tempSortAscending = _sortAscending;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Use StatefulBuilder for dialog's state management
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sort Requirements'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Sort Column Selector Dropdown ---
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Sort By', border: OutlineInputBorder()),
                  value: tempSortBy,
                  items: const [
                    // Define sortable columns
                    DropdownMenuItem(
                        value: 'reqId', child: Text('Requirement ID')),
                    DropdownMenuItem(
                        value: 'priority', child: Text('Priority')),
                    DropdownMenuItem(value: 'type', child: Text('Type')),
                    DropdownMenuItem(value: 'status', child: Text('Status')),
                    DropdownMenuItem(
                        value: 'requirement',
                        child:
                            Text('Requirement Text')), // Allow sorting by text
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        tempSortBy = value;
                      }); // Update dialog state
                    }
                  },
                ),
                const SizedBox(height: 16),

                // --- Sort Direction Radio Buttons ---
                Row(
                  // Layout radio buttons horizontally
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Order: '),
                    Radio<bool>(
                      value: true, // Represents Ascending
                      groupValue: tempSortAscending, // Current selection
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            tempSortAscending = value;
                          }); // Update dialog state
                        }
                      },
                    ),
                    const Text('Asc'), // Concise label
                    const SizedBox(width: 10),
                    Radio<bool>(
                      value: false, // Represents Descending
                      groupValue: tempSortAscending,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            tempSortAscending = value;
                          });
                        }
                      },
                    ),
                    const Text('Desc'), // Concise label
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              // Cancel button
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              // Apply sort button
              onPressed: () {
                // Apply selected sort options from dialog to the main screen state
                if (mounted) {
                  setState(() {
                    _sortBy = tempSortBy;
                    _sortAscending = tempSortAscending;
                    // Sorting doesn't necessarily mean changes need saving, so _isSaved remains unchanged.
                  });
                }
                _applyFiltersAndSort(); // Refresh the list with new sorting applied
                Navigator.of(context).pop(); // Close the sort dialog
              },
              child: const Text('Apply Sort'),
            ),
          ],
        ),
      ),
    );
  }

  // Exports the current requirements data to an Excel file and initiates sharing.
  Future<void> _exportToExcel() async {
    // Check for unsaved changes before exporting
    if (!_isSaved) {
      _showUnsavedChangesDialog(
          exportAfterSave: true); // Prompt user to save or discard
      return; // Exit if user cancels or needs to save first
    }

    // Prevent export if there's no data
    if (_requirements.isEmpty) {
      _showSnackBar('No requirements data to export.',
          isError: false, isWarning: true);
      return;
    }

    if (mounted) setState(() => _isExporting = true); // Show loading indicator

    try {
      var excel = Excel.createExcel(); // Create a new Excel workbook instance
      Sheet sheet =
          excel['Requirements']; // Get or create the 'Requirements' sheet

      // --- Styling (Optional but improves readability) ---
      var headerStyle = CellStyle(
          bold: true,
          fontSize: 11,
          backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'), // Light grey
          verticalAlign: VerticalAlign.Center,
          horizontalAlign: HorizontalAlign.Center);
      var dataCellStyle = CellStyle(
          verticalAlign: VerticalAlign.Top,
          textWrapping: TextWrapping.WrapText); // Wrap text in cells

      // --- Define and Write Headers ---
      List<String> headerTitles = [
        'Req ID',
        'Priority',
        'Type',
        'Requirement',
        'Notes',
        'Status'
      ];
      // Write header titles as TextCellValues
      sheet.appendRow(
          headerTitles.map((title) => TextCellValue(title)).toList());
      // Apply header style to each header cell
      for (var i = 0; i < headerTitles.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      // --- Set Column Widths (Optional) ---
      try {
        sheet.setColumnWidth(0, 12); // Req ID
        sheet.setColumnWidth(1, 10); // Priority
        sheet.setColumnWidth(2, 18); // Type
        sheet.setColumnWidth(3, 55); // Requirement (wider)
        sheet.setColumnWidth(4, 35); // Notes (wider)
        sheet.setColumnWidth(5, 18); // Status
      } catch (e) {
        print(
            "Note: Could not set Excel column widths. $e"); // Log if setting widths fails
      }

      // --- Add Data Rows ---
      int rowIndex = 1; // Start from the second row (index 1)
      for (var req in _requirements) {
        // Map requirement data to Excel CellValue objects
        List<CellValue> rowData = [
          TextCellValue(req['reqId']?.toString() ?? ''),
          TextCellValue(req['priority']?.toString() ?? ''),
          TextCellValue(req['type']?.toString() ?? ''),
          TextCellValue(req['requirement']?.toString() ?? ''),
          TextCellValue(req['notes']?.toString() ?? ''),
          TextCellValue(req['status']?.toString() ?? ''),
        ];
        sheet.appendRow(rowData); // Add the row to the sheet

        // Apply data cell style to each cell in the newly added row
        for (var i = 0; i < rowData.length; i++) {
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: i, rowIndex: rowIndex))
              .cellStyle = dataCellStyle;
        }
        rowIndex++;
      }

      // --- Save Excel to Bytes ---
      // Provide a default filename for the save method (used internally by excel package)
      final List<int>? bytes = excel.save(fileName: 'requirements.xlsx');
      if (bytes == null) {
        throw Exception("Failed to generate Excel byte data.");
      }
      const String excelFileName =
          'requirements.xlsx'; // Filename for saving/sharing

      // --- Mobile/Desktop: Save Temporarily and Share ---
      try {
        // Get a temporary directory using path_provider
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}/$excelFileName'; // Full path for the temp file
        final file = io.File(path);
        // Write the Excel bytes to the temporary file
        await file.writeAsBytes(bytes, flush: true);

        // Use share_plus to trigger the platform's share sheet
        final result = await Share.shareXFiles([XFile(path)],
            text: 'Here is the requirements Excel file.');

        // Provide feedback based on the sharing result status
        if (!mounted) return; // Check mount before showing snackbar
        if (result.status == ShareResultStatus.success) {
          _showSnackBar('File shared successfully!', isError: false);
        } else if (result.status == ShareResultStatus.dismissed) {
          _showSnackBar('Sharing cancelled. File saved temporarily.',
              isError: false, isWarning: true);
        } else {
          _showSnackBar(
              'File saved temporarily. Sharing status: ${result.status.name}.',
              isError: false);
        }
        // Note: The temporary file might be cleaned up by the OS later, or you could delete it explicitly if needed.
      } catch (e) {
        // Handle errors during file writing or sharing
        throw Exception('Error saving/sharing file on device: $e');
      }
    } catch (e) {
      // Catch any errors during Excel generation or saving/sharing process
      if (mounted)
        _showSnackBar('Error exporting Excel file: $e', isError: true);
    } finally {
      // Ensure loading indicator is turned off regardless of success or failure
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // Uploads the current requirements data as an Excel file to Firebase Storage.
  Future<void> _uploadToFirebase() async {
    // Check for unsaved changes first
    if (!_isSaved) {
      _showUnsavedChangesDialog(
          uploadToFirebaseAfterSave: true); // Prompt to save/discard
      return;
    }

    // Prevent upload if there's no data
    if (_requirements.isEmpty) {
      _showSnackBar('No requirements data to upload.',
          isError: false, isWarning: true);
      return;
    }

    if (mounted) setState(() => _isUploading = true); // Show loading indicator

    try {
      // --- Generate the Excel file in memory (similar to _exportToExcel) ---
      var excel = Excel.createExcel();
      Sheet sheet = excel['Requirements'];
      // Add Headers
      List<String> headerTitles = [
        'Req ID',
        'Priority',
        'Type',
        'Requirement',
        'Notes',
        'Status'
      ];
      sheet.appendRow(
          headerTitles.map((title) => TextCellValue(title)).toList());
      // Add Data rows
      for (var req in _requirements) {
        List<CellValue> rowData = [
          TextCellValue(req['reqId']?.toString() ?? ''),
          TextCellValue(req['priority']?.toString() ?? ''),
          TextCellValue(req['type']?.toString() ?? ''),
          TextCellValue(req['requirement']?.toString() ?? ''),
          TextCellValue(req['notes']?.toString() ?? ''),
          TextCellValue(req['status']?.toString() ?? ''),
        ];
        sheet.appendRow(rowData);
      }
      // Save Excel to bytes
      final List<int>? bytes = excel.save(); // No filename needed here
      if (bytes == null) {
        throw Exception("Failed to generate Excel byte data for upload.");
      }

      // --- Upload Logic (Mobile/Desktop Focused) ---
      // Generate a unique filename using a timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'requirements_$timestamp.xlsx'; // e.g., requirements_1678886400000.xlsx
      // Get Firebase Storage reference (using a folder path)
      final ref = _storage.ref().child('excel_files/$fileName');

      // Save the bytes to a temporary file first (required for putFile)
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/temp_upload.xlsx'; // Temporary file name
      final file = io.File(path);
      await file.writeAsBytes(bytes, flush: true);

      // Upload the temporary file using putFile
      final uploadTask = ref.putFile(file);

      // Wait for the upload to complete
      await uploadTask.whenComplete(() {});

      // Optionally, get the download URL after upload (not used here, but available)
      // final downloadUrl = await ref.getDownloadURL();

      if (mounted)
        _showSnackBar('Excel file uploaded to Firebase!', isError: false);

      // Clean up the temporary file after successful upload
      try {
        await file.delete();
      } catch (e) {
        print(
            "Note: Could not delete temporary upload file: $e"); // Log deletion errors
      }
    } catch (e) {
      // Handle errors during Excel generation or Firebase upload
      if (mounted)
        _showSnackBar('Error uploading to Firebase: $e', isError: true);
    } finally {
      // Ensure loading indicator is hidden
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Initiates the process to import requirements from an Excel file in Firebase Storage.
  Future<void> _importFromFirebase() async {
    // Prevent import if there are unsaved changes
    if (!_isSaved) {
      _showSnackBar('Please save or discard changes before importing.',
          isError: false, isWarning: true);
      // Consider showing the unsaved changes dialog here as well
      // _showUnsavedChangesDialog(importAfterSave: true); // Need to add import flag
      return;
    }

    if (mounted)
      setState(() =>
          _isUploading = true); // Show loading indicator for listing files

    try {
      // List all files/items in the 'excel_files' directory in Firebase Storage
      final ListResult result =
          await _storage.ref().child('excel_files').listAll();

      if (!mounted) return; // Check mount status after async operation
      setState(() =>
          _isUploading = false); // Hide indicator after listing is complete

      // Check if any files were found
      if (result.items.isEmpty) {
        _showSnackBar(
            'No Excel files found in Firebase Storage (in /excel_files).',
            isError: false,
            isWarning: true);
        return;
      }

      // --- Show File Selection Dialog ---
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Excel File to Import'),
          content: SizedBox(
            // Constrain the size of the list view
            width: double.maxFinite, // Use available width
            height: 300, // Set a fixed height for the list
            child: ListView.builder(
              itemCount: result.items.length, // Number of files found
              itemBuilder: (context, index) {
                final Reference ref =
                    result.items[index]; // Get reference to the file
                return ListTile(
                  leading: const Icon(Icons.description_outlined), // File icon
                  title: Text(ref.name), // Display filename
                  onTap: () async {
                    Navigator.pop(context); // Close the selection dialog first
                    await _downloadAndProcessExcel(
                        ref); // Start download & processing
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              // Cancel button for the dialog
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } on FirebaseException catch (e) {
      // Handle specific Firebase errors (e.g., permissions)
      if (mounted) setState(() => _isUploading = false);
      _showSnackBar('Firebase Error listing files: ${e.message}',
          isError: true);
    } catch (e) {
      // Handle other potential errors during listing
      if (mounted)
        setState(() => _isUploading = false); // Hide indicator on error
      _showSnackBar('Error listing Firebase files: $e', isError: true);
    }
  }

  // Downloads the selected Excel file from Firebase and processes its content.
  Future<void> _downloadAndProcessExcel(Reference ref) async {
    if (mounted) setState(() => _isUploading = true); // Show loading indicator

    io.File? tempFile; // To hold temporary file reference for cleanup

    try {
      // --- Mobile/Desktop: Download to Temporary File ---
      final directory = await getTemporaryDirectory();
      tempFile =
          io.File('${directory.path}/${ref.name}'); // Create local file path

      // Download the file from Firebase Storage to the temporary file
      await ref.writeToFile(tempFile);

      // Read the downloaded file bytes
      final Uint8List data = await tempFile.readAsBytes();

      // --- Process the downloaded Excel data ---
      if (data.isEmpty) {
        throw Exception("Downloaded Excel file data is empty.");
      }

      // Decode the Excel bytes using the excel package
      final excel = Excel.decodeBytes(data);

      // Check if the required sheet named 'Requirements' exists
      if (!excel.tables.containsKey('Requirements')) {
        throw Exception(
            "Excel file must contain a sheet named 'Requirements'.");
      }
      Sheet sheet = excel['Requirements']; // Get the sheet

      // Check if the sheet has at least one data row (besides header)
      if (sheet.maxRows <= 1) {
        throw Exception("The 'Requirements' sheet has no data rows.");
      }

      // --- Extract Headers ---
      // Safely extract headers from the first row (index 0)
      // Use `?.` on value and `?.` on toString() for null safety
      List<String?> headers = sheet
          .row(0)
          .map((cell) => cell?.value?.toString()?.trim())
          .toList(); // Handles potential null cells/values

      // --- Map Headers to Field Names --- (Case-insensitive)
      Map<String, int> columnMap = {}; // Stores {'fieldName': columnIndex}
      // Define expected header variations and map them to consistent field names
      Map<String, String> headerToFieldMap = {
        'req id': 'reqId',
        'requirement id': 'reqId',
        'priority': 'priority',
        'type': 'type',
        'requirement type': 'type',
        'requirement': 'requirement',
        'description': 'requirement',
        'notes': 'notes',
        'comments': 'notes',
        'status': 'status',
      };
      // Find the column index for each expected field
      for (int i = 0; i < headers.length; i++) {
        String? header =
            headers[i]?.toLowerCase(); // Use lowercase for matching
        if (header != null && headerToFieldMap.containsKey(header)) {
          columnMap[headerToFieldMap[header]!] = i; // Store the index
        }
      }

      // --- Optional: Check if all mandatory columns were found ---
      if (!columnMap.containsKey('reqId') ||
          !columnMap.containsKey('requirement')) {
        _showSnackBar(
            "Warning: Missing 'Req ID' or 'Requirement' column in Excel. Rows without these may be skipped or have default values.",
            isError: false,
            isWarning: true);
        // Depending on strictness, could throw Exception here instead
      }

      // --- Process Data Rows ---
      List<Map<String, dynamic>> importedReqs =
          []; // List to store imported requirements
      // Iterate through rows starting from the second row (index 1)
      for (int r = 1; r < sheet.maxRows; r++) {
        var row = sheet.row(r);
        // Skip potentially empty rows more robustly
        if (row.isEmpty ||
            row.every((cell) =>
                cell == null ||
                cell.value == null ||
                cell.value.toString().trim().isEmpty)) {
          continue;
        }

        Map<String, dynamic> reqData =
            {}; // Map to hold data for the current row

        // Helper function to safely get cell value by field name using the columnMap
        String? getCellValue(String fieldName) {
          if (columnMap.containsKey(fieldName)) {
            int colIndex = columnMap[fieldName]!;
            // Check if the row has enough cells for the mapped index
            if (colIndex < row.length) {
              // Safely access value and convert to string, then trim
              return row[colIndex]?.value?.toString().trim();
            }
          }
          return null; // Return null if field not found or index out of bounds
        }

        // --- Extract data for each field using the helper ---
        reqData['reqId'] = getCellValue('reqId') ??
            'IMPORT_ID_$r'; // Provide fallback ID if missing
        reqData['priority'] =
            getCellValue('priority')?.toUpperCase() ?? 'C'; // Default to 'C'
        reqData['type'] =
            getCellValue('type') ?? 'Functional'; // Default to 'Functional'
        reqData['requirement'] =
            getCellValue('requirement') ?? ''; // Default to empty string
        reqData['notes'] = getCellValue('notes') ?? '';
        reqData['status'] = getCellValue('status') ?? 'New'; // Default to 'New'

        // --- Basic Data Validation ---
        // Ensure priority is a valid MoSCoW value, default to 'C' if not
        if (!['M', 'S', 'C', 'W'].contains(reqData['priority'])) {
          reqData['priority'] = 'C';
        }
        // Add more validation as needed (e.g., for type, status)

        // Add the processed requirement data to the list if it has an ID and requirement text
        if ((reqData['reqId']?.isNotEmpty ?? false) &&
            (reqData['requirement']?.isNotEmpty ?? false)) {
          importedReqs.add(reqData);
        } else {
          print(
              "Skipping imported row $r due to missing Req ID or Requirement text.");
        }
      }

      // Check if any valid requirements were imported
      if (importedReqs.isEmpty) {
        throw Exception(
            "No valid data rows found or processed in the Excel file.");
      }

      // --- Update App State ---
      // Replace current requirements with the imported data
      if (mounted) {
        setState(() {
          _requirements = importedReqs;
          _isSaved = true; // Mark as saved state after successful import
          _applyFiltersAndSort(); // Refresh the view with imported data
        });
      }

      _showSnackBar(
          'Successfully imported ${importedReqs.length} requirements from ${ref.name}',
          isError: false);
    } catch (e) {
      // Handle errors during download or processing
      if (mounted) _showSnackBar('Error importing Excel: $e', isError: true);
    } finally {
      // --- Cleanup Temporary File ---
      if (tempFile != null) {
        try {
          await tempFile.delete(); // Delete the temporary file
        } catch (e) {
          print(
              "Note: Could not delete temporary import file: $e"); // Log deletion errors
        }
      }
      // Ensure loading indicator is hidden
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Navigates to the AnalyticsScreen.
  void _navigateToAnalytics() {
    // Check for unsaved changes first
    if (!_isSaved) {
      _showUnsavedChangesDialog(
          navigateToAnalyticsAfterSave: true); // Prompt save/discard
      return;
    }

    // Prevent navigation if there's no data to analyze
    if (_requirements.isEmpty) {
      _showSnackBar('No data available to analyze.',
          isError: false, isWarning: true);
      return;
    }

    // Navigate to AnalyticsScreen, passing a deep copy of the current data
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsScreen(
            // Create a deep copy to prevent modification issues if user navigates back
            requirementsData: List<Map<String, dynamic>>.from(
                _requirements.map((req) => Map<String, dynamic>.from(req)))),
      ),
    );
  }

  // Helper function to show SnackBar messages with different colors for status.
  void _showSnackBar(String message,
      {required bool isError, bool isWarning = false}) {
    if (!mounted) return; // Check if widget is still mounted
    // Determine background color based on message type
    final Color backgroundColor = isError
        ? Colors.redAccent // Red for errors
        : (isWarning
            ? Colors.orangeAccent
            : Colors.green); // Orange for warnings, Green for success

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior
          .floating, // Makes SnackBar float above bottom widgets (like FAB)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10), // Margin around the SnackBar
      backgroundColor: backgroundColor, // Set background color
    ));
  }

  // Shows a dialog warning about unsaved changes before performing an action (like export, upload, navigate).
  void _showUnsavedChangesDialog({
    bool navigateToAnalyticsAfterSave = false,
    bool uploadToFirebaseAfterSave = false,
    bool exportAfterSave = false, // Flag for export action
    // bool importAfterSave = false, // Flag if needed for import (currently handled differently)
  }) {
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                  'You have unsaved changes. Would you like to save them before proceeding?'),
              actions: [
                // --- Discard Changes Button ---
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      if (mounted)
                        setState(() {
                          _isSaved = true;
                        }); // Mark as saved (effectively discarding changes)
                      // Proceed with the original action after discarding
                      if (navigateToAnalyticsAfterSave) _navigateToAnalytics();
                      if (uploadToFirebaseAfterSave) _uploadToFirebase();
                      if (exportAfterSave) _exportToExcel();
                      // if (importAfterSave) _importFromFirebase(); // If needed
                    },
                    child: const Text('Discard Changes')),
                // --- Cancel Action Button ---
                TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(), // Just close the dialog
                    child: const Text('Cancel Action')),
                // --- Save Changes & Proceed Button ---
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      _saveChanges(); // Perform the save action first

                      // Proceed with the original action after saving
                      // Use short delay to ensure save state update propagates if needed
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (!mounted) return; // Re-check mount status
                        if (navigateToAnalyticsAfterSave)
                          _navigateToAnalytics();
                        if (uploadToFirebaseAfterSave) _uploadToFirebase();
                        if (exportAfterSave) _exportToExcel();
                        // if (importAfterSave) _importFromFirebase(); // If needed
                      });
                    },
                    child: const Text('Save & Proceed')),
              ],
            ));
  }

  // Helper to get a color based on requirement priority (MoSCoW).
  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'M':
        return Colors.redAccent;
      case 'S':
        return Colors.orangeAccent;
      case 'C':
        return Colors.lightBlueAccent;
      case 'W':
        return Colors.grey;
      default:
        return Colors.grey.shade400; // Default color for unknown/unset
    }
  }

  // Helper to get the full text label for a priority key (e.g., 'M' -> 'Must Have').
  String _getPriorityLabel(String priority) {
    switch (priority.toUpperCase()) {
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

  // Helper to get a color based on requirement status.
  Color _getStatusColor(String status) {
    // Use lowercase for case-insensitive matching
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'updated':
        return Colors.green;
      case 'pending':
      case 'pending qa':
        return Colors.orange; // Group pending statuses
      case 'completed':
        return Colors.teal;
      case 'rejected':
        return Colors.red;
      case 'skipped qa':
        return Colors.purpleAccent; // Distinct color for skipped items
      default:
        return Colors.grey; // Default color for unknown statuses
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if actions like export/analyze/upload are enabled
    // Requires changes to be saved and no other operation in progress
    final bool canPerformActions = _isSaved && !_isExporting && !_isUploading;
    // Check if any filters (Type, Priority, Status) or search query are active
    final bool isFiltered = _filterType != 'All' ||
        _filterPriority != 'All' ||
        _filterStatus != 'All' ||
        _searchQuery.isNotEmpty;

    // --- Build Filter String for Display ---
    // Concatenate active filter criteria into a readable string
    String filterText = 'Filters: ' +
        [
          // Create list of active filters
          if (_filterType != 'All') 'Type: $_filterType',
          if (_filterPriority != 'All') 'Priority: $_filterPriority',
          if (_filterStatus != 'All') 'Status: $_filterStatus',
          if (_searchQuery.isNotEmpty) 'Search: "$_searchQuery"',
        ].join(', '); // Join with ', '
    // Remove trailing ', ' if only 'Filters: ' is present
    if (filterText == 'Filters: ')
      filterText = ''; // Clear if no filters active

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requirements Manager'),
        actions: [
          // --- Analytics Button ---
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View Analytics',
            // Enable only when saved and no operation is running
            onPressed: canPerformActions ? _navigateToAnalytics : null,
          ),

          // --- More Actions Menu (Export, Upload, Import) ---
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Actions',
            // Disable the entire menu if an export/upload/import is in progress
            enabled: !_isExporting && !_isUploading,
            itemBuilder: (context) => [
              // --- Export Option ---
              PopupMenuItem(
                value: 'export',
                enabled: canPerformActions, // Enable only if saved
                child: ListTile(
                  leading: Icon(Icons.download_outlined,
                      color: canPerformActions ? null : Colors.grey),
                  title: Text('Export to Excel',
                      style: TextStyle(
                          color: canPerformActions ? null : Colors.grey)),
                ),
              ),
              // --- Upload Option ---
              PopupMenuItem(
                value: 'upload',
                enabled: canPerformActions, // Enable only if saved
                child: ListTile(
                  leading: Icon(Icons.cloud_upload_outlined,
                      color: canPerformActions ? null : Colors.grey),
                  title: Text('Upload to Firebase',
                      style: TextStyle(
                          color: canPerformActions ? null : Colors.grey)),
                ),
              ),
              const PopupMenuDivider(), // Visual separator
              // --- Import Option ---
              PopupMenuItem(
                value: 'import',
                // Enable import even if unsaved (check happens inside _importFromFirebase)
                // Disable only if another upload/export is running
                enabled: !_isUploading && !_isExporting,
                child: ListTile(
                  leading: Icon(Icons.cloud_download_outlined,
                      color:
                          !_isUploading && !_isExporting ? null : Colors.grey),
                  title: Text('Import from Firebase',
                      style: TextStyle(
                          color: !_isUploading && !_isExporting
                              ? null
                              : Colors.grey)),
                ),
              ),
            ],
            // Handle menu item selection
            onSelected: (value) {
              switch (value) {
                case 'export':
                  if (canPerformActions) _exportToExcel();
                  break;
                case 'upload':
                  if (canPerformActions) _uploadToFirebase();
                  break;
                case 'import':
                  // Check for unsaved changes happens inside the function itself
                  _importFromFirebase();
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Search and Filter Controls Bar ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // --- Search Input Field ---
                Expanded(
                  child: TextField(
                    controller: _searchController, // Use controller
                    decoration: InputDecoration(
                      hintText: 'Search requirements...',
                      prefixIcon:
                          const Icon(Icons.search, size: 20), // Smaller icon
                      // Style for a cleaner, contained look
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.4),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 12), // Adjust padding
                      // Clear button
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              tooltip: 'Clear Search',
                              onPressed: () {
                                _searchController
                                    .clear(); // Clear controller and trigger listener
                              },
                            )
                          : null,
                    ),
                    // onChanged handled by listener
                  ),
                ),
                const SizedBox(width: 4), // Small space

                // --- Filter Button ---
                // Shows a badge if filters are active
                IconButton(
                  icon: Badge(
                    label:
                        const Text(''), // No label needed, just dot indicator
                    // Small offset for the badge position
                    offset: const Offset(2, -2),
                    // Show badge only if filters are active
                    isLabelVisible: isFiltered,
                    child: const Icon(Icons.filter_list),
                  ),
                  tooltip: 'Filter Requirements',
                  onPressed: _showFilterDialog, // Open filter dialog
                ),

                // --- Sort Button ---
                IconButton(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort Requirements',
                  onPressed: _showSortDialog, // Open sort dialog
                ),

                // --- Save Button ---
                // Icon changes based on saved state (checkmark or save icon)
                IconButton(
                  icon: Icon(
                    _isSaved ? Icons.check_circle : Icons.save_outlined,
                    color: _isSaved
                        ? Colors.green
                        : Theme.of(context)
                            .colorScheme
                            .primary, // Green when saved
                  ),
                  tooltip: _isSaved ? 'Changes Saved' : 'Save Changes',
                  // Enable button only when there are unsaved changes
                  onPressed: _isSaved ? null : _saveChanges,
                ),
              ],
            ),
          ),

          // --- Active Filters Indicator Row --- (Shown only if filters/search active)
          if (isFiltered)
            Container(
              // Subtle background color to highlight the filter bar
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined,
                      size: 16, color: Colors.grey), // Filter icon
                  const SizedBox(width: 8),
                  // Display the constructed filterText string
                  Expanded(
                    child: Text(
                      filterText, // Use the pre-built string
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow:
                          TextOverflow.ellipsis, // Prevent long text overflow
                    ),
                  ),
                  // --- Clear All Filters Button ---
                  TextButton(
                    // Minimal styling for the clear button
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        visualDensity: VisualDensity.compact),
                    onPressed: () {
                      // Reset all filter states and clear search query
                      if (mounted) {
                        setState(() {
                          _filterType = 'All';
                          _filterPriority = 'All';
                          _filterStatus = 'All';
                          _searchController
                              .clear(); // This will trigger the listener to update _searchQuery
                          // Clearing filters doesn't necessarily warrant marking as unsaved
                        });
                      }
                      _applyFiltersAndSort(); // Re-apply to show all items
                    },
                    child:
                        const Text('Clear All', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // --- Loading Indicators for Export/Upload/Import ---
          if (_isExporting || _isUploading)
            LinearProgressIndicator(
              // Use a linear indicator for file operations
              minHeight: 3, // Make it subtle
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
              backgroundColor: Colors.amber.withOpacity(0.2),
            ),

          // --- Main Requirements List View ---
          Expanded(
            // Show message if list is empty after filtering/loading
            child: _filteredRequirements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          // Different icon based on whether list is empty due to filters or genuinely empty
                          isFiltered
                              ? Icons.filter_alt_off_outlined
                              : Icons.notes_outlined,
                          size: 48, color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          // Different message based on context
                          isFiltered
                              ? 'No requirements match your filters/search'
                              : 'No requirements added yet',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Show "Add" button only if the list is truly empty (no filters active)
                        if (!isFiltered && _requirements.isEmpty)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Requirement'),
                            onPressed: _addNewRequirement,
                          ),
                      ],
                    ),
                  )
                // Display the list of requirements using ListView.builder for efficiency
                : ListView.builder(
                    itemCount: _filteredRequirements
                        .length, // Number of items in the filtered list
                    itemBuilder: (context, index) {
                      final req = _filteredRequirements[
                          index]; // Get requirement data for the current index
                      // --- Requirement List Item Card ---
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        elevation: 1.5, // Subtle shadow
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          // Padding inside the list tile
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          // --- Title Section (ID, Priority, Type) ---
                          title: Row(
                            children: [
                              // -- Requirement ID Tag --
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  req['reqId'] ??
                                      'ID?', // Display ID, fallback to 'ID?'
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // -- Priority Chip (Colored Square/Circle with Letter) --
                              Tooltip(
                                // Show full priority label on hover/long press
                                message: _getPriorityLabel(
                                    req['priority'] ?? 'C'), // Get full label
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(req['priority'] ??
                                        'C'), // Get color based on priority
                                    borderRadius: BorderRadius.circular(
                                        4), // Slightly rounded corners
                                  ),
                                  child: Text(
                                    req['priority'] ??
                                        'C', // Show only the letter (M/S/C/W)
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // -- Requirement Type Text --
                              Expanded(
                                // Allow type to take remaining space
                                child: Text(
                                  req['type'] ??
                                      'Unknown Type', // Display type, fallback
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey), // Subdued color
                                  overflow: TextOverflow
                                      .ellipsis, // Prevent overflow if type name is long
                                ),
                              ),
                            ],
                          ),
                          // --- Subtitle Section (Requirement Text, Notes, Status) ---
                          subtitle: Padding(
                            padding: const EdgeInsets.only(
                                top: 6.0), // Space below title row
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // -- Requirement Text (Main content) --
                                Text(
                                  req['requirement']?.toString() ??
                                      '', // Display requirement text
                                  style: const TextStyle(
                                      fontSize: 15,
                                      height:
                                          1.3), // Regular weight, slight line spacing
                                  maxLines:
                                      3, // Limit lines shown initially in the list
                                  overflow: TextOverflow
                                      .ellipsis, // Add ellipsis if text exceeds maxLines
                                ),
                                // -- Notes (Show only if notes exist) --
                                if (req['notes'] != null &&
                                    req['notes'].toString().trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      "Notes: ${req['notes']?.toString() ?? ''}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle:
                                            FontStyle.italic, // Italicize notes
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.7), // Subdued color
                                      ),
                                      maxLines: 2, // Limit lines for notes
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(
                                    height: 8), // Space before status chip
                                // -- Status Chip (Aligned to the right) --
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      // Use status color with low opacity for background
                                      color: _getStatusColor(
                                              req['status'] ?? 'New')
                                          .withOpacity(0.15),
                                      // Use full status color for border
                                      border: Border.all(
                                          color: _getStatusColor(
                                              req['status'] ?? 'New'),
                                          width: 0.8),
                                      borderRadius: BorderRadius.circular(
                                          12), // Rounded pill shape
                                    ),
                                    child: Text(
                                      req['status'] ??
                                          'New', // Display status text
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        // Use full status color for text for contrast
                                        color: _getStatusColor(
                                            req['status'] ?? 'New'),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // --- Interactions ---
                          onTap: () =>
                              _editRequirement(req), // Tap to open edit dialog
                          onLongPress: () => _deleteRequirement(
                              req), // Long press to show delete confirmation
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // --- Floating Action Button (FAB) ---
      // Used for adding new requirements
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRequirement, // Call function to add new item
        tooltip: 'Add New Requirement',
        child: const Icon(Icons.add), // Standard add icon
      ),
    );
  }
}

// --- Helper extension for String class ---
// Adds a method to trim a trailing comma and optional space.
extension StringTrim on String {
  String trimRightComma() {
    if (endsWith(', ')) {
      return substring(0, length - 2); // Remove ', '
    } else if (endsWith(',')) {
      return substring(0, length - 1); // Remove just ','
    }
    return this; // Return original string if no trailing comma found
  }
}

// --- Chart Data Structure ---
// Simple class to hold data points for Syncfusion charts.
class ChartData {
  ChartData(this.x, this.y, [this.color]);
  final String x; // Category Name (e.g., 'Functional', 'Must Have', 'New')
  final double y; // Value (e.g., count, percentage)
  final Color? color; // Optional color for the data point/segment/bar
}

// --- Analytics Screen Widget ---
// Displays charts visualizing the requirements data.
class AnalyticsScreen extends StatelessWidget {
  final List<Map<String, dynamic>>
      requirementsData; // Data passed from Manager screen

  const AnalyticsScreen({super.key, required this.requirementsData});

  // Helper to get the full MoSCoW label from priority key (e.g., 'M' -> 'Must Have').
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
        return 'Unknown'; // Handle null or unexpected values
    }
  }

  // Helper to get a specific color for each MoSCoW priority.
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
        return Colors.grey.shade400; // Default grey for unknown
    }
  }

  // Helper to get a color for status (reusing logic from Manager screen).
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'updated':
        return Colors.green;
      case 'pending':
      case 'pending qa':
        return Colors.orange;
      case 'completed':
        return Colors.teal;
      case 'rejected':
        return Colors.red;
      case 'skipped qa':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Data Processing for Charts ---
    // Initialize counters and maps
    int functionalCount = 0;
    int nonFunctionalCount = 0;
    Map<String, int> moscowCounts = {
      'M': 0,
      'S': 0,
      'C': 0,
      'W': 0
    }; // Counts for each valid priority
    Map<String, int> statusCounts = {}; // Counts for each status found
    Map<String, int> unknownPriorities =
        {}; // To track invalid/missing priorities explicitly

    // Iterate through requirements data to aggregate counts
    for (var req in requirementsData) {
      // --- Count Functional vs Non-Functional types ---
      String? type = req['type']?.toString();
      if (type == 'Functional') {
        functionalCount++;
      } else if (type == 'Non-Functional') {
        nonFunctionalCount++;
      } // Ignore other types for this specific chart

      // --- Count MoSCoW priorities ---
      String? priority = req['priority']?.toString().toUpperCase();
      if (priority != null && moscowCounts.containsKey(priority)) {
        moscowCounts[priority] =
            moscowCounts[priority]! + 1; // Increment count for valid priority
      } else {
        // Count unknown/invalid priorities separately
        String key = priority ?? 'Unknown'; // Use 'Unknown' if priority is null
        unknownPriorities[key] = (unknownPriorities[key] ?? 0) + 1;
      }

      // --- Count statuses ---
      String? status = req['status']?.toString();
      if (status != null && status.isNotEmpty) {
        statusCounts[status] =
            (statusCounts[status] ?? 0) + 1; // Increment count for status
      }
    }

    int totalReqs = requirementsData.length; // Total number of requirements

    // --- Prepare Data for Functional vs Non-Functional Pie Chart ---
    final List<ChartData> funcNFuncData = [];
    if (totalReqs > 0) {
      // Avoid division by zero
      // Add data point for Functional requirements if count > 0
      if (functionalCount > 0) {
        funcNFuncData.add(ChartData(
            'Functional', (functionalCount / totalReqs) * 100, Colors.teal));
      }
      // Add data point for Non-Functional requirements if count > 0
      if (nonFunctionalCount > 0) {
        funcNFuncData.add(ChartData('Non-Functional',
            (nonFunctionalCount / totalReqs) * 100, Colors.deepOrangeAccent));
      }
      // Calculate and add data point for any 'Other' or unset types
      int otherCount = totalReqs - functionalCount - nonFunctionalCount;
      if (otherCount > 0) {
        funcNFuncData.add(ChartData(
            'Other/Unset', (otherCount / totalReqs) * 100, Colors.grey));
      }
    }

    // --- Prepare Data for MoSCoW Priority Pie Chart ---
    // Map valid priority counts to ChartData objects
    final List<ChartData> moscowData = moscowCounts.entries
        .where((entry) =>
            entry.value > 0) // Only include priorities with count > 0
        .map((entry) => ChartData(
            _getMoscowLabel(
                entry.key), // Use helper for full label (e.g., 'Must Have')
            entry.value.toDouble(), // Value is the count
            _getMoscowColor(entry.key))) // Use helper for color
        .toList();
    // Add unknown/invalid priorities found during aggregation to the chart data
    unknownPriorities.forEach((key, value) {
      // Label includes the invalid key found (e.g., 'Unknown (P)')
      moscowData.add(
          ChartData('Unknown ($key)', value.toDouble(), Colors.grey.shade400));
    });
    // Sort MoSCoW data for a consistent order in the legend/chart (M, S, C, W, Unknown)
    moscowData.sort((a, b) {
      const order = {
        'Must Have': 1,
        'Should Have': 2,
        'Could Have': 3,
        'Won\'t Have': 4
      };
      // Assign high order number to 'Unknown' labels to place them last
      int orderA = a.x.startsWith('Unknown')
          ? 99
          : (order[a.x] ?? 98); // 98 for potential future valid priorities
      int orderB = b.x.startsWith('Unknown') ? 99 : (order[b.x] ?? 98);
      return orderA.compareTo(orderB); // Compare based on assigned order
    });

    // --- Prepare Data for Status Bar Chart ---
    // Map status counts to ChartData objects
    final List<ChartData> statusData = statusCounts.entries
        .map((entry) => ChartData(
            entry.key, // Status name (e.g., 'New', 'Completed')
            entry.value.toDouble(), // Count for that status
            _getStatusColor(entry.key))) // Use helper for color
        .toList();
    // Sort status data alphabetically by status name for consistency
    statusData.sort((a, b) => a.x.compareTo(b.x));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requirements Analytics'), // Screen title
      ),
      // Show message if no data is available for analysis
      body: requirementsData.isEmpty
          ? const Center(
              child: Text('No requirements data available for analysis.'))
          : SingleChildScrollView(
              // Allow scrolling if chart content overflows on smaller screens
              padding: const EdgeInsets.all(16.0), // Padding around the charts
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .stretch, // Stretch chart cards horizontally
                children: [
                  // --- Card 1: Functional vs Non-Functional Pie Chart ---
                  _buildChartCard(
                    title: 'Type Distribution (%)', // Chart title
                    chart: SfCircularChart(
                      // Configure legend
                      legend: const Legend(
                          isVisible: true,
                          position: LegendPosition.bottom,
                          overflowMode: LegendItemOverflowMode.wrap),
                      series: <CircularSeries<ChartData, String>>[
                        PieSeries<ChartData, String>(
                          dataSource: funcNFuncData, // Use prepared data
                          xValueMapper: (ChartData data, _) => data
                              .x, // Category name (Functional/Non-Functional)
                          yValueMapper: (ChartData data, _) =>
                              data.y, // Percentage value
                          pointColorMapper: (ChartData data, _) =>
                              data.color, // Assign colors per category
                          // Configure data labels shown on/around the pie slices
                          dataLabelMapper: (ChartData data, _) =>
                              '${data.y.toStringAsFixed(1)}%', // Format label as percentage
                          dataLabelSettings: const DataLabelSettings(
                              isVisible: true, // Show labels
                              labelPosition: ChartDataLabelPosition
                                  .outside, // Position labels outside slices
                              connectorLineSettings: ConnectorLineSettings(
                                  type: ConnectorType
                                      .curve), // Use curved connectors
                              textStyle: TextStyle(fontSize: 12)),
                          // Optional: Explode slices on tap for emphasis
                          explode: true, // Enable explosion
                          explodeAll: false, // Only explode the tapped slice
                          selectionBehavior: SelectionBehavior(
                              enable: true), // Enable selection highlighting
                        )
                      ],
                      // Configure tooltips shown on hover/tap
                      tooltipBehavior: TooltipBehavior(
                          enable: true,
                          format:
                              'point.x: point.y%'), // Show category and percentage
                    ),
                  ),
                  const SizedBox(height: 24), // Spacing between chart cards

                  // --- Card 2: MoSCoW Priority Pie Chart ---
                  _buildChartCard(
                    title: 'MoSCoW Priority Breakdown (Count)', // Chart title
                    chart: SfCircularChart(
                      legend: const Legend(
                          isVisible: true,
                          position: LegendPosition.bottom,
                          overflowMode: LegendItemOverflowMode.wrap),
                      series: <CircularSeries<ChartData, String>>[
                        PieSeries<ChartData, String>(
                          dataSource: moscowData, // Use prepared MoSCoW data
                          xValueMapper: (ChartData data, _) =>
                              data.x, // Priority label (Must Have, etc.)
                          yValueMapper: (ChartData data, _) =>
                              data.y, // Count for each priority
                          pointColorMapper: (ChartData data, _) =>
                              data.color, // Priority color
                          dataLabelMapper: (ChartData data, _) =>
                              '${data.y.toInt()}', // Show count as integer
                          dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              labelPosition: ChartDataLabelPosition.outside,
                              connectorLineSettings: ConnectorLineSettings(
                                  type: ConnectorType.curve),
                              textStyle: TextStyle(fontSize: 12)),
                          explode: true,
                          explodeAll: false, // Enable explode on tap
                          selectionBehavior: SelectionBehavior(
                              enable: true), // Enable selection
                        )
                      ],
                      tooltipBehavior: TooltipBehavior(
                          enable: true,
                          format:
                              'point.x: point.y'), // Show priority label and count
                    ),
                  ),
                  const SizedBox(height: 24), // Spacing

                  // --- Card 3: Status Bar Chart ---
                  _buildChartCard(
                    title: 'Requirements Status (Count)', // Chart title
                    chart: SfCartesianChart(
                      // Configure X-axis (Status names)
                      primaryXAxis: const CategoryAxis(
                        labelIntersectAction: AxisLabelIntersectAction
                            .rotate45, // Rotate labels if they overlap
                        majorGridLines: MajorGridLines(
                            width:
                                0), // Hide vertical grid lines for cleaner look
                      ),
                      // Configure Y-axis (Count)
                      primaryYAxis: const NumericAxis(
                        minimum: 0, // Ensure Y-axis starts at 0
                        axisLine: AxisLine(width: 0), // Hide Y axis line itself
                        majorTickLines:
                            MajorTickLines(size: 0), // Hide Y axis tick marks
                        // interval: 1, // Optionally set interval if counts are small integers
                        // edgeLabelPlacement: EdgeLabelPlacement.shift, // Adjust label placement if needed
                      ),
                      series: <CartesianSeries<ChartData, String>>[
                        // Define column series (bar chart)
                        ColumnSeries<ChartData, String>(
                          dataSource: statusData, // Use prepared status data
                          xValueMapper: (ChartData data, _) =>
                              data.x, // Status name
                          yValueMapper: (ChartData data, _) => data.y, // Count
                          pointColorMapper: (ChartData data, _) =>
                              data.color, // Use status color for bars
                          // Configure data labels shown on top of bars
                          dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              textStyle: TextStyle(fontSize: 11)),
                          borderRadius: const BorderRadius.all(Radius.circular(
                              5)), // Add rounded corners to bars
                        )
                      ],
                      // Configure tooltips for bars
                      tooltipBehavior: TooltipBehavior(
                          enable: true), // Show tooltip on tap/hover
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper widget to create a consistent Card layout for each chart.
  Widget _buildChartCard({required String title, required Widget chart}) {
    return Card(
      elevation: 2, // Card shadow
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(16, 16, 16, 8), // Padding inside the card
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align title to the left
          children: [
            // Chart title text
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600), // Title styling
            ),
            const SizedBox(height: 16), // Space between title and chart
            // Container to hold the chart widget with a fixed height
            SizedBox(
                height: 300, // Standard height for chart containers
                child: chart // The actual chart widget (Pie or Cartesian)
                )
          ],
        ),
      ),
    );
  }
}
