import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/ngo_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/ngo_request_service.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';

/// Developer Admin Dashboard — view & manage all NGO requests.
class DeveloperAdminDashboard extends StatefulWidget {
  const DeveloperAdminDashboard({super.key});

  @override
  State<DeveloperAdminDashboard> createState() =>
      _DeveloperAdminDashboardState();
}

class _DeveloperAdminDashboardState extends State<DeveloperAdminDashboard>
    with SingleTickerProviderStateMixin {
  final _ngoRequestService = NgoRequestService();
  final _userService = UserService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A74F8),
        elevation: 0,
        title: Text(
          'Developer Admin',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RequestList(status: 'pending', service: _ngoRequestService, userService: _userService),
          _RequestList(status: 'approved', service: _ngoRequestService, userService: _userService),
          _RequestList(status: 'rejected', service: _ngoRequestService, userService: _userService),
        ],
      ),
    );
  }
}

// ── Request List by Status ──────────────────────────────────────
class _RequestList extends StatelessWidget {
  final String status;
  final NgoRequestService service;
  final UserService userService;

  const _RequestList({
    required this.status,
    required this.service,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NgoRequestModel>>(
      stream: service.streamRequestsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_rounded,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No $status requests',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return _RequestCard(
              request: req,
              service: service,
              userService: userService,
            );
          },
        );
      },
    );
  }
}

// ── Individual Request Card ─────────────────────────────────────
class _RequestCard extends StatefulWidget {
  final NgoRequestModel request;
  final NgoRequestService service;
  final UserService userService;

  const _RequestCard({
    required this.request,
    required this.service,
    required this.userService,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _processing = false;
  String? _requesterName;

  @override
  void initState() {
    super.initState();
    _loadRequesterName();
  }

  Future<void> _loadRequesterName() async {
    try {
      final user =
          await widget.userService.getUserById(widget.request.requestedBy);
      if (mounted && user != null) {
        setState(() => _requesterName = user.name);
      }
    } catch (_) {}
  }

  Future<void> _approve() async {
    setState(() => _processing = true);
    try {
      final ngo = await widget.service.approveRequest(widget.request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Approved! NGO Code: ${ngo.joinCode}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF43A047),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Request?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to reject this NGO request?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processing = true);
    try {
      await widget.service.rejectRequest(widget.request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request rejected.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final isPending = req.status == 'pending';

    Color statusColor;
    switch (req.status) {
      case 'approved':
        statusColor = const Color(0xFF43A047);
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A74F8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business_rounded,
                      color: Color(0xFF6A74F8)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.ngoName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Reg: ${req.registrationNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    req.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            _detailRow(Icons.person_outline, 'Requested by',
                _requesterName ?? req.requestedBy),
            _detailRow(Icons.email_outlined, 'Email', req.contactEmail),
            _detailRow(Icons.location_on_outlined, 'Address', req.address),
            if (req.description.isNotEmpty)
              _detailRow(Icons.description_outlined, 'Description',
                  req.description),
            if (req.certificateUrl.isNotEmpty)
              _detailRow(Icons.file_present_rounded, 'Certificate', 'Uploaded'),

            // Action buttons (only for pending)
            if (isPending) ...[
              const Divider(height: 24),
              if (_processing)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reject,
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.red, size: 18),
                        label: Text('Reject',
                            style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontWeight: FontWeight.w500)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _approve,
                        icon: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18),
                        label: Text('Approve',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
