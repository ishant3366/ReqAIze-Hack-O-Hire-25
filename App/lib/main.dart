import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// --- Import the screen files ---
import 'docupload.dart'; // Contains DocuMindAIApp()
import 'reqassist_ui.dart'; // Contains RequirementsApp()
import 'analyzer.dart'; // Assume contains DocumentAnalyzerPage()
import 'history.dart'; // Assume contains FileListScreen()
// --- End of imports ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Firebase Initialization (Keep as is) ---
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey:
                "AIzaSyBo7wqKnzZdcNOTWJda2wThgbQlilJWl_w", // Replace with your actual API key
            authDomain: "reqaize-698c3.firebaseapp.com",
            projectId: "reqaize-698c3",
            storageBucket: "reqaize-698c3.firebasestorage.app",
            messagingSenderId: "1082633324628",
            appId: "1:1082633324628:web:11740576b9bafa7d9385c1",
            measurementId: "G-TG5LCDJB5L"));
  } else {
    await Firebase.initializeApp();
  }
  // --- End of Firebase Initialization ---

  runApp(MyApp());
}

// Placeholder classes for missing screens (Remove these if the actual files exist)

// --- End of Placeholder classes ---

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReqAIze',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      // Example of using named routes if needed later (optional)
      // routes: {
      //   '/home': (context) => const HomeScreen(),
      //   '/upload': (context) => DocuMindAIApp(),
      //   '/analyzer': (context) => DocumentAnalyzerPage(),
      //   '/history': (context) => FileListScreen(),
      //   '/requirements': (context) => RequirementsApp(),
      // },
      // initialRoute: '/home',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Navigation Helper Function ---
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  // --- End of Navigation Helper ---

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Enhanced background with more gradients and animated elements
          _buildEnhancedBackground(screenWidth, screenHeight),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Enhanced top section with glass morphism
                _buildEnhancedTopSection(context),

                // Content area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.03,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upload Document Card - enhanced with glass morphism
                        _buildEnhancedUploadCard(context),

                        SizedBox(height: screenHeight * 0.035),

                        // Section Title
                        _buildSectionHeader(
                            context, "Core Features", "See All"),

                        SizedBox(height: screenHeight * 0.02),

                        // Enhanced Feature Grid with more modern styling
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: isLandscape ? 1.8 : 1.1,
                          crossAxisSpacing: screenWidth * 0.04,
                          mainAxisSpacing: screenWidth * 0.04,
                          children: [
                            // --- Document AI Grid Item (Existing Navigation) ---
                            _buildEnhancedFeatureGridItem(
                              context,
                              "Document AI",
                              Icons.smart_toy_outlined,
                              [
                                const Color(0xFF6366F1),
                                const Color(0xFF8B5CF6),
                                const Color(0xFFA78BFA)
                              ],
                              "Process your documents with AI",
                              onTap: () {
                                // Existing navigation to RequirementsApp - kept as is from original code
                                // If this should go elsewhere, change RequirementsApp() below
                                _navigateTo(context, RequirementsApp());
                              },
                            ),
                            // --- Analysis Grid Item (Requirement 1) ---
                            _buildEnhancedFeatureGridItem(
                              context,
                              "AutoTest",
                              Icons.auto_fix_high_sharp,
                              [
                                const Color(0xFF0EA5E9),
                                const Color(0xFF38BDF8),
                                const Color(0xFF7DD3FC)
                              ],
                              "Automation, Quality, Tracking",
                              onTap: () {
                                _navigateTo(context,
                                    DocumentAnalyzerPage()); // Navigate to DocumentAnalyzerPage
                              },
                            ),
                            // --- Insights Grid Item (Requirement 2) ---
                            _buildEnhancedFeatureGridItem(
                              context,
                              "History",
                              Icons.history,
                              [
                                const Color(0xFF10B981),
                                const Color(0xFF34D399),
                                const Color(0xFF6EE7B7)
                              ],
                              "Retrieve your files",
                              onTap: () {
                                _navigateTo(context,
                                    FileListScreen()); // Navigate to FileListScreen
                              },
                            ),
                            // --- Templates Grid Item (No navigation specified) ---
                            _buildEnhancedFeatureGridItem(
                              context,
                              "Jira",
                              Icons.design_services_outlined,
                              [
                                const Color(0xFFF59E0B),
                                const Color(0xFFFBBF24),
                                const Color(0xFFFCD34D)
                              ],
                              "Project management",
                              onTap: () {
                                // Add navigation if needed for Templates
                                print("Templates Tapped");
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.035),

                        _buildSectionHeader(
                            context, "Recent Activity", "View All"),

                        SizedBox(height: screenHeight * 0.02),

                        // Enhanced Document Items with glass morphism (Keep as is)
                        _buildEnhancedDocumentItem(
                          context,
                          "Requirements.doc",
                          "2 hours ago",
                          "Processing",
                          const Color(0xFF6366F1),
                          Icons.hourglass_top_outlined,
                          progress: 0.6,
                        ),
                        _buildEnhancedDocumentItem(
                          context,
                          "Project Scope.pdf",
                          "5 hours ago",
                          "Completed",
                          const Color(0xFF10B981),
                          Icons.check_circle_outline,
                        ),
                        _buildEnhancedDocumentItem(
                          context,
                          "Meeting Notes.doc",
                          "Yesterday",
                          "Completed",
                          const Color(0xFF10B981),
                          Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Enhanced Floating Action Button with pulse animation (Requirement 5)
          _buildEnhancedFAB(context),

          // Enhanced Bottom Navigation Bar with glass morphism (Requirements 3 & 4)
          _buildEnhancedNavBar(context),
        ],
      ),
    );
  }

  // --- Widget Builder Functions (Keep most as is, modify where navigation is added) ---

  Widget _buildEnhancedBackground(double screenWidth, double screenHeight) {
    // ... (Keep existing background code) ...
    return Stack(
      children: [
        // Multiple gradient blobs strategically positioned
        Positioned(
          top: screenHeight * -0.15,
          right: screenWidth * -0.2,
          child: Container(
            width: screenWidth * 0.6,
            height: screenWidth * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFECB2F5),
                  const Color(0xFFECB2F5).withOpacity(0.5),
                  const Color(0x00ECB2F5),
                ],
                stops: const [0.2, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: screenHeight * -0.12,
          right: screenWidth * -0.12,
          child: Container(
            width: screenWidth * 0.55,
            height: screenWidth * 0.55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFBBF7D0),
                  const Color(0xFFBBF7D0).withOpacity(0.5),
                  const Color(0x00BBF7D0),
                ],
                stops: const [0.2, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: screenHeight * 0.3,
          left: screenWidth * -0.15,
          child: Container(
            width: screenWidth * 0.5,
            height: screenWidth * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFBAE6FD),
                  const Color(0xFFBAE6FD).withOpacity(0.5),
                  const Color(0x00BAE6FD),
                ],
                stops: const [0.2, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: screenHeight * 0.4,
          left: screenWidth * 0.5,
          child: Container(
            width: screenWidth * 0.3,
            height: screenWidth * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFED7AA),
                  const Color(0xFFFED7AA).withOpacity(0.5),
                  const Color(0x00FED7AA),
                ],
                stops: const [0.2, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Animated floating patterns
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Positioned(
              top: screenHeight * 0.2 + (_animation.value * 20),
              right: screenWidth * 0.15,
              child: Opacity(
                opacity: 0.7 - (_animation.value * 0.3),
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Positioned(
              bottom: screenHeight * 0.3 + (_animation.value * 15),
              left: screenWidth * 0.2,
              child: Opacity(
                opacity: 0.6 - (_animation.value * 0.2),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            );
          },
        ),
        // Subtle mesh gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.7),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.5),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTopSection(BuildContext context) {
    // ... (Keep existing top section code) ...
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(screenWidth * 0.08),
        bottomRight: Radius.circular(screenWidth * 0.08),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.025,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(screenWidth * 0.08),
              bottomRight: Radius.circular(screenWidth * 0.08),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: screenWidth * 0.1,
                        height: screenWidth * 0.1,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                              Color(0xFFC084FC),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.06,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Text(
                        "ReqAIze",
                        style: TextStyle(
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                              ],
                            ).createShader(
                              Rect.fromLTWH(0, 0, screenWidth * 0.2, 0),
                            ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: screenWidth * 0.1,
                    height: screenWidth * 0.1,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                          Color(0xFFA78BFA),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "S", // Placeholder for User Initial
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                "Welcome, Suresh", // Placeholder Name
                style: TextStyle(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [
                        Color(0xFF1E293B),
                        Color(0xFF334155),
                      ],
                    ).createShader(
                      Rect.fromLTWH(0, 0, screenWidth * 0.45, 0),
                    ),
                ),
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                "What's your document needs today?",
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              _buildAnimatedProgressBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedProgressBar(BuildContext context) {
    // ... (Keep existing progress bar code) ...
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.01,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        color: const Color(0xFFEEF2FF),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Example: Make progress dynamic based on animation or state
          double progressValue =
              0.6 + (_animation.value * 0.1); // Example dynamic progress
          return Row(
            children: [
              Container(
                width:
                    screenWidth * 0.8 * progressValue, // Use calculated width
                constraints: BoxConstraints(
                    maxWidth: screenWidth * 0.8), // Max width constraint
                height: screenHeight * 0.01,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFA78BFA),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnhancedUploadCard(BuildContext context) {
    // --- This card already navigates to DocuMindAIApp, keep as is ---
    // ... (Keep existing upload card code) ...
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        // Navigate to DocuMindAIApp when tapped (Requirement 3 is handled by Navbar)
        // This card also goes to DocuMindAIApp as per original code
        _navigateTo(context, DocuMindAIApp());
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(screenWidth * 0.06),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.03,
          ),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFA78BFA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _animation.value * 3),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: screenWidth * 0.08,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: screenWidth * 0.05),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upload documents",
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                      "Get instant AI analysis",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: const Color(0xFF64748B),
                        letterSpacing: -0.1,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      "PDF, DOC, DOCX, TXT",
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.1),
                      const Color(0xFF8B5CF6).withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  size: screenWidth * 0.05,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, String actionText) {
    // ... (Keep existing section header code) ...
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: screenWidth * 0.01,
              height: screenWidth * 0.05,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.005),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        // Make the action text tappable if needed
        InkWell(
          onTap: () {
            print("$actionText Tapped for $title");
            // Add navigation or action for "See All" / "View All" if required
          },
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.01,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: screenWidth * 0.033,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6366F1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedFeatureGridItem(
    BuildContext context,
    String title,
    IconData icon,
    List<Color> gradientColors,
    String subtitle, {
    Function()? onTap, // Ensure onTap is accepted
  }) {
    // --- Add GestureDetector wrapper for onTap functionality ---
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      // Wrap with GestureDetector
      onTap: onTap, // Use the provided onTap callback
      child: Container(
        // ... (Keep existing grid item decoration and layout code) ...
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.06),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Abstract pattern for visual interest
            Positioned(
              top: -screenWidth * 0.05,
              right: -screenWidth * 0.05,
              child: Container(
                width: screenWidth * 0.2,
                height: screenWidth * 0.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -screenWidth * 0.07,
              left: -screenWidth * 0.04,
              child: Container(
                width: screenWidth * 0.18,
                height: screenWidth * 0.18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: screenWidth * 0.065,
                      color: Colors.white,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.042,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.006),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: -0.1,
                        ),
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
  }

  Widget _buildEnhancedDocumentItem(
    BuildContext context,
    String title,
    String time,
    String status,
    Color statusColor,
    IconData statusIcon, {
    double? progress,
  }) {
    // ... (Keep existing document item code) ...
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.045),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: screenWidth * 0.13,
                  height: screenWidth * 0.13,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF1F5F9),
                        const Color(0xFFE2E8F0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      title.endsWith('.pdf')
                          ? Icons.picture_as_pdf_outlined
                          : Icons.description_outlined,
                      size: screenWidth * 0.06,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.042,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: screenWidth * 0.035,
                            color: const Color(0xFF64748B),
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: screenWidth * 0.033,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: status == "Processing"
                        ? const Color(0xFFEEF2FF)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    boxShadow: [
                      BoxShadow(
                        color: status == "Processing"
                            ? const Color(0xFF6366F1).withOpacity(0.1)
                            : const Color(0xFF10B981).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: screenWidth * 0.04,
                        color: statusColor,
                      ),
                      SizedBox(width: screenWidth * 0.015),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: screenWidth * 0.033,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              SizedBox(height: screenHeight * 0.018),
              Stack(
                children: [
                  // Background shimmer effect for progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    child: Container(
                      height: screenHeight * 0.01,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFEEF2FF),
                            const Color(0xFFD8DCFD),
                            const Color(0xFFEEF2FF),
                          ],
                          stops: const [0.35, 0.5, 0.65],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          // Subtle shimmer effect moving across the background
                          return Transform.translate(
                            offset: Offset(
                                -screenWidth * 0.1 +
                                    (_animation.value * screenWidth * 0.9),
                                0),
                            child: Container(
                              width: screenWidth * 0.1,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Actual progress
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      // Add a slight pulsing effect to the progress
                      double pulsingProgress = progress +
                          (math.sin(_animation.value * math.pi) *
                              0.02); // Use sin for smooth pulse
                      if (pulsingProgress > 1) pulsingProgress = 1;
                      if (pulsingProgress < 0) pulsingProgress = 0;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        child: Container(
                          height: screenHeight * 0.01,
                          width: screenWidth *
                              0.8 *
                              pulsingProgress, // Adjust width based on parent constraints
                          constraints:
                              BoxConstraints(maxWidth: screenWidth * 0.8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor,
                                statusColor.withOpacity(0.7),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFAB(BuildContext context) {
    // --- Add GestureDetector for tap functionality (Requirement 5) ---
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      bottom:
          screenHeight * 0.08, // Adjust position to avoid overlap with NavBar
      right: screenWidth * 0.05,
      child: GestureDetector(
        // Wrap the animated builder content with GestureDetector
        onTap: () {
          _navigateTo(
              context, RequirementsApp()); // Navigate to RequirementsApp
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            // Create a pulse effect
            return Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing background
                Container(
                  height: screenWidth * 0.17 + (_animation.value * 8),
                  width: screenWidth * 0.17 + (_animation.value * 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1)
                            .withOpacity(0.2 - (_animation.value * 0.15)),
                        const Color(0xFF8B5CF6)
                            .withOpacity(0.2 - (_animation.value * 0.15)),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    // Use circle for smoother pulse appearance
                    shape: BoxShape.circle,
                    // borderRadius: BorderRadius.circular(screenWidth * 0.06 + (_animation.value * 4)),
                  ),
                ),
                // Main button
                Container(
                  height: screenWidth * 0.15,
                  width: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                        Color(0xFFA78BFA),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    // borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    shape: BoxShape.circle, // Match pulsing background shape
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.35),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Transform.rotate(
                    angle: _animation.value * 0.1,
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: screenWidth * 0.07,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedNavBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    int _selectedIndex = 0; // Assuming Home is initially selected

    // --- Define Navigation Actions for Navbar Items ---
    final List<Function()> navActions = [
      () => print("Home Tapped"), // Home - No navigation needed from Home
      () => _navigateTo(context, DocuMindAIApp()), // Docs (Requirement 3)
      () {}, // Placeholder for the FAB space
      () => _navigateTo(context, DocumentAnalyzerPage()), // AI (Requirement 4)
      () => print("Settings Tapped"), // Settings - No navigation specified
    ];

    // --- Define Navbar Items ---
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.home_rounded, 'label': "Home"},
      {'icon': Icons.description_outlined, 'label': "Docs"},
      {'isSpacer': true}, // Represents the space for the FAB
      {'icon': Icons.analytics_outlined, 'label': "AI"},
      {'icon': Icons.settings_outlined, 'label': "Settings"},
    ];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(screenWidth * 0.08),
          topRight: Radius.circular(screenWidth * 0.08),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: screenHeight * 0.08,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(screenWidth * 0.08),
                topRight: Radius.circular(screenWidth * 0.08),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                if (item['isSpacer'] == true) {
                  // Render the spacer for the FAB
                  return SizedBox(width: screenWidth * 0.15);
                } else {
                  // Render a regular nav item
                  bool isActive = _selectedIndex ==
                      index; // Determine if the item is active
                  return _buildEnhancedNavItem(
                    context,
                    item['icon'],
                    item['label'],
                    isActive,
                    onTap: navActions[index], // Assign the corresponding action
                  );
                }
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedNavItem(
      BuildContext context, IconData icon, String label, bool isActive,
      {Function()? onTap} // Add onTap callback
      ) {
    // --- Add GestureDetector wrapper for onTap functionality ---
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      // Wrap the Column with GestureDetector
      onTap: onTap, // Use the provided onTap callback
      behavior: HitTestBehavior.opaque, // Make sure the whole area is tappable
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // Apply subtle animation to active icon container if desired
              double scaleFactor =
                  isActive ? 1.0 + (_animation.value * 0.05) : 1.0;
              return Transform.scale(
                scale: scaleFactor,
                child: Container(
                  width: screenWidth * 0.12,
                  height: screenHeight * 0.04,
                  decoration: isActive
                      ? BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1),
                              const Color(0xFF8B5CF6),
                              const Color(0xFFA78BFA),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          // Inactive style
                          color: Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                        ),
                  child: Center(
                    child: Icon(
                      icon,
                      // Animate size slightly if active
                      size: isActive
                          ? screenWidth * 0.055 +
                              (math.sin(_animation.value * math.pi) * 2.0)
                          : screenWidth * 0.055,
                      color: isActive ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: screenHeight * 0.006),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color:
                  isActive ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // --- Unused Helper Widgets (Keep or remove as needed) ---
  Widget _buildNeumorphicButton(
      BuildContext context, IconData icon, String label, Color iconColor,
      {void Function()? onTap}) {
    // ... (Keep existing neumorphic button code) ...
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color:
              Colors.white, // Or use scaffold background color for better blend
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(5, 5),
              blurRadius: 15,
              spreadRadius: 1,
            ),
            BoxShadow(
              color:
                  Colors.white.withOpacity(0.7), // Adjust white shadow opacity
              offset: const Offset(-5, -5),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.025),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: screenWidth * 0.06,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticleAnimation(BuildContext context) {
    // ... (Keep existing particle animation code) ...
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: List.generate(10, (index) {
            // Adjust particle count if needed
            final random = math.Random(index);
            final size = random.nextDouble() * 6 + 2; // Size range 2-8
            // Ensure particles stay within bounds and animate smoothly
            final initialX = random.nextDouble() * screenWidth;
            final initialY = random.nextDouble() * screenHeight;
            // Use sine wave for smoother vertical oscillation
            final yOffset =
                math.sin((_animation.value + (index * 0.2)) * math.pi * 2) * 15;
            final opacity = (random.nextDouble() * 0.4 + 0.1) *
                (1.0 - _animation.value); // Fade out

            return Positioned(
              left: initialX,
              top: initialY + yOffset,
              child: Opacity(
                opacity: opacity < 0 ? 0 : opacity, // Ensure opacity >= 0
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                      const Color(0xFF10B981),
                      const Color(0xFF0EA5E9),
                    ][index % 4]
                        .withOpacity(0.7), // Add slight transparency
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
