import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/task_model.dart';
import '../../models/progress_request_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

// ── Urgency colour helper ─────────────────────────────────────────
Color taskUrgencyColor(DateTime createdAt, DateTime deadline) {
  final now = DateTime.now();
  final total = deadline.difference(createdAt).inMinutes;
  final remaining = deadline.difference(now).inMinutes;
  if (remaining <= 0 || total <= 0) return const Color(0xFFF44336);
  final pct = (remaining / total) * 100;
  if (pct > 50) return const Color(0xFF4CAF50);
  if (pct > 30) return const Color(0xFFFF9800);
  return const Color(0xFFF44336);
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _auth = AuthService();
  final _taskService = TaskService();
  final _userService = UserService();

  int _selectedTab = 0;
  UserModel? _currentUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final uid = _auth.currentUser?.uid ?? '';
      final profile = await _auth.getUserProfile(uid);
      if (mounted) setState(() { _currentUser = profile; _loadingUser = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFF06110B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF42A5F5))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF06110B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E2419), Color(0xFF091A10), Color(0xFF06110B)],
          ),
        ),
        child: _selectedTab == 0
            ? _TasksTab(
                currentUser: _currentUser,
                taskService: _taskService,
                userService: _userService,
              )
            : _RequestsTab(
                currentUser: _currentUser,
                taskService: _taskService,
                userService: _userService,
              ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF42A5F5),
              onPressed: () {
                if (_currentUser == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateTaskScreen(
                      adminId: _currentUser!.uid,
                      ngoId: _currentUser!.ngoId ?? '',
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E2419),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _NavItem(
              icon: Icons.task_alt_rounded,
              label: 'Tasks',
              selected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            _NavItem(
              icon: Icons.pending_actions_rounded,
              label: 'Requests',
              selected: _selectedTab == 1,
              badge: _currentUser != null
                  ? StreamBuilder<List<ProgressRequestModel>>(
                      stream: _taskService.streamPendingRequestsForAdmin(
                          _currentUser!.uid),
                      builder: (_, snap) {
                        final count = snap.data?.length ?? 0;
                        return count > 0
                            ? Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFF44336),
                                    shape: BoxShape.circle),
                              )
                            : const SizedBox.shrink();
                      })
                  : null,
              onTap: () => setState(() => _selectedTab = 1),
            ),
            _NavItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              selected: false,
              onTap: () async {
                await _auth.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Nav Item ───────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? badge;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF42A5F5) : Colors.white38;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (badge != null)
                    Positioned(top: -4, right: -4, child: badge!),
                ],
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 1 — TASKS
// ═══════════════════════════════════════════════════════════════════
class _TasksTab extends StatelessWidget {
  final UserModel? currentUser;
  final TaskService taskService;
  final UserService userService;

