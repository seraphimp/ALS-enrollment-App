import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to ALS',
      subtitle: 'Alternative Learning System',
      description:
          'Start your educational journey with our streamlined enrollment process designed for accessibility and convenience.',
      icon: Icons.school_rounded,
      iconGradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      illustration: _buildEducationIllustration,
    ),
    OnboardingPage(
      title: 'Easy Enrollment',
      subtitle: 'Just a few steps away',
      description:
          'Complete your enrollment in minutes with our intuitive step-by-step process. No complicated forms or confusing procedures.',
      icon: Icons.assignment_turned_in_rounded,
      iconGradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      illustration: _buildEnrollmentIllustration,
    ),
    OnboardingPage(
      title: 'Track Your Progress',
      subtitle: 'Stay updated',
      description:
          'Monitor your application status in real-time and receive instant notifications about your enrollment journey.',
      icon: Icons.timeline_rounded,
      iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
      illustration: _buildProgressIllustration,
    ),
    OnboardingPage(
      title: 'Secure & Verified',
      subtitle: 'Your data is safe',
      description:
          'We prioritize your privacy and security with encrypted data storage and verified authentication processes.',
      icon: Icons.verified_user_rounded,
      iconGradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
      illustration: _buildSecurityIllustration,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    // Save that user has seen onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    // Navigate to login
    _goToLogin();
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipToLogin() {
    _completeOnboarding();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var offsetAnimation = animation.drive(tween);
          var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeIn),
          );

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F2FE),
              Color(0xFFBAE6FD),
              Color(0xFF7DD3FC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPageContent(_pages[index], index);
                  },
                ),
              ),

              // Bottom section with indicators and buttons
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          // Skip button
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _skipToLogin,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0C4A6E),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Animated illustration
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatValue = Tween<double>(begin: -8.0, end: 8.0).animate(
                CurvedAnimation(
                  parent: _floatController,
                  curve: Curves.easeInOut,
                ),
              );

              return Transform.translate(
                offset: Offset(0, floatValue.value),
                child: SizedBox(
                  height: 280,
                  child: page.illustration(),
                ),
              );
            },
          ),

          const SizedBox(height: 48),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: page.iconGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.iconGradient[0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              color: Colors.white,
              size: 40,
            ),
          ),

          const SizedBox(height: 24),

          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0369A1),
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0C4A6E),
              height: 1.2,
            ),
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0C4A6E).withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildIndicator(index),
            ),
          ),

          const SizedBox(height: 32),

          // Action button
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive
            ? const Color(0xFF0284C7)
            : const Color(0xFF0284C7).withOpacity(0.3),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF0284C7).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildActionButton() {
    final isLastPage = _currentPage == _pages.length - 1;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = Tween<double>(begin: 1.0, end: 1.05).animate(
          CurvedAnimation(
            parent: _pulseController,
            curve: Curves.easeInOut,
          ),
        );

        return Transform.scale(
          scale: isLastPage ? pulseValue.value : 1.0,
          child: GestureDetector(
            onTap: _goToNextPage,
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: isLastPage
                      ? const [Color(0xFF10B981), Color(0xFF059669)]
                      : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isLastPage
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0284C7))
                        .withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLastPage ? 'GET STARTED' : 'NEXT',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLastPage
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Illustration builders
  static Widget _buildEducationIllustration() {
    return CustomPaint(
      painter: _EducationIllustrationPainter(),
      size: const Size(280, 280),
    );
  }

  static Widget _buildEnrollmentIllustration() {
    return CustomPaint(
      painter: _EnrollmentIllustrationPainter(),
      size: const Size(280, 280),
    );
  }

  static Widget _buildProgressIllustration() {
    return CustomPaint(
      painter: _ProgressIllustrationPainter(),
      size: const Size(280, 280),
    );
  }

  static Widget _buildSecurityIllustration() {
    return CustomPaint(
      painter: _SecurityIllustrationPainter(),
      size: const Size(280, 280),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> iconGradient;
  final Widget Function() illustration;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.iconGradient,
    required this.illustration,
  });
}

