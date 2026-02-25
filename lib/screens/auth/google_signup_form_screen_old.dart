import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/ngo_service.dart';
import '../role_router.dart';

/// ───────────────────────────────────────────────────────────────
/// POST-GOOGLE SIGNUP FORM — Sevadaar
/// Shown to first-time Google sign-in users.
/// Collects: Display name + 8-digit NGO code.
/// ───────────────────────────────────────────────────────────────
class GoogleSignupFormScreen extends StatefulWidget {
  final User firebaseUser;
  const GoogleSignupFormScreen({super.key, required this.firebaseUser});

  @override
  State<GoogleSignupFormScreen> createState() => _GoogleSignupFormScreenState();
}

class _GoogleSignupFormScreenState extends State<GoogleSignupFormScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _authService = AuthService();
  final _ngoService = NgoService();

  bool _loading = false;
  String? _error;

  // ── Animations ────────────────────────────────────────────────
  late final AnimationController _enterCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from Google profile
    _nameCtrl.text = widget.firebaseUser.displayName ?? '';

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    _slide = Tween(begin: 30.0, end: 0.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
    ));
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Validate code
      final ngo = await _ngoService.validateJoinCode(_codeCtrl.text.trim());
      if (ngo == null) {
        setState(() {
          _error = 'Invalid NGO code. Please check and try again.';
          _loading = false;
        });
        return;
      }

      await _authService.completeGoogleSignUp(
        uid: widget.firebaseUser.uid,
        name: _nameCtrl.text,
        email: widget.firebaseUser.email ?? '',
        ngoCode: _codeCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleRouter()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06110B),
      body: AnimatedBuilder(
        animation: _enterCtrl,
        builder: (context, _) {
          return Stack(
            children: [
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
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Opacity(
                    opacity: _fade.value,
                    child: Transform.translate(
                      offset: Offset(0, _slide.value),
                      child: Column(
                        children: [
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.08),

                          // ── Google avatar ──
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4CAF50),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: widget.firebaseUser.photoURL != null
                                  ? Image.network(
                                      widget.firebaseUser.photoURL!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _defaultAvatar(),
                                    )
                                  : _defaultAvatar(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Almost There!',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Complete your profile to get started',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: const Color(0xFF81C784),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color(0xFF0A1810),
                              border: Border.all(
                                  color: const Color(0xFF1E3A28)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.email_outlined,
                                    size: 14, color: Color(0xFF5A7A62)),
                                const SizedBox(width: 6),
                                Text(
                                  widget.firebaseUser.email ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF7A9A82),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Form ──
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1F15)
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF2E7D32)
                                    .withValues(alpha: 0.15),
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  if (_error != null) _errorBanner(),
                                  _field(
                                    controller: _nameCtrl,
                                    hint: 'Full name',
                                    icon: Icons.person_outline,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Enter your name'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _field(
                                    controller: _codeCtrl,
                                    hint: 'Organisation code (8 digits)',
                                    icon: Icons.tag_rounded,
                                    keyboardType: TextInputType.number,
                                    maxLength: 8,
                                    validator: (v) {
                                      if (v == null ||
                                          v.trim().length != 8) {
                                        return 'Enter exact 8-digit code';
                                      }
                                      if (int.tryParse(v.trim()) == null) {
                                        return 'Code must be numeric';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline,
                                          size: 14,
                                          color: Color(0xFF5A7A62)),
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
                                  const SizedBox(height: 22),
                                  _gradientButton(
                                    label: 'Continue',
                                    onTap: _complete,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

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

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFF1B5E20),
      child: const Icon(Icons.person, size: 40, color: Colors.white70),
    );
  }

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  fontSize: 12, color: const Color(0xFFEF9A9A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
      cursorColor: const Color(0xFF66BB6A),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            fontSize: 13, color: const Color(0xFF5A7A62)),
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
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
}
