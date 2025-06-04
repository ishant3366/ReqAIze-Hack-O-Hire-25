import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reqassist_logic.dart';

class RequirementsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReqAssist Pro',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.light,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _dismissWelcome() {
    setState(() {
      _showWelcome = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) {
      return WelcomeScreen(
        onGetStarted: _dismissWelcome,
        onSetApiKey: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsScreen()),
          );
          if (result == true) {
            setState(() {});
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ReqAssist Pro'),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
              if (result == true) {
                setState(() {});
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.description), text: 'Requirements'),
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatScreen(),
          RequirementsEditorScreen(),
          DashboardScreen(),
        ],
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSetApiKey;

  WelcomeScreen({required this.onGetStarted, required this.onSetApiKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 800),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: 24),
              Text(
                'Welcome to ReqAssist Pro',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Your AI-powered requirements engineering assistant',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Text(
                'ReqAssist Pro helps you draft, manage, and export software requirements using AI.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onSetApiKey,
                    icon: Icon(Icons.key),
                    label: Text('Settings'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                  SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: onGetStarted,
                    icon: Icon(Icons.arrow_forward),
                    label: Text('Get Started'),
                    style: FilledButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _modelName = 'mistral-large-latest';
  double _temperature = 0.6;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _modelName = prefs.getString('model_name') ?? 'mistral-large-latest';
        _temperature = prefs.getDouble('temperature') ?? 0.6;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('model_name', _modelName);
      await prefs.setDouble('temperature', _temperature);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_errorMessage!,
                            style: TextStyle(color: Colors.red.shade900)),
                      ),
                    Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('API Settings',
                                style: Theme.of(context).textTheme.titleLarge),
                            SizedBox(height: 16),
                            Text(
                                "API Key: Using hardcoded key (MISTRAL_API_KEY)"),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Model',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.model_training),
                              ),
                              value: _modelName,
                              items: [
                                DropdownMenuItem(
                                    value: 'mistral-large-latest',
                                    child: Text('Mistral Large (Latest)')),
                                DropdownMenuItem(
                                    value: 'mistral-medium',
                                    child: Text('Mistral Medium')),
                                DropdownMenuItem(
                                    value: 'mistral-small',
                                    child: Text('Mistral Small')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _modelName = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Generation Settings',
                                style: Theme.of(context).textTheme.titleLarge),
                            SizedBox(height: 16),
                            Text(
                                'Temperature: ${_temperature.toStringAsFixed(2)}'),
                            Slider(
                              value: _temperature,
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              label: _temperature.toStringAsFixed(2),
                              onChanged: (value) {
                                setState(() => _temperature = value);
                              },
                            ),
                            Text(
                              'Lower values produce more focused and deterministic outputs. Higher values produce more creative and varied outputs.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saveSettings,
                      child: Text('Save Settings'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final List<String> _templates = [
    'Create requirements for a mobile banking app',
    'Generate requirements for an e-commerce checkout process',
    'Draft requirements for a user authentication system',
    'Create requirements for a content management system',
    'Generate requirements for a patient management system for clinics',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Container(
              color: Colors.red.shade100,
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage)),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => setState(() => _errorMessage = ''),
                  )
                ],
              ),
            ),
          if (_messages.isEmpty)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Start by describing your project or requirements',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      Text(
                        'Try these templates:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _templates
                            .map((template) => ActionChip(
                                  label: Text(template),
                                  onPressed: () {
                                    _controller.text = template;
                                    _handleSubmitted();
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _messages[_messages.length - 1 - index];
                },
              ),
            ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor)),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Describe your project requirements...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSubmitted(),
                    enabled: !_isLoading,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isLoading ? null : _handleSubmitted,
                  tooltip: 'Generate Requirements',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmitted() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
        ),
      );
      _isLoading = true;
      _errorMessage = '';
    });

    List<Requirement> requirements = [];
    String additionalInfo = "";

    try {
      final prefs = await SharedPreferences.getInstance();
      final modelName = prefs.getString('model_name') ?? 'mistral-large-latest';
      final temperature = prefs.getDouble('temperature') ?? 0.6;

      final Map<String, dynamic> apiResult =
          await RequirementsService.getRequirementsFromMistral(
              text, modelName, temperature);

      requirements = apiResult['requirements'] as List<Requirement>;
      additionalInfo = apiResult['additionalInfo'] as String? ??
          "Generated requirements, test ideas, and code snippets.";

      // Store requirements in shared state
      RequirementsState.instance.updateRequirements(requirements);
    } catch (e) {
      print("API Error: $e. Using mock data instead.");
      setState(() {
        _errorMessage = "API Error: ${e.toString()}. Using Mock Data.";
      });
      requirements = RequirementsService.getMockRequirements();
      additionalInfo = "Default Mock Data Used.";
    }

    try {
      final Map<String, dynamic>? result =
          await RequirementsService.createDocuments(
              requirements, additionalInfo);
      if (result == null) {
        throw Exception("File creation returned null unexpectedly.");
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: "Here are the generated requirements artifacts:",
            isUser: false,
            onDownload: kIsWeb
                ? () => RequirementsService.downloadWebFiles(result, (msg) {
                      setState(() => _errorMessage = msg);
                    })
                : null,
            filePaths: kIsWeb ? null : result['filePaths'] as List<String>?,
            webFiles:
                kIsWeb ? result['webFiles'] as Map<String, Uint8List>? : null,
            requirements: requirements,
            additionalInfo: additionalInfo,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Sorry, there was an error generating or displaying the files.",
            isUser: false,
          ),
        );
        _errorMessage = "File Generation Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class RequirementsEditorScreen extends StatefulWidget {
  @override
  _RequirementsEditorScreenState createState() =>
      _RequirementsEditorScreenState();
}

