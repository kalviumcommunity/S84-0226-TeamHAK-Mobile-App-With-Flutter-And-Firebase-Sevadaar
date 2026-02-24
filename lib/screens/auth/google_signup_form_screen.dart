import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/ngo_service.dart';
import '../role_router.dart';

/// Clean post-Google signup form
class GoogleSignupFormScreen extends StatefulWidget {
  final User firebaseUser;
  const GoogleSignupFormScreen({super.key, required this.firebaseUser});

  @override
  State<GoogleSignupFormScreen> createState() => _GoogleSignupFormScreenState();
}

class _GoogleSignupFormScreenState extends State<GoogleSignupFormScreen> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _authService = AuthService();
  final _ngoService = NgoService();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.firebaseUser.displayName ?? '';
  }

  @override
  void dispose() {
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
        orgId: ngo.ngoId,
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
      backgroundColor: const Color(0xFF6C63FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
              ),
            ),
            child: Column(
              children: [
                // ── Header with avatar ──
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Column(
                    children: [
                      // Google avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: widget.firebaseUser.photoURL != null
                              ? Image.network(
                                  widget.firebaseUser.photoURL!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(),
                                )
                              : _buildDefaultAvatar(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Complete Your Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.firebaseUser.email ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Form Container ──
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error message
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                _error!,
                                style: GoogleFonts.poppins(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          // Name field
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                            ),
                            style: GoogleFonts.poppins(fontSize: 15),
                            validator: (v) => (v?.trim().isEmpty ?? true)
                                ? 'Enter your name'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // NGO Code field
                          TextFormField(
                            controller: _codeCtrl,
                            decoration: InputDecoration(
                              labelText: 'NGO Code (8 digits)',
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                              helperText: 'Ask your NGO admin for the code',
                              helperStyle: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(fontSize: 15),
                            maxLength: 8,
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Enter NGO code';
                              if (v!.length != 8) return 'Code must be 8 digits';
                              if (!RegExp(r'^\d+$').hasMatch(v)) {
                                return 'Only numbers allowed';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Complete button
                          ElevatedButton(
                            onPressed: _loading ? null : _complete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Complete Sign Up',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
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

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF6C63FF),
      child: Icon(
        Icons.person,
        size: 50,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }
}
