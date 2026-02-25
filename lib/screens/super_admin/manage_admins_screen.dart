import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

/// Allows the Super Admin to view all NGO members and
/// toggle any volunteer ↔ admin for their NGO.
class ManageAdminsScreen extends StatelessWidget {
  final String ngoId;
  final String superAdminUid;

  const ManageAdminsScreen({
    super.key,
    required this.ngoId,
    required this.superAdminUid,
  });

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A74F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Members',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'Promote volunteers to Admin or demote Admins back to Volunteer.',
              style: GoogleFonts.poppins(
                  color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: userService.streamNgoMembers(ngoId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: GoogleFonts.poppins(color: Colors.red)),
            );
          }

          final members = snap.data ?? [];
          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No members in this NGO yet.',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Text(
                      'Share your NGO join code with volunteers\nso they can join your organization.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }

          // Sort: super_admin first, then admin, then volunteer
          final sorted = [...members];
          sorted.sort((a, b) {
            const order = {'super_admin': 0, 'admin': 1, 'volunteer': 2};
            return (order[a.role] ?? 3).compareTo(order[b.role] ?? 3);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (_, i) => _MemberCard(
              member: sorted[i],
              superAdminUid: superAdminUid,
              userService: userService,
            ),
          );
        },
      ),
    );
  }
}

// ── Member Card ───────────────────────────────────────────────────
class _MemberCard extends StatefulWidget {
  final UserModel member;
  final String superAdminUid;
  final UserService userService;

  const _MemberCard({
    required this.member,
    required this.superAdminUid,
    required this.userService,
  });

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  bool _processing = false;

  bool get _isSuperAdmin => widget.member.role == 'super_admin';
  bool get _isDeveloperAdmin => widget.member.role == 'developer_admin';
  bool get _isAdmin => widget.member.role == 'admin';
  bool get _isCurrentUser => widget.member.uid == widget.superAdminUid;

  Future<void> _toggleRole() async {
    final isPromoting = widget.member.role == 'volunteer';
    final action = isPromoting ? 'Promote to Admin' : 'Demote to Volunteer';
    final msg = isPromoting
        ? '${widget.member.name} will be able to create tasks and manage volunteers.'
        : '${widget.member.name} will lose their admin privileges.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(action,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(msg, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPromoting
                  ? const Color(0xFF4CAF50)
                  : Colors.orange,
            ),
            child: Text(
              isPromoting ? 'Promote' : 'Demote',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processing = true);
    try {
      if (isPromoting) {
        await widget.userService.promoteToAdmin(widget.member.uid);
      } else {
        await widget.userService.demoteToVolunteer(widget.member.uid);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isPromoting
              ? '${widget.member.name} is now an Admin.'
              : '${widget.member.name} is now a Volunteer.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor:
            isPromoting ? const Color(0xFF4CAF50) : Colors.orange,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleData = _roleDisplay(widget.member.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  roleData.$2.withValues(alpha: 0.15),
              child: Text(
                widget.member.name.isNotEmpty
                    ? widget.member.name[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                    color: roleData.$2,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),

            // Name + email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.member.name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF2D3142))),
                      if (_isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('you',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade600)),
                        ),
                      ],
                    ],
                  ),
                  Text(widget.member.email,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Role chip + action
            if (_processing)
              const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else if (_isSuperAdmin || _isDeveloperAdmin || _isCurrentUser)
              // Locked — cannot be modified
              _RoleChip(label: roleData.$1, color: roleData.$2)
            else
              _ToggleButton(
                isAdmin: _isAdmin,
                onTap: _toggleRole,
              ),
          ],
        ),
      ),
    );
  }

  (String, Color) _roleDisplay(String role) {
    switch (role) {
      case 'super_admin':
        return ('Super Admin', const Color(0xFF6A74F8));
      case 'developer_admin':
        return ('Dev Admin', const Color(0xFF9C27B0));
      case 'admin':
        return ('Admin', const Color(0xFF2196F3));
      default:
        return ('Volunteer', const Color(0xFF4CAF50));
    }
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RoleChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onTap;
  const _ToggleButton({required this.isAdmin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isAdmin
              ? Colors.orange.withValues(alpha: 0.1)
              : const Color(0xFF4CAF50).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAdmin
                ? Colors.orange.withValues(alpha: 0.5)
                : const Color(0xFF4CAF50).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAdmin
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 13,
              color: isAdmin ? Colors.orange : const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 4),
            Text(
              isAdmin ? 'Demote' : 'Promote',
              style: GoogleFonts.poppins(
                color: isAdmin ? Colors.orange : const Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