class _RequirementsEditorScreenState extends State<RequirementsEditorScreen> {
  List<Requirement> _requirements = [];
  bool _isLoading = false;
  String? _searchQuery;
  String? _filterType;
  String? _filterMoscow;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _requirements = List.from(RequirementsState.instance.requirements);
  }

  @override
  Widget build(BuildContext context) {
    // Apply filters
    List<Requirement> displayedRequirements = _requirements;

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      displayedRequirements = displayedRequirements
          .where((req) =>
              req.reqNo.toLowerCase().contains(query) ||
              req.description.toLowerCase().contains(query))
          .toList();
    }

    if (_filterType != null) {
      displayedRequirements = displayedRequirements
          .where((req) => req.type == _filterType)
          .toList();
    }

    if (_filterMoscow != null) {
      displayedRequirements = displayedRequirements
          .where((req) => req.moscow == _filterMoscow)
          .toList();
    }

    if (_filterStatus != null) {
      displayedRequirements = displayedRequirements
          .where((req) => req.status == _filterStatus)
          .toList();
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requirements Editor',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search requirements...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.isEmpty ? null : value;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.filter_list),
                          onPressed: () {
                            _showFilterDialog();
                          },
                          tooltip: 'Filter Requirements',
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            _showAddEditRequirementDialog();
                          },
                          tooltip: 'Add Requirement',
                        ),
                        IconButton(
                          icon: Icon(Icons.file_download),
                          onPressed: _requirements.isEmpty
                              ? null
                              : _exportRequirements,
                          tooltip: 'Export Requirements',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _requirements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No requirements yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Generate requirements in the Chat tab or add them manually',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: Icon(Icons.add),
                              label: Text('Add Requirement'),
                              onPressed: () {
                                _showAddEditRequirementDialog();
                              },
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayedRequirements.length,
                        itemBuilder: (context, index) {
                          final req = displayedRequirements[index];
                          final originalIndex = _requirements.indexOf(req);

                          return Dismissible(
                            key: Key(req.reqNo),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              setState(() {
                                _requirements.removeAt(originalIndex);
                              });
                              RequirementsState.instance
                                  .removeRequirement(originalIndex);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Requirement deleted'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      setState(() {
                                        _requirements.insert(
                                            originalIndex, req);
                                      });
                                      RequirementsState.instance
                                          .updateRequirements(_requirements);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: ExpansionTile(
                                title: Text(req.reqNo),
                                subtitle: Text(req.type),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text(req.moscow),
                                      backgroundColor:
                                          RequirementsService.getMoscowColor(
                                              req.moscow),
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                    ),
                                    SizedBox(width: 8),
                                    Chip(
                                      label: Text(req.status),
                                      backgroundColor:
                                          RequirementsService.getStatusColor(
                                              req.status),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Description:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 8),
                                        Text(req.description),
                                        SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton.icon(
                                              icon: Icon(Icons.edit),
                                              label: Text('Edit'),
                                              onPressed: () {
                                                _showAddEditRequirementDialog(
                                                  requirement: req,
                                                  index: originalIndex,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempType = _filterType;
        String? tempMoscow = _filterMoscow;
        String? tempStatus = _filterStatus;

        return AlertDialog(
          title: Text('Filter Requirements'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                value: tempType,
                items: [
                  DropdownMenuItem(value: null, child: Text('All Types')),
                  DropdownMenuItem(
                      value: 'Functional', child: Text('Functional')),
                  DropdownMenuItem(
                      value: 'Non-Functional', child: Text('Non-Functional')),
                ],
                onChanged: (value) {
                  tempType = value;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                value: tempMoscow,
                items: [
                  DropdownMenuItem(value: null, child: Text('All Priorities')),
                  DropdownMenuItem(
                      value: 'Must Have', child: Text('Must Have')),
                  DropdownMenuItem(
                      value: 'Should Have', child: Text('Should Have')),
                  DropdownMenuItem(
                      value: 'Could Have', child: Text('Could Have')),
                  DropdownMenuItem(
                      value: 'Won\'t Have', child: Text('Won\'t Have')),
                ],
                onChanged: (value) {
                  tempMoscow = value;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                value: tempStatus,
                items: [
                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(
                      value: 'In Progress', child: Text('In Progress')),
                  DropdownMenuItem(
                      value: 'Completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                ],
                onChanged: (value) {
                  tempStatus = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterType = tempType;
                  _filterMoscow = tempMoscow;
                  _filterStatus = tempStatus;
                });
                Navigator.pop(context);
              },
              child: Text('Apply'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterType = null;
                  _filterMoscow = null;
                  _filterStatus = null;
                });
                Navigator.pop(context);
              },
              child: Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditRequirementDialog({Requirement? requirement, int? index}) {
    final isEditing = requirement != null;

    final formKey = GlobalKey<FormState>();
    final reqNoController = TextEditingController(
        text:
            isEditing ? requirement.reqNo : 'REQ-${_requirements.length + 1}');
    final descriptionController =
        TextEditingController(text: isEditing ? requirement.description : '');
    String type = isEditing ? requirement.type : 'Functional';
    String moscow = isEditing ? requirement.moscow : 'Must Have';
    String status = isEditing ? requirement.status : 'Pending';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Requirement' : 'Add Requirement'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: reqNoController,
                    decoration: InputDecoration(
                      labelText: 'Requirement ID',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a requirement ID';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    value: type,
                    items: [
                      DropdownMenuItem(
                          value: 'Functional', child: Text('Functional')),
                      DropdownMenuItem(
                          value: 'Non-Functional',
                          child: Text('Non-Functional')),
                    ],
                    onChanged: (value) {
                      type = value!;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Priority (MoSCoW)',
                      border: OutlineInputBorder(),
                    ),
                    value: moscow,
                    items: [
                      DropdownMenuItem(
                          value: 'Must Have', child: Text('Must Have')),
                      DropdownMenuItem(
                          value: 'Should Have', child: Text('Should Have')),
                      DropdownMenuItem(
                          value: 'Could Have', child: Text('Could Have')),
                      DropdownMenuItem(
                          value: 'Won\'t Have', child: Text('Won\'t Have')),
                    ],
                    onChanged: (value) {
                      moscow = value!;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    value: status,
                    items: [
                      DropdownMenuItem(
                          value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'In Progress', child: Text('In Progress')),
                      DropdownMenuItem(
                          value: 'Completed', child: Text('Completed')),
                      DropdownMenuItem(
                          value: 'Rejected', child: Text('Rejected')),
                    ],
                    onChanged: (value) {
                      status = value!;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newRequirement = Requirement(
                    reqNo: reqNoController.text,
                    type: type,
                    description: descriptionController.text,
                    moscow: moscow,
                    status: status,
                  );

                  setState(() {
                    if (isEditing && index != null) {
                      _requirements[index] = newRequirement;
                      RequirementsState.instance
                          .updateRequirement(index, newRequirement);
                    } else {
                      _requirements.add(newRequirement);
                      RequirementsState.instance.addRequirement(newRequirement);
                    }
                  });

                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportRequirements() async {
    try {
      setState(() => _isLoading = true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final excelBytes =
          await RequirementsService.createExcelBytes(_requirements);
      final markdownContent =
          RequirementsService.generateMarkdownContent(_requirements);

      if (kIsWeb) {
        final Map<String, Uint8List> webFiles = {};
        webFiles['requirements_$timestamp.xlsx'] = excelBytes!;
        webFiles['requirements_doc_$timestamp.md'] =
            Uint8List.fromList(utf8.encode(markdownContent));

        RequirementsService.downloadWebFiles(webFiles, (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        });
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final dirPath = directory.path;
        final excelPath = '$dirPath/requirements_$timestamp.xlsx';
        final excelFile = File(excelPath);
        await excelFile.writeAsBytes(excelBytes!, flush: true);

        final docPath = '$dirPath/requirements_doc_$timestamp.md';
        final docFile = File(docPath);
        await docFile.writeAsString(markdownContent, flush: true);

        // Use share_plus to share the files
        final xFiles = [excelPath, docPath].map((path) => XFile(path)).toList();
        await Share.shareXFiles(xFiles, text: 'Generated Requirements Files');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting requirements: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final requirements = RequirementsState.instance.requirements;

    // Count types of requirements
    int functionalCount = 0;
    int nonFunctionalCount = 0;

    // Count MoSCoW priorities
    Map<String, int> moscowCounts = {
      'Must Have': 0,
      'Should Have': 0,
      'Could Have': 0,
      'Won\'t Have': 0,
    };

    // Count statuses
    Map<String, int> statusCounts = {
      'Pending': 0,
      'In Progress': 0,
      'Completed': 0,
      'Rejected': 0,
    };

    for (final req in requirements) {
      if (req.type == 'Functional') {
        functionalCount++;
      } else if (req.type == 'Non-Functional') {
        nonFunctionalCount++;
      }

      if (moscowCounts.containsKey(req.moscow)) {
        moscowCounts[req.moscow] = moscowCounts[req.moscow]! + 1;
      }

      if (statusCounts.containsKey(req.status)) {
        statusCounts[req.status] = statusCounts[req.status]! + 1;
      }
    }

    return Scaffold(
      body: requirements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    size: 64,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No data to display',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Generate requirements in the Chat tab to view analytics',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requirements Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Summary of your ${requirements.length} requirements',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 24),

                  // Requirements Type Distribution
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requirements by Type',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: functionalCount.toDouble(),
                                    title: 'Functional\n$functionalCount',
                                    color: Colors.blue,
                                    radius: 80,
                                  ),
                                  PieChartSectionData(
                                    value: nonFunctionalCount.toDouble(),
                                    title:
                                        'Non-Functional\n$nonFunctionalCount',
                                    color: Colors.green,
                                    radius: 80,
                                  ),
                                ],
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // MoSCoW Distribution
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requirements by Priority',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: moscowCounts.values.isEmpty
                                    ? 1
                                    : (moscowCounts.values
                                            .reduce((a, b) => a > b ? a : b) *
                                        1.2),
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        String text = '';
                                        switch (value.toInt()) {
                                          case 0:
                                            text = 'Must';
                                            break;
                                          case 1:
                                            text = 'Should';
                                            break;
                                          case 2:
                                            text = 'Could';
                                            break;
                                          case 3:
                                            text = 'Won\'t';
                                            break;
                                        }
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(text),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: [
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [
                                      BarChartRodData(
                                        toY: moscowCounts['Must Have']!
                                            .toDouble(),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: moscowCounts['Should Have']!
                                            .toDouble(),
                                        color: Colors.orange,
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 2,
                                    barRods: [
                                      BarChartRodData(
                                        toY: moscowCounts['Could Have']!
                                            .toDouble(),
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 3,
                                    barRods: [
                                      BarChartRodData(
                                        toY: moscowCounts['Won\'t Have']!
                                            .toDouble(),
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Status Distribution
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requirements by Status',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: statusCounts.values.isEmpty
                                    ? 1
                                    : (statusCounts.values
                                            .reduce((a, b) => a > b ? a : b) *
                                        1.2),
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        String text = '';
                                        switch (value.toInt()) {
                                          case 0:
                                            text = 'Pending';
                                            break;
                                          case 1:
                                            text = 'In Progress';
                                            break;
                                          case 2:
                                            text = 'Completed';
                                            break;
                                          case 3:
                                            text = 'Rejected';
                                            break;
                                        }
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(text,
                                              style: TextStyle(fontSize: 10)),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: [
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [
                                      BarChartRodData(
                                        toY:
                                            statusCounts['Pending']!.toDouble(),
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: statusCounts['In Progress']!
                                            .toDouble(),
                                        color: Colors.amber,
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 2,
                                    barRods: [
                                      BarChartRodData(
                                        toY: statusCounts['Completed']!
                                            .toDouble(),
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 3,
                                    barRods: [
                                      BarChartRodData(
                                        toY: statusCounts['Rejected']!
                                            .toDouble(),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Requirement Validation Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requirement Validation',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 16),
                          RequirementsService.buildValidationSummary(
                              requirements),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final VoidCallback? onDownload;
  final List<String>? filePaths;
  final Map<String, Uint8List>? webFiles;
  final List<Requirement>? requirements;
  final String? additionalInfo;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.onDownload,
    this.filePaths,
    this.webFiles,
    this.requirements,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isUser
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'You' : 'ReqAssist AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(text),
                if (requirements != null && requirements!.isNotEmpty) ...[
                  SizedBox(height: 16.0),
                  Text(
                    'Generated Requirements:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    height: 200,
                    child: ListView.builder(
                      itemCount: requirements!.length,
                      itemBuilder: (context, index) {
                        final req = requirements![index];
                        return ListTile(
                          title: Text(req.reqNo),
                          subtitle: Text(
                            req.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Chip(
                            label: Text(req.moscow),
                            backgroundColor:
                                RequirementsService.getMoscowColor(req.moscow),
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (additionalInfo != null && additionalInfo!.isNotEmpty) ...[
                  SizedBox(height: 16.0),
                  Text(
                    'Additional Information:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      additionalInfo!,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Additional Information'),
                          content: SingleChildScrollView(
                            child: Text(additionalInfo!),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text('View Full Details'),
                  ),
                ],
                if (onDownload != null || filePaths != null) ...[
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      if (onDownload != null)
                        ElevatedButton.icon(
                          icon: Icon(Icons.download),
                          label: Text('Download Files'),
                          onPressed: onDownload,
                        ),
                      if (filePaths != null) ...[
                        SizedBox(width: 8.0),
                        ElevatedButton.icon(
                          icon: Icon(Icons.share),
                          label: Text('Share Files'),
                          onPressed: () async {
                            final xFiles =
                                filePaths!.map((path) => XFile(path)).toList();
                            await Share.shareXFiles(xFiles,
                                text: 'Generated Requirements Files');
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
