import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/ngo_request_service.dart';

/// Screen where a volunteer can submit a request to register a new NGO,
/// which will be reviewed by a Developer Admin.
class RegisterNgoScreen extends StatefulWidget {
  const RegisterNgoScreen({super.key});

  @override
  State<RegisterNgoScreen> createState() => _RegisterNgoScreenState();
}

class _RegisterNgoScreenState extends State<RegisterNgoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _regNumCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _ngoRequestService = NgoRequestService();
  final _authService = AuthService();

  bool _loading = false;
  String? _error;
  XFile? _certificate;
  String? _certificateFileName;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regNumCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 80,
      );
      if (file != null) {
        setState(() {
          _certificate = file;
          _certificateFileName = file.name;
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not pick file: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'You must be logged in.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Certificate file name stored as reference (upload skipped — needs Blaze plan)
      final String certificateUrl =
          _certificate != null ? 'local:${_certificate!.name}' : '';

      // Submit request
      await _ngoRequestService.submitRequest(
        ngoName: _nameCtrl.text,
        registrationNumber: _regNumCtrl.text,
        certificateUrl: certificateUrl,
        contactEmail: _emailCtrl.text,
        address: _addressCtrl.text,
        description: _descCtrl.text,
        requestedBy: uid,
      );

      if (!mounted) return;

      // Show success & pop back
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 64, color: Color(0xFF43A047)),
              const SizedBox(height: 16),
              Text(
                'Request Submitted!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your NGO registration request has been submitted for review. '
                'You\'ll be notified once it\'s approved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A74F8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
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
          'Register New NGO',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit your NGO details for approval.\n'
                'Once approved, you\'ll become the Super Admin.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // ── Error ──
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.poppins(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),

              // ── Fields ──
              _buildField(
                controller: _nameCtrl,
                label: 'NGO Name',
                hint: 'e.g. Helping Hands Foundation',
                icon: Icons.business_rounded,
                validator: (v) =>
                    v!.trim().isEmpty ? 'NGO name is required' : null,
              ),

              _buildField(
                controller: _regNumCtrl,
                label: 'Registration Number',
                hint: 'e.g. NGO/2024/12345',
                icon: Icons.numbers_rounded,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Registration number required' : null,
              ),

              _buildField(
                controller: _emailCtrl,
                label: 'Contact Email',
                hint: 'contact@ngo.org',
                icon: Icons.email_rounded,
                keyboard: TextInputType.emailAddress,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Email is required' : null,
              ),

              _buildField(
                controller: _addressCtrl,
                label: 'Address',
                hint: 'Office address',
                icon: Icons.location_on_rounded,
                maxLines: 2,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Address is required' : null,
              ),

              _buildField(
                controller: _descCtrl,
                label: 'Description',
                hint: 'Brief description of your NGO',
                icon: Icons.description_rounded,
                maxLines: 3,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Description is required' : null,
              ),

              // ── Certificate Upload ──
              const SizedBox(height: 8),
              Text(
                'Registration Certificate',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickCertificate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _certificate != null
                            ? Icons.check_circle_rounded
                            : Icons.upload_file_rounded,
                        color: _certificate != null
                            ? const Color(0xFF43A047)
                            : Colors.grey.shade500,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _certificateFileName ??
                              'Tap to upload certificate image',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _certificate != null
                                ? Colors.black87
                                : Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
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
                          'Submit Request',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade500),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6A74F8)),
          ),
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
        validator: validator,
      ),
    );
  }
}
