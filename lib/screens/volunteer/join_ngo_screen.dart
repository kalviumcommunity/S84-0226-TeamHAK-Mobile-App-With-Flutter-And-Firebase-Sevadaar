import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/ngo_service.dart';
import '../../services/user_service.dart';
import '../role_router.dart';

/// Screen where a volunteer without an NGO can enter an 8-digit code to join.
class JoinNgoScreen extends StatefulWidget {
  const JoinNgoScreen({super.key});

  @override
  State<JoinNgoScreen> createState() => _JoinNgoScreenState();
}

class _JoinNgoScreenState extends State<JoinNgoScreen> {
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _ngoService = NgoService();
  final _userService = UserService();
  final _authService = AuthService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinNgo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final code = _codeCtrl.text.trim();
      final ngo = await _ngoService.validateJoinCode(code);

      if (ngo == null) {
        setState(() {
          _error = 'No NGO found with this code.';
          _loading = false;
        });
        return;
      }

      final uid = _authService.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _error = 'You must be logged in.';
          _loading = false;
        });
        return;
      }

      // Update user's ngoId
      await _userService.assignNgo(uid, ngo.ngoId);

      if (!mounted) return;

      // Navigate to RoleRouter which will send them to Volunteer Dashboard
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Join an NGO',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Illustration ──
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6A74F8).withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.login_rounded,
                  size: 48,
                  color: Color(0xFF6A74F8),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Enter NGO Code',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Ask your NGO admin for the 8-digit joining code',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 32),

              // ── Error ──
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Code Input ──
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 8,
                  ),
                  maxLength: 8,
                  decoration: InputDecoration(
                    hintText: '00000000',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey.shade300,
                      letterSpacing: 8,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter the 8-digit code';
                    }
                    if (v.trim().length != 8) return 'Code must be 8 digits';
                    if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
                      return 'Only numbers allowed';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _joinNgo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A74F8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Join NGO',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
