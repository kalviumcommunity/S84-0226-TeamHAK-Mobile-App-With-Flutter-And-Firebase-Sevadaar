import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/notice_model.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFEEF2F8);
  static const heroCard = Color(0xFF0D1B3E);
  static const textPri = Color(0xFF0D1B3E);
  static const textSec = Color(0xFF6B7280);
  static const red = Color(0xFFEF4444);
  static const redLight = Color(0xFFFEF2F2);
  static const divider = Color(0xFFF1F4F9);
}

class NoticesTab extends StatelessWidget {
  final UserModel currentUser;

  const NoticesTab({super.key, required this.currentUser});

  Stream<List<NoticeModel>> _streamNotices() {
    return FirebaseFirestore.instance
        .collection('notices')
        .where('volunteerId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => NoticeModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
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
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Header
            SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _C.heroCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notices',
                            style: GoogleFonts.dmSans(
                              color: _C.textPri,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Important updates regarding your tasks',
                            style: GoogleFonts.dmSans(
                              color: _C.textSec,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Notices List
            StreamBuilder<List<NoticeModel>>(
              stream: _streamNotices(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: _C.red),
                    ),
                  );
                }

                if (snap.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: _C.red,
                            size: 40,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load notices.',
                            style: GoogleFonts.dmSans(color: _C.textSec),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final notices = snap.data ?? [];

                if (notices.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: _C.textSec.withValues(alpha: 0.5),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'You have no notices.',
                            style: GoogleFonts.dmSans(
                              color: _C.textSec,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  // Extra padding at bottom so content isn't hidden by bottom nav bar
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final notice = notices[index];
                      final formattedDate = DateFormat(
                        'MMM d, yyyy • h:mm a',
                      ).format(notice.createdAt);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _C.redLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_remove_rounded,
                                    color: _C.red,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Removed from Task',
                                    style: GoogleFonts.dmSans(
                                      color: _C.textPri,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              notice.taskTitle,
                              style: GoogleFonts.dmSans(
                                color: _C.textPri,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notice.reason,
                              style: GoogleFonts.dmSans(
                                color: _C.textSec,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(height: 1, color: _C.divider),
                            const SizedBox(height: 12),
                            Text(
                              formattedDate,
                              style: GoogleFonts.dmSans(
                                color: _C.textSec.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }, childCount: notices.length),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