  const _TasksTab({
    required this.currentUser,
    required this.taskService,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return _emptyState('Could not load profile.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(currentUser: currentUser!),
        Expanded(
          child: StreamBuilder<List<TaskModel>>(
            stream: taskService.streamAdminTasks(currentUser!.uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF42A5F5)));
              }
              if (snap.hasError) {
                return _emptyState('Error loading tasks:\n${snap.error}');
              }
              final tasks = snap.data ?? [];
              if (tasks.isEmpty) {
                return _emptyState(
                    'No tasks yet.\nTap + to create your first task.');
              }

              final active = tasks.where((t) => t.status == 'active').length;
              final inviting = tasks.where((t) => t.status == 'inviting').length;
              final completed = tasks.where((t) => t.status == 'completed').length;

              return Column(
                children: [
                  _StatBar(active: active, inviting: inviting, completed: completed),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: tasks.length,
                      itemBuilder: (_, i) => _TaskCard(
                        task: tasks[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(
                              taskId: tasks[i].taskId,
                              adminId: currentUser!.uid,
                              ngoId: currentUser!.ngoId ?? '',
                              taskService: taskService,
                              userService: userService,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined,
              size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final UserModel currentUser;
  const _Header({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                  stops: [0.1, 1.0],
                ),
              ),
              child: Center(
                child: Text(
                  currentUser.name.isNotEmpty
                      ? currentUser.name[0].toUpperCase()
                      : 'A',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 12)),
                  Text(currentUser.name,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.4)),
              ),
              child: Text('ADMIN',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF42A5F5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Bar ──────────────────────────────────────────────────────
class _StatBar extends StatelessWidget {
  final int active, inviting, completed;
  const _StatBar(
      {required this.active, required this.inviting, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Stat(label: 'Active', value: active, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          _Stat(label: 'Inviting', value: inviting, color: const Color(0xFF42A5F5)),
          const SizedBox(width: 8),
          _Stat(label: 'Done', value: completed, color: Colors.white38),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: GoogleFonts.poppins(
                    color: color, fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label,
                style: GoogleFonts.poppins(
                    color: color.withValues(alpha: 0.8), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Task Card ─────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final urgency = taskUrgencyColor(task.createdAt, task.deadline);
    final statusData = _statusData(task.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0E2419),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: urgency,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(task.title,
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(label: statusData.$1, color: statusData.$2),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(task.description,
                          style: GoogleFonts.poppins(
                              color: Colors.white54, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: task.mainProgress / 100,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(urgency),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_outline,
                                  size: 14, color: Colors.white38),
                              const SizedBox(width: 4),
                              Text(
                                '${task.assignedVolunteers.length}/${task.maxVolunteers}',
                                style: GoogleFonts.poppins(
                                    color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                          Text('${task.mainProgress.toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                  color: urgency,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined,
                              size: 13, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
                            style: GoogleFonts.poppins(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _statusData(String status) {
    switch (status) {
      case 'active':
        return ('ACTIVE', const Color(0xFF4CAF50));
      case 'completed':
        return ('DONE', Colors.white38);
      default:
        return ('INVITING', const Color(0xFF42A5F5));
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 2 — PROGRESS REQUESTS
// ═══════════════════════════════════════════════════════════════════
class _RequestsTab extends StatelessWidget {
  final UserModel? currentUser;
  final TaskService taskService;
  final UserService userService;

  const _RequestsTab({
    required this.currentUser,
    required this.taskService,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(
          child: Text('Could not load profile.',
              style: TextStyle(color: Colors.white54)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Pending Requests',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ProgressRequestModel>>(
            stream: taskService.streamPendingRequestsForAdmin(currentUser!.uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF42A5F5)));
              }
              final requests = snap.data ?? [];
              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('No pending requests',
                          style: GoogleFonts.poppins(
                              color: Colors.white38, fontSize: 14)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: requests.length,
                itemBuilder: (_, i) => _RequestCard(
                  request: requests[i],
                  taskService: taskService,
                  userService: userService,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Progress Request Card ─────────────────────────────────────────
class _RequestCard extends StatefulWidget {
  final ProgressRequestModel request;
  final TaskService taskService;
  final UserService userService;

  const _RequestCard({
    required this.request,
    required this.taskService,
    required this.userService,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _processing = false;
  String? _volunteerName;

  @override
  void initState() {
    super.initState();
    _loadVolunteerName();
  }

  Future<void> _loadVolunteerName() async {
    final user =
        await widget.userService.getUserById(widget.request.volunteerId);
    if (mounted && user != null) {
      setState(() => _volunteerName = user.name);
    }
  }

  Future<void> _approve() async {
    setState(() => _processing = true);
    try {
      await widget.taskService.approveProgressRequest(widget.request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Progress approved!', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF4CAF50),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E2419),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Request?',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('The volunteer\'s progress will not be updated.',
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: Colors.white54))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Reject',
                  style: GoogleFonts.poppins(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _processing = true);
    try {
      await widget.taskService.rejectProgressRequest(widget.request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request rejected.', style: GoogleFonts.poppins()),
        backgroundColor: Colors.orange,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2419),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    const Color(0xFF42A5F5).withValues(alpha: 0.2),
                child: Text(
                  (_volunteerName ?? '?')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF42A5F5),
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_volunteerName ?? req.volunteerId,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text(req.taskTitle,
                        style: GoogleFonts.poppins(
                            color: Colors.white54, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _ProgressPill(value: req.currentProgress, color: Colors.white38),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white38, size: 16),
                const SizedBox(width: 8),
                _ProgressPill(
                    value: req.requestedProgress,
                    color: const Color(0xFF4CAF50)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (req.mandatoryNote.isNotEmpty) ...[
            Text('Note:',
                style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(req.mandatoryNote,
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
          ],
          if (_processing)
            const Center(
                child: CircularProgressIndicator(color: Color(0xFF42A5F5)))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reject,
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.red, size: 16),
                    label: Text('Reject',
                        style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.w500)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _approve,
                    icon: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16),
                    label: Text('Approve',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final double value;
  final Color color;
  const _ProgressPill({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text('${value.toStringAsFixed(0)}%',
          style: GoogleFonts.poppins(
              color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
