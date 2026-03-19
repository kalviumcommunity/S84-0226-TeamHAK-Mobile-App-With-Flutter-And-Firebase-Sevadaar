import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../screens/auth/login_screen.dart';

class ProfileButton extends StatelessWidget {
  final UserModel currentUser;
  const ProfileButton({super.key, required this.currentUser});

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileModal(currentUser: currentUser),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = currentUser.name.isNotEmpty
        ? currentUser.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () => _showProfileModal(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF4A6CF7).withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4A6CF7).withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4A6CF7),
          ),
        ),
      ),
    );
  }
}

class _ProfileModal extends StatefulWidget {
  final UserModel currentUser;
  const _ProfileModal({required this.currentUser});

  @override
  State<_ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<_ProfileModal> {
  final _authService = AuthService();
  final _userService = UserService();
  
  late TextEditingController _nameCtrl;
  bool _isEditingName = false;
  bool _isLoading = false;
  String _currentName = '';

  @override
  void initState() {
    super.initState();
    _currentName = widget.currentUser.name;
    _nameCtrl = TextEditingController(text: _currentName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty || newName == _currentName) {
      setState(() => _isEditingName = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _userService.updateUser(widget.currentUser.uid, {'name': newName});
      setState(() {
        _currentName = newName;
        _isEditingName = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Name updated successfully!', style: GoogleFonts.dmSans()),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update name: $e', style: GoogleFonts.dmSans()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final nav = Navigator.of(context, rootNavigator: true);
    await _authService.signOut();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'super_admin': return 'Super Admin';
      case 'admin': return 'NGO Admin';
      case 'volunteer': return 'Volunteer';
      default: return role.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final initials = _currentName.isNotEmpty
        ? _currentName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset > 0 ? bottomInset + 24 : 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CF7).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4A6CF7).withValues(alpha: 0.3), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.dmSans(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A6CF7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Name and Edit toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isEditingName)
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveName(),
                  ),
                )
              else
                Flexible(
                  child: Text(
                    _currentName,
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D1B3E),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(width: 8),
              if (!_isEditingName)
                GestureDetector(
                  onTap: () => setState(() => _isEditingName = true),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, size: 16, color: Colors.grey),
                  ),
                )
              else
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 20, height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E)),
                        onPressed: _saveName,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatRole(widget.currentUser.role),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF22C55E),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          const Divider(height: 1, color: Color(0xFFF1F4F9)),
          const SizedBox(height: 24),
          
          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text('Sign Out', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                foregroundColor: const Color(0xFFEF4444),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
