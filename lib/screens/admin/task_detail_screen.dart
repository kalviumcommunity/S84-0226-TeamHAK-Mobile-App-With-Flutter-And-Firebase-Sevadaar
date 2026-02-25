import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/task_model.dart';
import '../../models/task_assignment_model.dart';
import '../../models/progress_request_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import 'admin_dashboard.dart' show taskUrgencyColor;

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final String adminId;
  final String ngoId;
  final TaskService taskService;
  final UserService userService;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.adminId,
    required this.ngoId,
    required this.taskService,
    required this.userService,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final Set<String> _selectedToInvite = {};
  final _finalNoteCtrl = TextEditingController();
  bool _completingTask = false;

  @override
  void dispose() {
    _finalNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06110B),
      body: StreamBuilder<TaskModel?>(
        stream: widget.taskService.streamTask(widget.taskId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF42A5F5)));
          }
          final task = snap.data;
          if (task == null) {
            return const Center(
                child: Text('Task not found.',
                    style: TextStyle(color: Colors.white54)));
          }
          return _buildBody(task);
        },
      ),
    );
  }

  Widget _buildBody(TaskModel task) {
    final urgency = taskUrgencyColor(task.createdAt, task.deadline);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E2419), Color(0xFF091A10), Color(0xFF06110B)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(task.title,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  _StatusBadge(status: task.status),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                children: [
                  // ── Progress Header Card ──────────────────────
                  _ProgressHeaderCard(task: task, urgency: urgency),
                  const SizedBox(height: 16),

                  // ── Pending Progress Requests ─────────────────
                  StreamBuilder<List<ProgressRequestModel>>(
                    stream: widget.taskService
                        .streamPendingRequestsForAdmin(widget.adminId),
                    builder: (context, reqSnap) {
                      final allRequests = reqSnap.data ?? [];
                      final taskRequests = allRequests
                          .where((r) => r.taskId == widget.taskId)
                          .toList();
                      if (taskRequests.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                              icon: Icons.pending_actions_rounded,
                              label: 'Pending Progress Requests',
                              count: taskRequests.length,
                              color: const Color(0xFFFF9800)),
                          const SizedBox(height: 8),
                          ...taskRequests.map((r) => _InlineRequestCard(
                                request: r,
                                taskService: widget.taskService,
                                userService: widget.userService,
                              )),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                  // ── Assigned Volunteers ───────────────────────
                  StreamBuilder<List<TaskAssignmentModel>>(
                    stream: widget.taskService
                        .streamTaskAssignments(widget.taskId),
                    builder: (context, assignSnap) {
                      final assignments = assignSnap.data ?? [];
                      if (assignments.isEmpty &&
                          task.assignedVolunteers.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                              icon: Icons.group_rounded,
                              label: 'Assigned Volunteers',
                              count: task.assignedVolunteers.length,
                              color: const Color(0xFF4CAF50)),
                          const SizedBox(height: 8),
                          ...task.assignedVolunteers.map((uid) {
                            final assignment = assignments
                                .where((a) => a.volunteerId == uid)
                                .firstOrNull;
                            return _AssignedVolunteerRow(
                              volunteerId: uid,
                              progress: assignment?.individualProgress ?? 0.0,
                              userService: widget.userService,
                              onRemove: task.status != 'completed'
                                  ? () => _confirmRemove(task, uid)
                                  : null,
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                  // ── Pending Invites ───────────────────────────
                  if (task.pendingInvites.isNotEmpty &&
                      task.status == 'inviting') ...[
                    _SectionHeader(
                        icon: Icons.mail_outline_rounded,
                        label: 'Pending Invites',
                        count: task.pendingInvites.length,
                        color: const Color(0xFF42A5F5)),
                    const SizedBox(height: 8),
                    ...task.pendingInvites.map((uid) => _PendingInviteRow(
                          volunteerId: uid,
                          userService: widget.userService,
                          onCancel: () => widget.taskService
                              .cancelInvite(widget.taskId, uid),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // ── Invite Volunteers ─────────────────────────
                  if (task.status == 'inviting' &&
                      task.assignedVolunteers.length < task.maxVolunteers) ...[
                    _SectionHeader(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Invite Volunteers',
                        color: Colors.white54),
                    const SizedBox(height: 8),
                    StreamBuilder<List<UserModel>>(
                      stream: widget.taskService
                          .streamNgoVolunteers(widget.ngoId),
                      builder: (context, volSnap) {
                        final allVols = volSnap.data ?? [];
                        final already = {
                          ...task.assignedVolunteers,
                          ...task.pendingInvites,
                          ...task.declinedBy,
                        };
                        final eligible =
                            allVols.where((v) => !already.contains(v.uid)).toList();

                        if (eligible.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'All NGO volunteers have been invited.',
                              style: GoogleFonts.poppins(
                                  color: Colors.white38, fontSize: 13),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...eligible.map((v) => _InviteCheckRow(
                                  volunteer: v,
                                  selected:
                                      _selectedToInvite.contains(v.uid),
                                  onToggle: (val) {
                                    setState(() {
                                      if (val) {
                                        _selectedToInvite.add(v.uid);
                                      } else {
                                        _selectedToInvite.remove(v.uid);
                                      }
                                    });
                                  },
                                )),
                            const SizedBox(height: 8),
                            if (_selectedToInvite.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _sendInvites,
                                  icon: const Icon(Icons.send_rounded,
                                      color: Colors.white, size: 16),
                                  label: Text(
                                      'Send Invites (${_selectedToInvite.length})',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF42A5F5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ],

                  // ── Complete Task Section ─────────────────────
                  if (task.status != 'completed') ...[
                    _SectionHeader(
                        icon: Icons.flag_rounded,
                        label: 'Complete Task',
                        color: const Color(0xFF4CAF50)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _finalNoteCtrl,
                      maxLines: 3,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Final note (optional)',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF4CAF50)),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _completingTask
                            ? null
                            : () => _completeTask(task),
                        icon: _completingTask
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline_rounded,
                                color: Colors.white, size: 18),
                        label: Text('Mark as Completed',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],

                  // ── Final Note (if completed) ─────────────────
                  if (task.status == 'completed' &&
                      task.adminFinalNote.isNotEmpty) ...[
                    _SectionHeader(
                        icon: Icons.sticky_note_2_outlined,
                        label: 'Final Note',
                        color: Colors.white54),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(task.adminFinalNote,
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvites() async {
    try {
      await widget.taskService.inviteVolunteers(
          widget.taskId, _selectedToInvite.toList());
      setState(() => _selectedToInvite.clear());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Invites sent!', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF42A5F5),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _confirmRemove(TaskModel task, String volunteerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E2419),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Volunteer?',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text(
            'This volunteer will be removed and progress will be recalculated.',
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: Colors.white54))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Remove',
                  style: GoogleFonts.poppins(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.taskService.removeVolunteer(widget.taskId, volunteerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Volunteer removed.', style: GoogleFonts.poppins()),
        backgroundColor: Colors.orange,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _completeTask(TaskModel task) async {
    setState(() => _completingTask = true);
    try {
      await widget.taskService.completeTask(
          widget.taskId, _finalNoteCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Task completed!', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF4CAF50),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _completingTask = false);
    }
  }
}

// ── Progress Header Card ──────────────────────────────────────────
class _ProgressHeaderCard extends StatelessWidget {
  final TaskModel task;
  final Color urgency;
  const _ProgressHeaderCard({required this.task, required this.urgency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2419),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular progress + info
          Row(
            children: [
              SizedBox(
                width: 80, height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80, height: 80,
                      child: CircularProgressIndicator(
                        value: task.mainProgress / 100,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(urgency),
                        strokeWidth: 7,
                      ),
                    ),
                    Text('${task.mainProgress.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                            color: urgency,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.description,
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    _infoRow(Icons.schedule_outlined,
                        'Due ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}'),
                    const SizedBox(height: 4),
                    _infoRow(Icons.people_outline,
                        '${task.assignedVolunteers.length}/${task.maxVolunteers} volunteers'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Urgency label
          _UrgencyBadge(urgency: urgency, createdAt: task.createdAt, deadline: task.deadline),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 5),
        Expanded(
          child: Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  final Color urgency;
  final DateTime createdAt, deadline;
  const _UrgencyBadge(
      {required this.urgency,
      required this.createdAt,
      required this.deadline});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final total = deadline.difference(createdAt).inMinutes;
    final remaining = deadline.difference(now).inMinutes;
    final pct = total > 0 ? (remaining / total) * 100 : 0.0;

    String label;
    if (pct > 50) {
      label = 'ON TRACK';
    } else if (pct > 30) {
      label = 'CAUTION';
    } else {
      label = 'URGENT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: urgency.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: urgency.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              color: urgency, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int? count;
  const _SectionHeader(
      {required this.icon,
      required this.label,
      required this.color,
      this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}

// ── Assigned Volunteer Row ────────────────────────────────────────
class _AssignedVolunteerRow extends StatefulWidget {
  final String volunteerId;
  final double progress;
  final UserService userService;
  final VoidCallback? onRemove;
  const _AssignedVolunteerRow({
    required this.volunteerId,
    required this.progress,
    required this.userService,
    this.onRemove,
  });

  @override
  State<_AssignedVolunteerRow> createState() => _AssignedVolunteerRowState();
}

class _AssignedVolunteerRowState extends State<_AssignedVolunteerRow> {
  String? _name;

  @override
  void initState() {
    super.initState();
    widget.userService.getUserById(widget.volunteerId).then((u) {
      if (mounted && u != null) setState(() => _name = u.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _name ?? '...';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                const Color(0xFF4CAF50).withValues(alpha: 0.2),
            child: Text(name[0].toUpperCase(),
                style: GoogleFonts.poppins(
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: widget.progress / 100,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF4CAF50)),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${widget.progress.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF4CAF50),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          if (widget.onRemove != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_remove_rounded,
                    color: Colors.red, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pending Invite Row ────────────────────────────────────────────
class _PendingInviteRow extends StatefulWidget {
  final String volunteerId;
  final UserService userService;
  final Future<void> Function() onCancel;
  const _PendingInviteRow({
    required this.volunteerId,
    required this.userService,
    required this.onCancel,
  });

  @override
  State<_PendingInviteRow> createState() => _PendingInviteRowState();
}

class _PendingInviteRowState extends State<_PendingInviteRow> {
  String? _name;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    widget.userService.getUserById(widget.volunteerId).then((u) {
      if (mounted && u != null) setState(() => _name = u.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                const Color(0xFF42A5F5).withValues(alpha: 0.15),
            child: Text((_name ?? '?')[0].toUpperCase(),
                style: GoogleFonts.poppins(
                    color: const Color(0xFF42A5F5),
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_name ?? widget.volunteerId,
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('INVITED',
                style: GoogleFonts.poppins(
                    color: const Color(0xFF42A5F5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          _cancelling
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.orange, strokeWidth: 2))
              : GestureDetector(
                  onTap: () async {
                    setState(() => _cancelling = true);
                    await widget.onCancel();
                    if (mounted) setState(() => _cancelling = false);
                  },
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white38, size: 18),
                ),
        ],
      ),
    );
  }
}

// ── Invite Checkbox Row ───────────────────────────────────────────
class _InviteCheckRow extends StatelessWidget {
  final UserModel volunteer;
  final bool selected;
  final ValueChanged<bool> onToggle;
  const _InviteCheckRow({
    required this.volunteer,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!selected),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF42A5F5).withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF42A5F5).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              child: Text(volunteer.name[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(volunteer.name,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 13)),
                  Text(volunteer.email,
                      style: GoogleFonts.poppins(
                          color: Colors.white38, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? const Color(0xFF42A5F5)
                  : Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inline Request Card ───────────────────────────────────────────
class _InlineRequestCard extends StatefulWidget {
  final ProgressRequestModel request;
  final TaskService taskService;
  final UserService userService;
  const _InlineRequestCard({
    required this.request,
    required this.taskService,
    required this.userService,
  });

  @override
  State<_InlineRequestCard> createState() => _InlineRequestCardState();
}

class _InlineRequestCardState extends State<_InlineRequestCard> {
  String? _name;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    widget.userService.getUserById(widget.request.volunteerId).then((u) {
      if (mounted && u != null) setState(() => _name = u.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFF9800).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_name ?? '...',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    '${req.currentProgress.toStringAsFixed(0)}% → ${req.requestedProgress.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFFFF9800),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (req.mandatoryNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(req.mandatoryNote,
                style: GoogleFonts.poppins(
                    color: Colors.white54, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          if (_processing)
            const SizedBox(
                height: 20,
                child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF42A5F5), strokeWidth: 2)))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _act(approve: false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: Text('Reject',
                        style: GoogleFonts.poppins(
                            color: Colors.red, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _act(approve: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: Size.zero,
                      elevation: 0,
                    ),
                    child: Text('Approve',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _act({required bool approve}) async {
    setState(() => _processing = true);
    try {
      if (approve) {
        await widget.taskService.approveProgressRequest(widget.request);
      } else {
        await widget.taskService.rejectProgressRequest(widget.request);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }
}

// ── Status Badge ──────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = const Color(0xFF4CAF50);
        break;
      case 'completed':
        color = Colors.white38;
        break;
      default:
        color = const Color(0xFF42A5F5);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(status.toUpperCase(),
          style: GoogleFonts.poppins(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
