import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DocuMind AI',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
        primaryColor: const Color(0xFF6366F1),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _shimmerController;
  late AnimationController _floatingBlobsController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _floatingBlobsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _floatingBlobsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenPadding = size.width * 0.05;

    return Scaffold(
      body: Stack(
        children: [
          // Enhanced Animated Background
          EnhancedBackground(controller: _floatingBlobsController),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Section with Welcome & AI Avatar
                Padding(
                  padding: EdgeInsets.all(screenPadding),
                  child: GlassContainer(
                    padding: EdgeInsets.all(screenPadding * 0.8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GradientText(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: size.width * 0.07,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6)
                                    ],
                                  ),
                                ),
                                SizedBox(height: size.height * 0.01),
                                Text(
                                  'What would you like to process today?',
                                  style: TextStyle(
                                    color: const Color(0xFF64748B),
                                    fontSize: size.width * 0.035,
                                  ),
                                ),
                              ],
                            ),
                            AIAvatar(size: size),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent Documents Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Documents',
                              style: TextStyle(
                                color: const Color(0xFF1E293B),
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ShimmerButton(
                              controller: _shimmerController,
                              label: 'View All',
                              onTap: () {},
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.02),

                        // Enhanced Upload Card
                        GestureDetector(
                          onTap: () {},
                          child: EnhancedUploadCard(
                              screenPadding: screenPadding, size: size),
                        ),

                        // Recent document preview
                        SizedBox(height: size.height * 0.02),
                        SizedBox(
                          height: size.height * 0.12,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (int i = 0; i < 3; i++)
                                RecentDocCard(
                                  title: 'Document ${i + 1}',
                                  date: '${i + 1} days ago',
                                  color: [
                                    const Color(0xFF6366F1),
                                    const Color(0xFF0EA5E9),
                                    const Color(0xFF10B981),
                                  ][i],
                                  size: size,
                                  progress: (i + 1) * 0.25,
                                  controller: _shimmerController,
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: size.height * 0.03),

                        // Features Grid with Section Label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'What can I help you with?',
                              style: TextStyle(
                                color: const Color(0xFF1E293B),
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            PopularityBadge(size: size),
                          ],
                        ),
                        SizedBox(height: size.height * 0.02),

                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: screenPadding * 0.8,
                            crossAxisSpacing: screenPadding * 0.8,
                            childAspectRatio: 1,
                            children: [
                              EnhancedFeatureCard(
                                title: 'Summarize',
                                subtitle: 'Get the key points',
                                icon: Icons.summarize,
                                gradientColors: const [
                                  Color(0xFF0EA5E9),
                                  Color(0xFF38BDF8),
                                ],
                                onTap: () {},
                              ),
                              EnhancedFeatureCard(
                                title: 'Extract',
                                subtitle: 'Get specific data',
                                icon: Icons.apps,
                                gradientColors: const [
                                  Color(0xFF10B981),
                                  Color(0xFF34D399),
                                ],
                                onTap: () {},
                                isPopular: true,
                              ),
                              EnhancedFeatureCard(
                                title: 'Query',
                                subtitle: 'Ask anything',
                                icon: Icons.question_answer,
                                gradientColors: const [
                                  Color(0xFFF59E0B),
                                  Color(0xFFFBBF24),
                                ],
                                onTap: () {},
                              ),
                              EnhancedFeatureCard(
                                title: 'Analyze',
                                subtitle: 'Deep insights',
                                icon: Icons.analytics,
                                gradientColors: const [
                                  Color(0xFF6366F1),
                                  Color(0xFFA78BFA),
                                ],
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Enhanced Floating Action Button
          Positioned(
            right: screenPadding,
            bottom: size.height * 0.1 + screenPadding,
            child: EnhancedFAB(
              onPressed: () {},
              icon: Icons.add,
              shimmerController: _shimmerController,
            ),
          ),

          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: EnhancedBottomNavBar(
              selectedIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Enhanced AI Avatar ---
class AIAvatar extends StatefulWidget {
  final Size size;

  const AIAvatar({Key? key, required this.size}) : super(key: key);

  @override
  _AIAvatarState createState() => _AIAvatarState();
}

class _AIAvatarState extends State<AIAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: size.width * 0.14,
                height: size.width * 0.14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.7),
                      const Color(0xFF6366F1).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // AI Avatar
        Container(
          width: size.width * 0.12,
          height: size.width * 0.12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: size.width * 0.06,
            ),
          ),
        ),
        // Online indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: size.width * 0.03,
            height: size.width * 0.03,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Enhanced Upload Card ---
class EnhancedUploadCard extends StatefulWidget {
  final double screenPadding;
  final Size size;

  const EnhancedUploadCard({
    Key? key,
    required this.screenPadding,
    required this.size,
  }) : super(key: key);

  @override
  _EnhancedUploadCardState createState() => _EnhancedUploadCardState();
}

class _EnhancedUploadCardState extends State<EnhancedUploadCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.all(widget.screenPadding),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -3 * sin(_bounceAnimation.value * pi)),
                child: Container(
                  padding: EdgeInsets.all(widget.screenPadding * 0.6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA78BFA)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.white,
                    size: widget.size.width * 0.08,
                  ),
                ),
              );
            },
          ),
          SizedBox(width: widget.size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Document',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: widget.size.width * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'PDF, Word, Images, or Text',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: widget.size.width * 0.032,
                  ),
                ),
                SizedBox(height: widget.size.height * 0.01),
                Row(
                  children: [
                    _buildFormatBadge('PDF', const Color(0xFFF43F5E)),
                    SizedBox(width: widget.size.width * 0.02),
                    _buildFormatBadge('DOCX', const Color(0xFF0EA5E9)),
                    SizedBox(width: widget.size.width * 0.02),
                    _buildFormatBadge('JPG', const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              color: const Color(0xFF6366F1),
              size: widget.size.width * 0.04,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: widget.size.width * 0.025,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// --- Recent Document Card ---
class RecentDocCard extends StatelessWidget {
  final String title;
  final String date;
  final Color color;
  final Size size;
  final double progress;
  final AnimationController controller;

  const RecentDocCard({
    Key? key,
    required this.title,
    required this.date,
    required this.color,
    required this.size,
    required this.progress,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width * 0.35,
      margin: EdgeInsets.only(right: size.width * 0.03),
      child: GlassContainer(
        padding: EdgeInsets.all(size.width * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description,
                    color: color,
                    size: size.width * 0.04,
                  ),
                ),
                SizedBox(width: size.width * 0.02),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: size.width * 0.035,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.005),
            Text(
              date,
              style: TextStyle(
                fontSize: size.width * 0.025,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: size.height * 0.01),
            AnimatedProgressBar(
              progress: progress,
              color: color,
              controller: controller,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Animated Progress Bar ---
class AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final AnimationController controller;

  const AnimatedProgressBar({
    Key? key,
    required this.progress,
    required this.color,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final shimmerValue = sin(controller.value * 2 * pi);

        return Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withOpacity(0.6 + 0.4 * shimmerValue),
                    color,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: -1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Enhanced Feature Card Widget ---
class EnhancedFeatureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool isPopular;

  const EnhancedFeatureCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.isPopular = false,
  }) : super(key: key);

  @override
  _EnhancedFeatureCardState createState() => _EnhancedFeatureCardState();
}

class _EnhancedFeatureCardState extends State<EnhancedFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradientColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradientColors[0]
                            .withOpacity(_isPressed ? 0.5 : 0.3),
                        blurRadius: _isPressed ? 12 : 8,
                        offset: Offset(0, _isPressed ? 2 : 4),
                        spreadRadius: _isPressed ? 0 : 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Enhanced abstract background circles
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 60,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
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

                // Popular badge if needed
                if (widget.isPopular)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- Popularity Badge ---
class PopularityBadge extends StatelessWidget {
  final Size size;

  const PopularityBadge({Key? key, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.trending_up,
            color: Color(0xFF6366F1),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Most Used',
            style: TextStyle(
              color: const Color(0xFF6366F1),
              fontSize: size.width * 0.03,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Shimmer Button ---
class ShimmerButton extends StatelessWidget {
  final AnimationController controller;
  final String label;
  final VoidCallback onTap;

  const ShimmerButton({
    Key? key,
    required this.controller,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final shimmerValue = sin(controller.value * 2 * pi);
          final color = Color.lerp(
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
            0.5 + 0.5 * shimmerValue,
          )!;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Enhanced Floating Action Button ---
class EnhancedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final AnimationController shimmerController;

  const EnhancedFAB({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.shimmerController,
  }) : super(key: key);

  @override
  _EnhancedFABState createState() => _EnhancedFABState();
}

class _EnhancedFABState extends State<EnhancedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation:
            Listenable.merge([_animationController, widget.shimmerController]),
        builder: (context, child) {
          final shimmerValue = sin(widget.shimmerController.value * 2 * pi);

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow layers
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.lerp(
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                          shimmerValue * 0.5 + 0.3,
                        )!
                            .withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Middle pulse
              Transform.scale(
                scale: 0.9 + 0.1 * sin(_animationController.value * pi),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                          shimmerValue * 0.5 + 0.3,
                        )!
                            .withOpacity(0.4),
                        Color.lerp(
                          const Color(0xFF8B5CF6),
                          const Color(0xFFA78BFA),
                          shimmerValue * 0.5 + 0.3,
                        )!
                            .withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),
              // Inner button
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                        shimmerValue * 0.5 + 0.3,
                      )!,
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1)
                          .withOpacity(_isHovered ? 0.6 : 0.4),
                      blurRadius: _isHovered ? 15 : 10,
                      spreadRadius: _isHovered ? 3 : 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: Transform.rotate(
                        angle: _rotateAnimation.value,
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Particle effects around button
              if (_isHovered) ..._buildParticles(shimmerValue),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildParticles(double shimmerValue) {
    final particles = <Widget>[];
    final random = Random();

    for (int i = 0; i < 5; i++) {
      final angle = 2 * pi * i / 5 + shimmerValue * pi / 10;
      final distance = 45.0 + 5 * sin(shimmerValue * pi + i);
      final x = distance * cos(angle);
      final y = distance * sin(angle);

      particles.add(
        Positioned(
          left: 30 + x,
          top: 30 + y,
          child: Opacity(
            opacity: 0.3 + 0.4 * random.nextDouble() * (1 - shimmerValue * 0.5),
            child: Container(
              width: 4 + 4 * random.nextDouble(),
              height: 4 + 4 * random.nextDouble(),
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF6366F1),
                  const Color(0xFFA78BFA),
                  random.nextDouble(),
                ),
                shape: random.nextBool() ? BoxShape.circle : BoxShape.rectangle,
                borderRadius:
                    random.nextBool() ? null : BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
    }

    return particles;
  }
}

// --- Enhanced Bottom Navigation Bar ---
class EnhancedBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const EnhancedBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final navItems = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.folder_rounded, 'label': 'Docs'},
      {'icon': Icons.history_rounded, 'label': 'History'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: size.height * 0.09,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              navItems.length,
              (index) => EnhancedNavBarItem(
                label: navItems[index]['label'] as String,
                icon: navItems[index]['icon'] as IconData,
                isActive: selectedIndex == index,
                onTap: () => onTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Enhanced Bottom NavBar Item ---
class EnhancedNavBarItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const EnhancedNavBarItem({
    Key? key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  _EnhancedNavBarItemState createState() => _EnhancedNavBarItemState();
}

class _EnhancedNavBarItemState extends State<EnhancedNavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(EnhancedNavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: widget.isActive
                      ? const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isActive ? Colors.white : Colors.grey,
                  size: widget.isActive ? 26 : 22,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color:
                      widget.isActive ? const Color(0xFF6366F1) : Colors.grey,
                  fontSize: widget.isActive ? 12 : 11,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(widget.label),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- Enhanced Animated Background ---
class EnhancedBackground extends StatelessWidget {
  final AnimationController controller;

  const EnhancedBackground({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Larger, more vibrant gradient blobs
            Positioned(
              top: -150 + 30 * controller.value,
              right: -200 + 40 * controller.value,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFA78BFA).withOpacity(0.6),
                      const Color(0xFFA78BFA).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80 - 50 * controller.value,
              left: -150 - 30 * controller.value,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF38BDF8).withOpacity(0.5),
                      const Color(0xFF38BDF8).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 300 + 40 * controller.value,
              left: 300 + 20 * controller.value,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6EE7B7).withOpacity(0.4),
                      const Color(0xFF6EE7B7).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),

            // Small accent blobs
            Positioned(
              top: 100 + 20 * sin(controller.value * pi),
              right: 80 + 10 * cos(controller.value * pi),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFBBF24).withOpacity(0.3),
                      const Color(0xFFFBBF24).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),

            // Overlay mesh gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF8FAFC).withOpacity(0.9),
                    const Color(0xFFF8FAFC).withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Add enhanced floating particles
            ...List.generate(
              15,
              (index) => Positioned(
                top: 50 + index * 50 + (15 * sin(index + controller.value * 2)),
                left: 20 +
                    index * 30 +
                    (25 * cos(index * 0.8 + controller.value)),
                child: Opacity(
                  opacity: 0.2 + 0.3 * sin(index * 0.5 + controller.value),
                  child: Container(
                    width: 6 + index % 5 * 2,
                    height: 6 + index % 5 * 2,
                    decoration: BoxDecoration(
                      shape:
                          index % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius:
                          index % 3 == 0 ? null : BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          [
                            const Color(0xFF6366F1),
                            const Color(0xFF8B5CF6),
                          ],
                          [
                            const Color(0xFF0EA5E9),
                            const Color(0xFF38BDF8),
                          ],
                          [
                            const Color(0xFF10B981),
                            const Color(0xFF34D399),
                          ],
                          [
                            const Color(0xFFF59E0B),
                            const Color(0xFFFBBF24),
                          ],
                        ][index % 4],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: [
                            const Color(0xFF6366F1),
                            const Color(0xFF38BDF8),
                            const Color(0xFF6EE7B7),
                            const Color(0xFFFBBF24),
                          ][index % 4]
                              .withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Light noise texture overlay
            Opacity(
              opacity: 0.03,
              child: Image.network(
                'https://cdn.jsdelivr.net/gh/tailwindlabs/tailwindcss/lib/public/img/placeholder.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- Gradient Text Widget ---
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign textAlign;

  const GradientText(
    this.text, {
    Key? key,
    required this.gradient,
    this.style,
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

// --- Glassmorphic Container Widget ---
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final BoxBorder? border;

  const GlassContainer({
    Key? key,
    required this.child,
    this.width = double.infinity,
    this.height = 0,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height == 0 ? null : height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.6)
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
