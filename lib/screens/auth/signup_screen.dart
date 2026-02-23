import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/ngo_service.dart';
import 'ngo_application_screen.dart';
import 'google_signup_form_screen.dart';
import '../role_router.dart';

/// ───────────────────────────────────────────────────────────────
/// SIGNUP SCREEN — Sevadaar
/// Clean signup with: Name, Email, Password, 8-digit NGO Code
/// + "Continue with Google" + "Have an NGO?" link
/// Same dark-green premium theme with entrance animations.
/// ───────────────────────────────────────────────────────────────
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _authService = AuthService();
  final _ngoService = NgoService();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  // ── Animations ────────────────────────────────────────────────
  late final AnimationController _enterCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _headerFade;
  late final Animation<double> _headerScale;
  late final Animation<double> _formFade;
  late final Animation<double> _formSlide;
  late final Animation<double> _bottomFade;

  final List<_Particle> _particles = [];
  final _rng = Random(42);

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

    _headerFade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    ));
    _headerScale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    ));
    _formFade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
    ));
    _formSlide = Tween(begin: 40.0, end: 0.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));
    _bottomFade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
    ));

    _enterCtrl.forward();
  }

  void _seedParticles() {
    for (var i = 0; i < 25; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 1.0 + _rng.nextDouble() * 2.0,
        speed: 0.03 + _rng.nextDouble() * 0.06,
        opacity: 0.1 + _rng.nextDouble() * 0.18,
      ));
    }
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── Sign Up ───────────────────────────────────────────────────
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Validate NGO code
      final ngo = await _ngoService.validateJoinCode(_codeCtrl.text.trim());
      if (ngo == null) {
        setState(() {
          _error = 'Invalid NGO code. Please check and try again.';
          _loading = false;
        });
        return;
      }

      // 2. Create account + Firestore profile
      await _authService.signUp(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        orgId: ngo.ngoId,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleRouter()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.getFriendlyError(e));
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Google Sign Up ────────────────────────────────────────────
  Future<void> _googleSignUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _authService.signInWithGoogle();

      if (!mounted) return;

      // If the user is new, redirect to post-Google form
      if (result.isNewUser) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GoogleSignupFormScreen(
              firebaseUser: result.firebaseUser,
            ),
          ),
        );
      } else {
        // Existing user with profile — go to dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleRouter()),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() => _error = 'Google sign-up failed: ${e.toString().replaceAll('Exception: ', '')}');
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
              // Background
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

              // Particles
              RepaintBoundary(
                child: CustomPaint(
                  size: sz,
                  painter:
                      _ParticlePainter(_particles, _particleCtrl.value),
                ),
              ),

              // Radial glow
              Positioned(
                top: -sz.height * 0.08,
                right: -sz.width * 0.1,
                child: Container(
                  width: sz.width * 0.5,
                  height: sz.width * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.fromRGBO(38, 166, 154, 0.05 + 0.02 * p),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      SizedBox(height: sz.height * 0.03),
                      _buildHeader(p),
                      const SizedBox(height: 30),
                      _buildForm(),
                      const SizedBox(height: 16),
                      _buildBottomLinks(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: Opacity(
                  opacity: _headerFade.value,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Color(0xFF81C784), size: 20),
                  ),
                ),
              ),

              // Loading
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

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(double pulse) {
    return Opacity(
      opacity: _headerFade.value,
      child: Transform.scale(
        scale: _headerScale.value,
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF4DB6AC),
                    Color(0xFF00897B),
                    Color(0xFF004D40),
                  ],
                  stops: [0.1, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Color.fromRGBO(38, 166, 154, 0.25 + 0.08 * pulse),
                    blurRadius: 20 + 6 * pulse,
                    spreadRadius: 3 + 2 * pulse,
                  ),
                ],
              ),
              child: const Icon(Icons.person_add_alt_1_rounded,
                  size: 30, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Join the Mission',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your volunteer account',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF80CBC4),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────
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
              color: const Color(0xFF00897B).withValues(alpha: 0.15),
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
                // Error
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D1212),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF5D1F1F)),
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

                // Name
                _buildField(
                  controller: _nameCtrl,
                  hint: 'Full name',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 14),

                // Email
                _buildField(
                  controller: _emailCtrl,
                  hint: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 14),

                // Password
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
                      color: const Color(0xFF80CBC4),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'At least 6 characters'
                      : null,
                ),
                const SizedBox(height: 14),

                // NGO code
                _buildField(
                  controller: _codeCtrl,
                  hint: 'Organisation code (8 digits)',
                  icon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  validator: (v) {
                    if (v == null || v.trim().length != 8) {
                      return 'Enter exact 8-digit code';
                    }
                    if (int.tryParse(v.trim()) == null) {
                      return 'Code must be numeric';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),

                // Helper text
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Color(0xFF5A7A62)),
                    const SizedBox(width: 6),
                    Text(
                      'Get this code from your NGO admin',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF5A7A62),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sign Up button
                _gradientButton(
                  label: 'Create Account',
                  onTap: _signUp,
                  colors: const [Color(0xFF4DB6AC), Color(0xFF00897B)],
                  shadowColor: const Color(0xFF26A69A),
                ),
                const SizedBox(height: 12),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFF1E3A28).withValues(alpha: 0.6),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF5A7A62),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFF1E3A28).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Google Sign Up button
                GestureDetector(
                  onTap: _loading ? null : _googleSignUp,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFF0A1810).withValues(alpha: 0.7),
                      border: Border.all(
                        color: const Color(0xFF1E3A28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/google_logo.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.g_mobiledata_rounded,
                            color: Color(0xFF80CBC4),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF80CBC4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
          // Already have account
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF7A9A82),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF80CBC4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // NGO application
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
                  color: const Color(0xFF00897B).withValues(alpha: 0.3),
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

  // ── Field builder ─────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      maxLength: maxLength,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
      cursorColor: const Color(0xFF4DB6AC),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFF5A7A62),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF26A69A), size: 20),
        suffixIcon: suffix,
        counterText: '',
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
              const BorderSide(color: Color(0xFF26A69A), width: 1.5),
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
    List<Color> colors = const [Color(0xFF66BB6A), Color(0xFF2E7D32)],
    Color shadowColor = const Color(0xFF4CAF50),
  }) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.3),
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
}

// ═══════════════════════════════════════════════════════════════════
// Particle (shared style)
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
