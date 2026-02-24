import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ngo_service.dart';
import '../../widgets/auth_header.dart';

class NgoApplicationScreen extends StatefulWidget {
  const NgoApplicationScreen({super.key});

  @override
  State<NgoApplicationScreen> createState() => _NgoApplicationScreenState();
}

class _NgoApplicationScreenState extends State<NgoApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _applicantNameCtrl = TextEditingController();
  final _applicantEmailCtrl = TextEditingController();
  final _ngoNameCtrl = TextEditingController();
  final _ngoDescCtrl = TextEditingController();
  final _ngoAddrCtrl = TextEditingController();
  final _ngoPhoneCtrl = TextEditingController();

  final _ngoService = NgoService();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
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
            content: Text('Something went wrong. Please try again.', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red.shade400,
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
    if (_submitted) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9298F0).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 60, color: Color(0xFF9298F0)),
                ),
                const SizedBox(height: 30),
                Text(
                  'Application Submitted!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'We have received your request. Our team will review your details and contact you via email shortly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9298F0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Back to Login', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHeader(title: 'Partner with Us'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Register Your NGO',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join our network to manage volunteers effectively.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Form Card
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
                      child: Column(
                        children: [
                          _buildField(_applicantNameCtrl, 'Applicant Name', Icons.person_outline),
                          _buildDivider(),
                          _buildField(_applicantEmailCtrl, 'Applicant Email', Icons.email_outlined, isEmail: true),
                          _buildDivider(),
                          _buildField(_ngoNameCtrl, 'NGO Name', Icons.business_outlined),
                          _buildDivider(),
                          _buildField(_ngoPhoneCtrl, 'Phone Number', Icons.phone_outlined, isPhone: true),
                          _buildDivider(),
                          _buildField(_ngoAddrCtrl, 'Address', Icons.location_on_outlined),
                          _buildDivider(),
                          _buildField(_ngoDescCtrl, 'Mission / Description', Icons.info_outline, maxLines: 3),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9298F0),
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
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text('Submit Application', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {bool isEmail = false, bool isPhone = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF9298F0), size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey.shade100);
}
