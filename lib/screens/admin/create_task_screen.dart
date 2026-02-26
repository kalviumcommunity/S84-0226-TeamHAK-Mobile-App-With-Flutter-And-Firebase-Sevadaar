import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/task_service.dart';

// ─── Shared Design Tokens (mirroring admin_dashboard.dart) ────────────────────
class _C {
  static const bg = Color(0xFFEEF2F8);
  static const bgCard = Colors.white;
  static const heroCard = Color(0xFF0D1B3E);
  static const blue = Color(0xFF4A6CF7);
  static const blueLight = Color(0xFFEEF2FF);
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const textPri = Color(0xFF0D1B3E);
  static const textSec = Color(0xFF6B7280);
  static const textTer = Color(0xFFB0B7C3);
  static const border = Color(0xFFE5E9F0);
  static const divider = Color(0xFFF1F4F9);
}

class CreateTaskScreen extends StatefulWidget {
  final String adminId;
  final String ngoId;
  const CreateTaskScreen({
    super.key,
    required this.adminId,
    required this.ngoId,
  });
  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxVolCtrl = TextEditingController(text: '1');
  final _taskService = TaskService();

  DateTime? _deadline;
  bool _loading = false;

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _anims = List.generate(
      5,
      (i) => CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(i * 0.1, i * 0.1 + 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _maxVolCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4A6CF7),
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4A6CF7),
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      _snack('Please select a deadline.', _C.orange, Icons.schedule_rounded);
      return;
    }
    setState(() => _loading = true);
    try {
      await _taskService.createTask(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        adminId: widget.adminId,
        ngoId: widget.ngoId,
        maxVolunteers: int.parse(_maxVolCtrl.text.trim()),
        deadline: _deadline!,
      );
      if (!mounted) return;
      _snack(
        'Task created successfully!',
        _C.green,
        Icons.check_circle_rounded,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e', _C.red, Icons.error_rounded);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color bg, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: GoogleFonts.dmSans(fontSize: 13))),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── App Bar ────────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                child: Row(
                  children: [
                    _BackButton(onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Task',
                            style: GoogleFonts.dmSans(
                              color: _C.textPri,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Fill in the details below',
                            style: GoogleFonts.dmSans(
                              color: _C.textSec,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form ───────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task Title
                        _SlideIn(
                          anim: _anims[0],
                          child: _FormSection(
                            label: 'Task Title',
                            icon: Icons.title_rounded,
                            child: _LightField(
                              controller: _titleCtrl,
                              hint: 'e.g. Clean the beach',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Title is required'
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description
                        _SlideIn(
                          anim: _anims[1],
                          child: _FormSection(
                            label: 'Description',
                            icon: Icons.description_rounded,
                            child: _LightField(
                              controller: _descCtrl,
                              hint: 'Describe what needs to be done...',
                              maxLines: 4,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Description is required'
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Max Volunteers
                        _SlideIn(
                          anim: _anims[2],
                          child: _FormSection(
                            label: 'Max Volunteers',
                            icon: Icons.people_rounded,
                            child: Row(
                              children: [
                                _CounterBtn(
                                  icon: Icons.remove_rounded,
                                  onTap: () {
                                    final cur =
                                        int.tryParse(_maxVolCtrl.text) ?? 1;
                                    if (cur > 1)
                                      _maxVolCtrl.text = '${cur - 1}';
                                  },
                                ),
                                Expanded(
                                  child: _LightField(
                                    controller: _maxVolCtrl,
                                    hint: '1',
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Required';
                                      final n = int.tryParse(v.trim());
                                      if (n == null || n < 1)
                                        return 'Must be ≥ 1';
                                      return null;
                                    },
                                  ),
                                ),
                                _CounterBtn(
                                  icon: Icons.add_rounded,
                                  onTap: () {
                                    final cur =
                                        int.tryParse(_maxVolCtrl.text) ?? 1;
                                    _maxVolCtrl.text = '${cur + 1}';
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Deadline
                        _SlideIn(
                          anim: _anims[3],
                          child: _FormSection(
                            label: 'Deadline',
                            icon: Icons.event_rounded,
                            child: GestureDetector(
                              onTap: _pickDeadline,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _deadline != null
                                        ? _C.blue.withOpacity(0.5)
                                        : _C.border,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: _deadline != null
                                          ? _C.blue
                                          : _C.textTer,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _deadline == null
                                            ? 'Select date & time'
                                            : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}  ${_deadline!.hour.toString().padLeft(2, '0')}:${_deadline!.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.dmSans(
                                          color: _deadline == null
                                              ? _C.textTer
                                              : _C.textPri,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (_deadline != null)
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 14,
                                        color: _C.textTer,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Submit Button
                        _SlideIn(
                          anim: _anims[4],
                          child: _loading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: _C.blue,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: _submit,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 17,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4A6CF7),
                                          Color(0xFF1A2B5E),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _C.blue.withOpacity(0.35),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_task_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Create Task',
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Back Button ─────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _C.divider,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: Icon(Icons.arrow_back_rounded, color: _C.textPri, size: 18),
    ),
  );
}

// ─── Form Section Label ───────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  const _FormSection({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: _C.blue),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: _C.textSec,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

// ─── Light Field ─────────────────────────────────────────────────────────────
class _LightField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final TextAlign textAlign;
  final String? Function(String?)? validator;

  const _LightField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    textAlign: textAlign,
    validator: validator,
    style: GoogleFonts.dmSans(color: _C.textPri, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: _C.textTer, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _C.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _C.blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _C.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _C.red, width: 1.5),
      ),
      errorStyle: GoogleFonts.dmSans(color: _C.red, fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// ─── Counter Button ───────────────────────────────────────────────────────────
class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CounterBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 40,
      height: 48,
      decoration: BoxDecoration(
        color: _C.blueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.blue.withOpacity(0.2)),
      ),
      child: Icon(icon, color: _C.blue, size: 20),
    ),
  );
}

// ─── Slide-in animation wrapper ───────────────────────────────────────────────
class _SlideIn extends StatelessWidget {
  final Animation<double> anim;
  final Widget child;
  const _SlideIn({required this.anim, required this.child});
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: anim,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(anim),
      child: child,
    ),
  );
}
