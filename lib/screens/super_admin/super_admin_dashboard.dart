import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/ngo_service.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';
import 'manage_admins_screen.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const bg = Color(0xFFF1F5F9);
  static const surface = Colors.white;
  static const dark = Color(0xFF0A0F1E);
  static const darkCard = Color(0xFF141B2D);
  static const indigo = Color(0xFF4F46E5);
  static const indigoLight = Color(0xFFEEF2FF);
  static const green = Color(0xFF10B981);
  static const greenLight = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFFFBEB);
  static const red = Color(0xFFEF4444);
  static const redLight = Color(0xFFFEF2F2);
  static const textPrimary = Color(0xFF0A0F1E);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
}

// ─── Main Widget ──────────────────────────────────────────────────────────────
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard>
    with TickerProviderStateMixin {
  final _ngoService = NgoService();
  final _authService = AuthService();
  final _userService = UserService();

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _staggered;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _staggered = List.generate(5, (i) {
      final start = i * 0.12;
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(
          start.clamp(0, 0.8),
          (start + 0.5).clamp(0, 1),
          curve: Curves.easeOutCubic,
        ),
      );
    });
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ─── Snackbars ───────────────────────────────────────────────────────────
  void _snack(
    String msg, {
    Color bg = _AppColors.green,
    IconData icon = Icons.check_circle_rounded,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: GoogleFonts.dmSans(fontSize: 13))),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Create NGO ──────────────────────────────────────────────────────────
  Future<void> _showCreateNgoDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool loading = false;
        return StatefulBuilder(
          builder: (ctx, setS) {
            return _BottomSheet(
              title: 'Create New NGO',
              subtitle: 'Register your organization',
              icon: Icons.add_business_rounded,
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Field(
                      ctrl: nameCtrl,
                      label: 'NGO Name',
                      icon: Icons.business_rounded,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      ctrl: descCtrl,
                      label: 'Description',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      ctrl: addressCtrl,
                      label: 'Address',
                      icon: Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      ctrl: emailCtrl,
                      label: 'Contact Email',
                      icon: Icons.email_rounded,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _OutlineBtn(
                            label: 'Cancel',
                            onTap: loading ? null : () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _PrimaryBtn(
                            label: 'Create NGO',
                            loading: loading,
                            onTap: () async {
                              if (!formKey.currentState!.validate()) return;
                              setS(() => loading = true);
                              try {
                                final uid = _authService.currentUser?.uid ?? '';
                                final ngo = await _ngoService.createNgo(
                                  name: nameCtrl.text,
                                  description: descCtrl.text,
                                  address: addressCtrl.text,
                                  contactEmail: emailCtrl.text,
                                  superAdminId: uid,
                                );
                                await _userService.assignNgo(uid, ngo.ngoId);
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx, true);
                                _showJoinCodeSheet(ngo.name, ngo.joinCode);
                              } catch (e) {
                                setS(() => loading = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error: $e',
                                        style: GoogleFonts.dmSans(),
                                      ),
                                      backgroundColor: _AppColors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(ctx).viewInsets.bottom > 0 ? 0 : 8,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Join Code Sheet ─────────────────────────────────────────────────────
  void _showJoinCodeSheet(String ngoName, String joinCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            const SizedBox(height: 24),
            // Success Badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _AppColors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: _AppColors.green,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'NGO Created!',
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$ngoName" is ready.\nShare this code with your volunteers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: _AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            // Code Card
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: joinCode));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.copy_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Copied to clipboard',
                          style: GoogleFonts.dmSans(),
                        ),
                      ],
                    ),
                    backgroundColor: _AppColors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _AppColors.indigo.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      joinCode,
                      style: GoogleFonts.spaceMono(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to copy',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _PrimaryBtn(label: 'Done', onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  // ─── My NGOs Sheet ───────────────────────────────────────────────────────
  Future<void> _openManageAdmins() async {
    try {
      _showMyNgosSheet();
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e', bg: _AppColors.red, icon: Icons.error_rounded);
    }
  }

  Future<void> _showMyNgosSheet() async {
    final uid = _authService.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      _snack(
        'Unable to load your NGOs.',
        bg: _AppColors.red,
        icon: Icons.error_rounded,
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: _AppColors.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Header (fixed, doesn't scroll)
              Container(
                decoration: const BoxDecoration(
                  color: _AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  children: [
                    _SheetHandle(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _AppColors.darkCard,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Color(0xFF818CF8),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your NGOs',
                                style: GoogleFonts.dmSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'All organizations you manage',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: _AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _AppColors.bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: _AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Scrollable NGO list
              Expanded(
                child: StreamBuilder(
                  stream: _ngoService.getNgosForSuperAdmin(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: _AppColors.indigo,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _EmptyState(
                        icon: Icons.error_outline_rounded,
                        color: _AppColors.red,
                        title: 'Failed to load',
                        subtitle: 'Something went wrong loading your NGOs.',
                      );
                    }
                    final ngos = snapshot.data ?? [];
                    if (ngos.isEmpty) {
                      return _EmptyState(
                        icon: Icons.business_outlined,
                        color: _AppColors.textTertiary,
                        title: 'No NGOs yet',
                        subtitle: 'Create your first NGO to get started.',
                      );
                    }
                    return ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      itemCount: ngos.length,
                      itemBuilder: (_, i) => _NgoCard(
                        ngo: ngos[i],
                        uid: uid,
                        parentContext: context,
                        onManage: () async {
                          Navigator.pop(ctx);
                          await Future.delayed(
                            const Duration(milliseconds: 120),
                          );
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageAdminsScreen(
                                ngoId: ngos[i].ngoId,
                                superAdminUid: uid,
                              ),
                            ),
                          );
                        },
                        onCopy: () {
                          Clipboard.setData(
                            ClipboardData(text: ngos[i].joinCode),
                          );
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.copy_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Code ${ngos[i].joinCode} copied!',
                                    style: GoogleFonts.dmSans(),
                                  ),
                                ],
                              ),
                              backgroundColor: _AppColors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final today = '${months[now.month - 1]} ${now.day}, ${now.year}';
    final uid = _authService.currentUser?.uid ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _AppColors.bg,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────
              SliverPersistentHeader(
                floating: true,
                delegate: _AppBarDelegate(
                  onLogout: () async {
                    await _authService.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Hero Card ──────────────────────────────────────
                    FadeTransition(
                      opacity: _staggered[0],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(_staggered[0]),
                        child: _HeroCard(
                          uid: uid,
                          today: today,
                          ngoService: _ngoService,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Section Label ──────────────────────────────────
                    FadeTransition(
                      opacity: _staggered[1],
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _AppColors.indigo,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Quick Actions',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Action Cards ───────────────────────────────────
                    ...List.generate(3, (i) {
                      final items = [
                        _ActionItem(
                          title: 'Your NGOs',
                          subtitle: 'View & manage all organizations',
                          icon: Icons.business_rounded,
                          accent: _AppColors.green,
                          accentBg: _AppColors.greenLight,
                          onTap: _showMyNgosSheet,
                          tag: 'View',
                        ),
                        _ActionItem(
                          title: 'Create NGO',
                          subtitle: 'Register a new organization',
                          icon: Icons.add_business_rounded,
                          accent: _AppColors.indigo,
                          accentBg: _AppColors.indigoLight,
                          onTap: _showCreateNgoDialog,
                          tag: 'New',
                        ),
                        _ActionItem(
                          title: 'Manage Users',
                          subtitle: 'View all member accounts',
                          icon: Icons.manage_accounts_rounded,
                          accent: _AppColors.amber,
                          accentBg: _AppColors.amberLight,
                          onTap: _openManageAdmins,
                          tag: 'Admin',
                        ),
                      ];
                      return FadeTransition(
                        opacity: _staggered[i + 2],
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(_staggered[i + 2]),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ActionCard(item: items[i]),
                          ),
                        ),
                      );
                    }),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final String uid, today;
  final NgoService ngoService;
  const _HeroCard({
    required this.uid,
    required this.today,
    required this.ngoService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _AppColors.dark.withOpacity(0.28),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A0F1E), Color(0xFF141B2D), Color(0xFF1a2340)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Background decorations
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _AppColors.indigo.withOpacity(0.12),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                right: 80,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _AppColors.indigo.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: -10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _AppColors.indigo.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _AppColors.indigo.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Color(0xFF818CF8),
                            size: 24,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 10,
                                color: Colors.white.withOpacity(0.45),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                today,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome back',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Super Admin',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Divider
                    Container(height: 1, color: Colors.white.withOpacity(0.07)),
                    const SizedBox(height: 20),
                    // Stats row
                    StreamBuilder(
                      stream: ngoService.getNgosForSuperAdmin(uid),
                      builder: (ctx, snap) {
                        final count = snap.hasData
                            ? (snap.data?.length ?? 0)
                            : 0;
                        return Row(
                          children: [
                            _HeroStat(
                              value: count.toString(),
                              label: 'Total NGOs',
                              icon: Icons.business_rounded,
                              iconColor: const Color(0xFF818CF8),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              color: Colors.white.withOpacity(0.08),
                            ),
                            _HeroStat(
                              value: count > 0 ? 'Active' : 'None',
                              label: 'Status',
                              icon: Icons.circle,
                              iconColor: count > 0
                                  ? _AppColors.green
                                  : Colors.grey.shade600,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color iconColor;
  const _HeroStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                height: 1,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Action Item Model ────────────────────────────────────────────────────────
class _ActionItem {
  final String title, subtitle, tag;
  final IconData icon;
  final Color accent, accentBg;
  final VoidCallback onTap;
  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.accentBg,
    required this.onTap,
    required this.tag,
  });
}

// ─── Action Card (horizontal list-style) ─────────────────────────────────────
class _ActionCard extends StatefulWidget {
  final _ActionItem item;
  const _ActionCard({required this.item});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        item.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.accentBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.accent, size: 26),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: _AppColors.textPrimary,
                        fontSize: 15,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.dmSans(
                        color: _AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Chevron badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item.accentBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.tag,
                      style: GoogleFonts.dmSans(
                        color: item.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: item.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── NGO Card (inside the sheet) ─────────────────────────────────────────────
class _NgoCard extends StatelessWidget {
  final dynamic ngo;
  final String uid;
  final BuildContext parentContext;
  final VoidCallback onManage, onCopy;

  const _NgoCard({
    required this.ngo,
    required this.uid,
    required this.parentContext,
    required this.onManage,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _AppColors.indigoLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: _AppColors.indigo,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ngo.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (ngo.contactEmail.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.email_rounded,
                                  size: 11,
                                  color: _AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    ngo.contactEmail,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: _AppColors.textTertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (ngo.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    ngo.description,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: _AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                // Join Code Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _AppColors.indigo.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.vpn_key_rounded,
                        size: 12,
                        color: _AppColors.indigo,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Join Code  ',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        ngo.joinCode,
                        style: GoogleFonts.spaceMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _AppColors.indigo,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(height: 1, color: _AppColors.border),
          // Action row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: _SheetBtn(
                    label: 'Manage Members',
                    icon: Icons.people_rounded,
                    color: _AppColors.indigo,
                    bg: _AppColors.indigoLight,
                    onTap: onManage,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetBtn(
                    label: 'Copy Code',
                    icon: Icons.copy_rounded,
                    color: _AppColors.green,
                    bg: _AppColors.greenLight,
                    onTap: onCopy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Sheet Container ───────────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Widget child;

  const _BottomSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _AppColors.darkCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFF818CF8), size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: _AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Sheet Button (properly aligned) ─────────────────────────────────
class _SheetBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _SheetBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  State<_SheetBtn> createState() => _SheetBtnState();
}

class _SheetBtnState extends State<_SheetBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 15, color: widget.color),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Form Field ───────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? type;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: type,
      style: GoogleFonts.dmSans(fontSize: 14, color: _AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
          color: _AppColors.textTertiary,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, size: 18, color: _AppColors.textTertiary),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _AppColors.indigo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _AppColors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'This field is required' : null,
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const _PrimaryBtn({required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _AppColors.dark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

// ─── Outline Button ───────────────────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _OutlineBtn({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: _AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const _EmptyState({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: _AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet Handle ─────────────────────────────────────────────────────────────
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: _AppColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ─── Custom App Bar Delegate ──────────────────────────────────────────────────
class _AppBarDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onLogout;
  const _AppBarDelegate({required this.onLogout});

  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 70;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 70,
      color: _AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _AppColors.darkCard,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF818CF8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Super Admin',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: _AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _AppColors.redLight,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _AppColors.red.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: _AppColors.red,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Logout',
                    style: GoogleFonts.dmSans(
                      color: _AppColors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
