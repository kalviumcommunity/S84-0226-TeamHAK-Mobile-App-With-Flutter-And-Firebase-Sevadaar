import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ngo_building_painter.dart';
import '../landing_page.dart';
import '../role_router.dart';

/// Premium splash screen – NGO building construction animation
/// with realistic painted volunteer figures.
///
/// The controller runs for the full 6 s (animation + hold).
/// All visual content completes by ~71 %, leaving a live hold period
/// where the controller keeps ticking so AnimatedBuilder never stops
/// rebuilding and the CustomPaint layers stay on screen.
///
/// Timeline (of 6000 ms controller):
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
  static const Duration _totalDuration = Duration(milliseconds: 6000);

  late final AnimationController _controller;
  late final Animation<double> _buildingProgress;
  late final Animation<double> _volunteerProgress;
  late final Animation<double> _connectionProgress;
  late final Animation<double> _brandFade;
  late final Animation<double> _buildingScale;

  /// true when the current Firebase user is already signed in
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    // Check if user is already logged in
    try {
      _isLoggedIn = FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      _isLoggedIn = false;
    }

    // Always play the full splash animation regardless of auth state
    _controller = AnimationController(vsync: this, duration: _totalDuration);

    // Building painter progress (0.0 – 0.46)
    _buildingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.46, curve: Curves.easeInOut),
      ),
    );

    // Volunteer walk-in (0.46 – 0.60)
    _volunteerProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.46, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // Connection lines (0.58 – 0.64)
    _connectionProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.64, curve: Curves.easeOut),
      ),
    );

    // Scale-up (0.62 – 0.71)
    _buildingScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 0.71, curve: Curves.easeOutBack),
      ),
    );

    // Brand text (0.60 – 0.69)
    _brandFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.69, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // After the 6 s animation completes, route based on auth state:
    //  • Logged in  → RoleRouter (dashboard) — skips the landing/onboarding page
    //  • Logged out → LandingPage (onboarding)
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isLoggedIn) {
          _navigateToAuthCheck();
        } else {
          _navigateToLanding();
        }
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