// Illustration Painters (keep all your existing painters here)
class _EducationIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background circle
    paint.color = const Color(0xFF6366F1).withOpacity(0.1);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.4,
      paint,
    );

    // Book shape
    paint.color = const Color(0xFF6366F1);
    final bookRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.4,
        height: size.height * 0.5,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(bookRect, paint);

    // Book pages
    paint.color = Colors.white.withOpacity(0.3);
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width / 2 - size.width * 0.15,
            size.height / 2 - size.height * 0.2 + i * 30),
        Offset(size.width / 2 + size.width * 0.15,
            size.height / 2 - size.height * 0.2 + i * 30),
        paint..strokeWidth = 2,
      );
    }

    // Graduation cap
    final capPath = Path();
    capPath.moveTo(size.width / 2, size.height * 0.25);
    capPath.lineTo(size.width * 0.3, size.height * 0.35);
    capPath.lineTo(size.width / 2, size.height * 0.4);
    capPath.lineTo(size.width * 0.7, size.height * 0.35);
    capPath.close();

    paint.color = const Color(0xFF8B5CF6);
    canvas.drawPath(capPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EnrollmentIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background
    paint.color = const Color(0xFF0EA5E9).withOpacity(0.1);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.4,
      paint,
    );

    // Document
    paint.color = const Color(0xFF0EA5E9);
    final docRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.5,
        height: size.height * 0.6,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(docRect, paint);

    // Lines on document
    paint.color = Colors.white.withOpacity(0.4);
    paint.strokeWidth = 3;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(size.width * 0.3, size.height * 0.3 + i * 25),
        Offset(size.width * 0.7, size.height * 0.3 + i * 25),
        paint,
      );
    }

    // Checkmark
    paint.color = const Color(0xFF10B981);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 8;
    paint.strokeCap = StrokeCap.round;

    final checkPath = Path();
    checkPath.moveTo(size.width * 0.35, size.height * 0.65);
    checkPath.lineTo(size.width * 0.45, size.height * 0.7);
    checkPath.lineTo(size.width * 0.65, size.height * 0.55);

    canvas.drawPath(checkPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background
    paint.color = const Color(0xFF10B981).withOpacity(0.1);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.4,
      paint,
    );

    // Progress bars
    final barColors = [
      const Color(0xFF10B981),
      const Color(0xFF059669),
      const Color(0xFF047857),
    ];

    for (int i = 0; i < 3; i++) {
      // Background bar
      paint.color = Colors.white.withOpacity(0.3);
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.35 + i * 45,
          size.width * 0.5,
          20,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(bgRect, paint);

      // Progress bar
      paint.color = barColors[i];
      final progressWidth = [0.8, 0.6, 0.4][i];
      final progressRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.35 + i * 45,
          size.width * 0.5 * progressWidth,
          20,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(progressRect, paint);
    }

    // Chart line
    paint.color = const Color(0xFF10B981);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;

    final chartPath = Path();
    chartPath.moveTo(size.width * 0.2, size.height * 0.7);
    chartPath.lineTo(size.width * 0.4, size.height * 0.65);
    chartPath.lineTo(size.width * 0.6, size.height * 0.6);
    chartPath.lineTo(size.width * 0.8, size.height * 0.5);

    canvas.drawPath(chartPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SecurityIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background
    paint.color = const Color(0xFFEC4899).withOpacity(0.1);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.4,
      paint,
    );

    // Shield
    final shieldPath = Path();
    shieldPath.moveTo(size.width / 2, size.height * 0.25);
    shieldPath.lineTo(size.width * 0.7, size.height * 0.35);
    shieldPath.lineTo(size.width * 0.7, size.height * 0.6);
    shieldPath.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.75,
      size.width / 2,
      size.height * 0.8,
    );
    shieldPath.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.75,
      size.width * 0.3,
      size.height * 0.6,
    );
    shieldPath.lineTo(size.width * 0.3, size.height * 0.35);
    shieldPath.close();

    paint.color = const Color(0xFFEC4899);
    canvas.drawPath(shieldPath, paint);

    // Checkmark on shield
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 6;
    paint.strokeCap = StrokeCap.round;

    final checkPath = Path();
    checkPath.moveTo(size.width * 0.4, size.height * 0.52);
    checkPath.lineTo(size.width * 0.47, size.height * 0.58);
    checkPath.lineTo(size.width * 0.6, size.height * 0.45);

    canvas.drawPath(checkPath, paint);

    // Lock detail
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white.withOpacity(0.3);
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.65),
      8,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
