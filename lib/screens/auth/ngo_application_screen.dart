import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ngo_service.dart';

/// ───────────────────────────────────────────────────────────────
/// NGO APPLICATION SCREEN — Sevadaar
/// "Have an NGO? Become a Super Admin"
/// Form: NGO name, description, address, phone, applicant
///       name & email → saved to Firestore + auto-email sent.
/// On success → confirmation screen, applicant returns to login.
/// ───────────────────────────────────────────────────────────────
class NgoApplicationScreen extends StatefulWidget {
  const NgoApplicationScreen({super.key});

  @override
  State<NgoApplicationScreen> createState() => _NgoApplicationScreenState();
}

class _NgoApplicationScreenState extends State<NgoApplicationScreen>
    with SingleTickerProviderStateMixin {
  // ── Form controllers ──────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _applicantNameCtrl = TextEditingController();
  final _applicantEmailCtrl = TextEditingController();
  final _ngoNameCtrl = TextEditingController();
  final _ngoDescCtrl = TextEditingController();
  final _ngoAddrCtrl = TextEditingController();
  final _ngoPhoneCtrl = TextEditingController();

  final _ngoService = NgoService();

  bool _loading = false;
  bool _submitted = false;

  // ── Animation ─────────────────────────────────────────────────
  late final AnimationController _enterCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    _slide = Tween(begin: 30.0, end: 0.0).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
    ));
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _applicantNameCtrl.dispose();
    _applicantEmailCtrl.dispose();
    _ngoNameCtrl.dispose();
    _ngoDescCtrl.dispose();
    _ngoAddrCtrl.dispose();
    _ngoPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _ngoService.submitApplication(
        applicantName: _applicantNameCtrl.text,
        applicantEmail: _applicantEmailCtrl.text,
        ngoName: _ngoNameCtrl.text,
        ngoDescription: _ngoDescCtrl.text,
        ngoAddress: _ngoAddrCtrl.text,
        ngoPhone: _ngoPhoneCtrl.text,
      );
      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Please try again.',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
              // ── Background ──
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A1008),
                      Color(0xFF0F0D06),
                      Color(0xFF06110B),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: _submitted ? _buildSuccess() : _buildForm(),
              ),

              // ── Back button ──
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: Opacity(
                  opacity: _fade.value,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Color(0xFFFFA726), size: 20),
                  ),
                ),
              ),

              if (_loading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFA726),
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

  // ── Success View ──────────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(
                scale: v,
                child: child,
              ),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFFFD54F),
                      Color(0xFFF57F17),
                      Color(0xFFE65100),
                    ],
                    stops: [0.1, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA726).withValues(alpha: 0.3),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    size: 44, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Application Submitted!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Our team will verify your NGO details and get back to you via email with your Super Admin credentials.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: const Color(0xFFFFCC80),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFFFFA726).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Back to Login',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3E2723),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form View ─────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.06),

              // ── Header ──
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFFFFD54F),
                            Color(0xFFF57F17),
                            Color(0xFFE65100),
                          ],
                          stops: [0.1, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA726)
                                .withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.business_rounded,
                          size: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Register Your NGO',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Apply for Super Admin access',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFFFFCC80),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Form card ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1008).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF57F17).withValues(alpha: 0.12),
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
                      // Section: Your details
                      _sectionLabel('YOUR DETAILS'),
                      const SizedBox(height: 12),
                      _field(
                        controller: _applicantNameCtrl,
                        hint: 'Your full name',
                        icon: Icons.person_outline,
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _applicantEmailCtrl,
                        hint: 'Your email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 22),

                      // Section: NGO details
                      _sectionLabel('NGO DETAILS'),
                      const SizedBox(height: 12),
                      _field(
                        controller: _ngoNameCtrl,
                        hint: 'NGO / Organisation name',
                        icon: Icons.business_outlined,
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _ngoDescCtrl,
                        hint: 'Brief description of your NGO',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _ngoAddrCtrl,
                        hint: 'Registered address',
                        icon: Icons.location_on_outlined,
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _ngoPhoneCtrl,
                        hint: 'Contact phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: _required,
                      ),
                      const SizedBox(height: 22),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF0F0D06),
                          border: Border.all(
                            color: const Color(0xFFF57F17)
                                .withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: Color(0xFFFFCC80)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Our team will review your application and send Super Admin credentials to your email within 24-48 hours.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFFFFCC80),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Submit button
                      GestureDetector(
                        onTap: _loading ? null : _submit,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFD54F),
                                Color(0xFFF57F17),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFA726)
                                    .withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Submit Application',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3E2723),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
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
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFA726),
        letterSpacing: 2,
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
      cursorColor: const Color(0xFFFFA726),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFF7A6A52),
        ),
        prefixIcon: maxLines > 1
            ? null
            : Icon(icon, color: const Color(0xFFFFA726), size: 20),
        filled: true,
        fillColor: const Color(0xFF0F0D06),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 14 : 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2214)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFFA726), width: 1.5),
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
}
