import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import 'google_signup_form_screen.dart';
import 'ngo_application_screen.dart';
import '../role_router.dart';

/// ───────────────────────────────────────────────────────────────
/// LOGIN SCREEN — Sevadaar
/// Clean, professional login with:
///   • Floating particle field
///   • Staggered entrance animations
///   • Gradient accents & glassmorphic cards
///   • Email/password + Google sign-in
///   • "Have an NGO?" super-admin application link
/// ───────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  // ── Animations ────────────────────────────────────────────────
  late final AnimationController _enterCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _formFade;
  late final Animation<double> _formSlide;
  late final Animation<double> _bottomFade;

  final List<_Particle> _particles = [];
  final _rng = Random(77);

  @override
  void initState() {
    super.initState();
    _seedParticles();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _logoFade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    ));
    _logoScale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    ));
    _formFade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    ));
    _formSlide = Tween(begin: 40.0, end: 0.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
    ));
    _bottomFade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    ));

    _enterCtrl.forward();
  }

  void _seedParticles() {
    for (var i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 1.0 + _rng.nextDouble() * 2.0,
        speed: 0.03 + _rng.nextDouble() * 0.06,
        opacity: 0.1 + _rng.nextDouble() * 0.2,
      ));
    }
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Login ─────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.signIn(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleRouter()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.getFriendlyError(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────
  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _authService.signInWithGoogle();
      if (!mounted) return;

      if (result.isNewUser) {
        // New user — needs to fill name + NGO code
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GoogleSignupFormScreen(
              firebaseUser: result.firebaseUser,
            ),
          ),
        );
      } else {
        // Returning user — go straight to dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleRouter()),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF06110B),
      body: AnimatedBuilder(
        animation:
            Listenable.merge([_enterCtrl, _particleCtrl, _pulseCtrl]),
        builder: (context, _) {
          final p = _pulseCtrl.value;
          return Stack(
            children: [
              // ── Background gradient ──
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0E2419),
                      Color(0xFF091A10),
                      Color(0xFF06110B),
                    ],
                  ),
                ),
              ),

              // ── Floating particles ──
              RepaintBoundary(
                child: CustomPaint(
                  size: sz,
                  painter:
                      _ParticlePainter(_particles, _particleCtrl.value),
                ),
              ),

              // ── Subtle radial glow top ──
              Positioned(
                top: -sz.height * 0.1,
                left: sz.width * 0.2,
                child: Container(
                  width: sz.width * 0.6,
                  height: sz.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.fromRGBO(76, 175, 80, 0.06 + 0.02 * p),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ──
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      SizedBox(height: sz.height * 0.06),
                      _buildLogo(p),
                      const SizedBox(height: 40),
                      _buildForm(),
                      const SizedBox(height: 16),
                      _buildBottomLinks(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // ── Loading overlay ──
              if (_loading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Logo Section ──────────────────────────────────────────────
  Widget _buildLogo(double pulse) {
    return Opacity(
      opacity: _logoFade.value,
      child: Transform.scale(
        scale: _logoScale.value,
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF66BB6A),
                    Color(0xFF388E3C),
                    Color(0xFF1B5E20),
                  ],
                  stops: [0.1, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(76, 175, 80, 0.25 + 0.08 * pulse),
                    blurRadius: 22 + 8 * pulse,
                    spreadRadius: 4 + 3 * pulse,
                  ),
                ],
              ),
              child: const Icon(Icons.volunteer_activism,
                  size: 36, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              'Welcome Back',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to continue your mission',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF81C784),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form Card ─────────────────────────────────────────────────
  Widget _buildForm() {
    return Transform.translate(
      offset: Offset(0, _formSlide.value),
      child: Opacity(
        opacity: _formFade.value,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1F15).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Error banner ──
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D1212),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF5D1F1F),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFEF9A9A), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFFEF9A9A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Email ──
                _buildField(
                  controller: _emailCtrl,
                  hint: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),

                // ── Password ──
                _buildField(
                  controller: _passCtrl,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF81C784),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'At least 6 characters'
                      : null,
                ),
                const SizedBox(height: 8),

                // ── Forgot password ──
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF81C784),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // ── Sign In button ──
                _gradientButton(
                  label: 'Sign In',
                  onTap: _login,
                ),
                const SizedBox(height: 20),

                // ── Divider ──
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFF2A3F32),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OR',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5A7A62),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFF2A3F32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Google sign-in ──
                _googleButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Links ──────────────────────────────────────────────
  Widget _buildBottomLinks() {
    return Opacity(
      opacity: _bottomFade.value,
      child: Column(
        children: [
          // Sign up link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF7A9A82),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: Text(
                  'Sign Up',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF66BB6A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // NGO application link
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const NgoApplicationScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                ),
                color: const Color(0xFF0D1F15).withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.business_rounded,
                      color: Color(0xFFFFA726), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Have an NGO? Become a Super Admin',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFFFA726),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared text field ─────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white,
      ),
      cursorColor: const Color(0xFF66BB6A),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFF5A7A62),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF0A1810),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E3A28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 11),
      ),
    );
  }

  // ── Gradient button ───────────────────────────────────────────
  Widget _gradientButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ── Google button ─────────────────────────────────────────────
  Widget _googleButton() {
    return GestureDetector(
      onTap: _loading ? null : _googleSignIn,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF0A1810),
          border: Border.all(color: const Color(0xFF1E3A28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(3),
              child: const Text(
                'G',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4285F4),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Forgot Password ───────────────────────────────────────────
  void _forgotPassword() {
    final resetCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1F15),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reset Password',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email and we\'ll send a reset link.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF81C784),
                ),
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: resetCtrl,
                hint: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _gradientButton(
                label: 'Send Reset Link',
                onTap: () async {
                  try {
                    await _authService.resetPassword(resetCtrl.text);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Reset link sent!',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500)),
                          backgroundColor: const Color(0xFF2E7D32),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                  } catch (e) {
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(e.toString(),
                            style: GoogleFonts.poppins()),
                        backgroundColor: Colors.red.shade800,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Particle data & painter (reusable)
// ═══════════════════════════════════════════════════════════════════
class _Particle {
  final double x, y, size, speed, opacity;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double tick;
  _ParticlePainter(this.particles, this.tick);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final y = ((p.y - tick * p.speed) % 1.0 + 1.0) % 1.0;
      paint.color = Color.fromRGBO(129, 199, 132, p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.tick != tick;
}
