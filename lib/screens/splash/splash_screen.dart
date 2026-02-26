import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ngo_building_painter.dart';
import '../landing_page.dart';
import '../role_router.dart';

/// Premium splash screen – NGO building construction animation
/// with realistic painted volunteer figures.
///
/// The controller runs for the full 8.5 s (animation + hold).
/// All visual content completes by ~71 %, leaving a live hold period
/// where the controller keeps ticking so AnimatedBuilder never stops
/// rebuilding and the CustomPaint layers stay on screen.
///
/// Timeline (of 8500 ms controller):
///   0.00 – 0.46  Building (foundation → details)
///   0.46 – 0.60  Volunteer figures walk in
///   0.58 – 0.64  Connection lines
///   0.60 – 0.69  Brand text (letter-by-letter)
///   0.62 – 0.71  Building scale-up
///   0.71 – 1.00  Hold (everything stays visible)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgColor = Color(0xFFF5F5F5);
  static const Color _accent = Color(0xFF2196F3);

  // Controller covers the ENTIRE splash duration (animation + hold).
  static const Duration _totalDuration = Duration(milliseconds: 4000);

  late final AnimationController _controller;
  late final Animation<double> _buildingProgress;
  late final Animation<double> _volunteerProgress;
  late final Animation<double> _connectionProgress;
  late final Animation<double> _brandFade;
  late final Animation<double> _buildingScale;
  
  bool _shouldShowAnimation = true;

  @override
  void initState() {
    super.initState();

    // Check if user is already logged in
    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (e) {
      // Firebase not available (e.g., on Linux/Windows dev mode)
      currentUser = null;
    }

    // If user is already logged in (existing user), skip animation and go to auth check
    if (currentUser != null) {
      _shouldShowAnimation = false;
      // Navigate immediately to RoleRouter without animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToAuthCheck();
      });
      return;
    }

    // For new/unauthenticated users, proceed with splash animation
    _controller = AnimationController(vsync: this, duration: _totalDuration);

    // Building painter progress (0.0 – 0.46 ≈ 3900 ms)
    _buildingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.46, curve: Curves.easeInOut),
      ),
    );

    // Volunteer walk-in (0.46 – 0.60 ≈ 1190 ms)
    _volunteerProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.46, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // Connection lines (0.58 – 0.64 ≈ 510 ms)
    _connectionProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.64, curve: Curves.easeOut),
      ),
    );

    // Scale-up (0.62 – 0.71 ≈ 765 ms)
    _buildingScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 0.71, curve: Curves.easeOutBack),
      ),
    );

    // Brand text (0.60 – 0.69 ≈ 765 ms)
    _brandFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.69, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Navigate when the controller completes (at 4000 ms).
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToLanding();
      }
    });
  }

  /// Navigate to auth check screen for existing logged-in users
  /// Shows RoleRouter loading screen while checking auth
  void _navigateToAuthCheck() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation1, animation2) => const RoleRouter(),
        transitionsBuilder: (context2, animation, animation3, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// Navigate after splash animation for new/unauthenticated users
  void _navigateToLanding() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation1, animation2) => const LandingPage(),
        transitionsBuilder: (context2, animation, animation3, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    if (_shouldShowAnimation) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If user is already logged in (returning user), show loading screen
    if (!_shouldShowAnimation) {
      return Scaffold(
        backgroundColor: const Color(0xFF06110B),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF4CAF50),
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your dashboard...',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF81C784),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // For new users, show splash animation
    final size = MediaQuery.of(context).size;

    // Painter canvas – make it big (90 % width, 55 % height)
    final double painterW = size.width * 0.92;
    final double painterH = size.height * 0.58;

    return Scaffold(
      backgroundColor: _bgColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              // ── Single CustomPaint for building + volunteers ──
              Center(
                child: Transform.scale(
                  scale: _buildingScale.value,
                  child: SizedBox(
                    width: painterW,
                    height: painterH,
                    child: CustomPaint(
                      painter: NgoBuildingPainter(
                        progress: _buildingProgress.value,
                        strokeColor: _accent,
                        walkProgress: _volunteerProgress.value,
                        connectionProgress: _connectionProgress.value,
                      ),
                      foregroundPainter: VolunteerPainter(
                        walkProgress: _volunteerProgress.value,
                        connectionProgress: _connectionProgress.value,
                        controllerValue: _controller.value,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Brand text (letter-by-letter reveal) ──────
              Positioned(
                bottom: size.height * 0.08,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLetterReveal(
                      'Sevadaar',
                      _brandFade.value,
                      GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF333333),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildLetterReveal(
                      'Structuring Impact',
                      ((_brandFade.value - 0.3) / 0.7).clamp(0.0, 1.0),
                      GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF757575),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Cascading letter-by-letter fade + slide-up reveal.
  Widget _buildLetterReveal(String text, double progress, TextStyle style) {
    if (progress <= 0) return const SizedBox.shrink();
    final int len = text.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(len, (i) {
        const double staggerSpan = 0.65;
        const double charDuration = 0.35;
        final double charStart = (i / len) * staggerSpan;
        final double charEnd = charStart + charDuration;
        final double charT =
            ((progress - charStart) / (charEnd - charStart)).clamp(0.0, 1.0);
        final double eased = Curves.easeOutCubic.transform(charT);
        return Transform.translate(
          offset: Offset(0, 10 * (1 - eased)),
          child: Opacity(
            opacity: eased,
            child: Text(text[i], style: style),
          ),
        );
      }),
    );
  }
}
