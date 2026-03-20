import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/notification_model.dart';

class _C {
  static const textPri = Color(0xFF0D1B3E);
  static const textSec = Color(0xFF6B7280);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);
  static const blue = Color(0xFF3B82F6);
}

class NotificationsTab extends StatefulWidget {
  final UserModel currentUser;

  const NotificationsTab({super.key, required this.currentUser});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  @override
  void initState() {
    super.initState();
    _cleanupOldNotifications();
  }

  /// Automatically deletes notifications older than 7 days from Firebase
  Future<void> _cleanupOldNotifications() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    try {
      // Query without inequality to avoid composite index requirement,
      // we just filter manually for deletion
      final snap = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientUid', isEqualTo: widget.currentUser.uid)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      int deleteCount = 0;

      for (var doc in snap.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          // If it's strictly older than 7 days
          if (createdAt.isBefore(sevenDaysAgo)) {
            batch.delete(doc.reference);
            deleteCount++;
          }
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        debugPrint('Cleaned up $deleteCount old notifications');
      }
    } catch (e) {
      debugPrint('Error cleaning up notifications: $e');
    }
  }

  Stream<List<NotificationModel>> _streamNotifications() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientUid', isEqualTo: widget.currentUser.uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => NotificationModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  String _getSectionTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(targetDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Text(
                'Notifications',
                style: GoogleFonts.dmSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _C.textPri,
                  letterSpacing: -1,
                ),
              ),
            ),

            // List
            Expanded(
              child: StreamBuilder<List<NotificationModel>>(
                stream: _streamNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading notifications\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(color: _C.red),
                      ),
                    );
                  }

                  // 1. Get raw list
                  final rawList = snapshot.data ?? [];

                  // 2. Filter out items older than 7 days (in case cleanup hasn't completed yet)
                  final sevenDaysAgo = DateTime.now().subtract(
                    const Duration(days: 7),
                  );
                  final notifications = rawList.where((n) {
                    return n.createdAt.isAfter(sevenDaysAgo);
                  }).toList();

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: _C.textSec.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _C.textPri,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You're all caught up!",
                            style: GoogleFonts.dmSans(color: _C.textSec),
                          ),
                        ],
                      ),
                    );
                  }

                  // 3. Group by date section
                  final grouped = <String, List<NotificationModel>>{};
                  for (var notif in notifications) {
                    final title = _getSectionTitle(notif.createdAt);
                    grouped.putIfAbsent(title, () => []).add(notif);
                  }

                  // 4. Ensure order of sections (Today first, then Yesterday, then older)
                  final sortedKeys = grouped.keys.toList()
                    ..sort((a, b) {
                      // Extract a date value from the title to sort appropriately
                      DateTime dateA = grouped[a]!.first.createdAt;
                      DateTime dateB = grouped[b]!.first.createdAt;
                      return dateB.compareTo(dateA); // descending
                    });

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final sectionKey = sortedKeys[index];
                      final items = grouped[sectionKey]!;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(bottom: 8),
                            initiallyExpanded: sectionKey == 'Today',
                            title: Text(
                              sectionKey,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _C.textPri,
                              ),
                            ),
                            children: items.map((notif) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _NotificationCard(notification: notif),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    // Determine icon and color based on type
    IconData icon = Icons.notifications_rounded;
    Color iconColor = _C.blue;
    Color bgColor = _C.blue.withValues(alpha: 0.1);

    if (notification.type == 'promotion') {
      icon = Icons.star_rounded;
      iconColor = _C.green;
      bgColor = _C.green.withValues(alpha: 0.1);
    } else if (notification.type == 'demotion') {
      icon = Icons.trending_down_rounded;
      iconColor = _C.red;
      bgColor = _C.red.withValues(alpha: 0.1);
    } else if (notification.type == 'task') {
      icon = Icons.task_alt_rounded;
      iconColor = _C.blue;
      bgColor = _C.blue.withValues(alpha: 0.1);
    } else if (notification.type == 'progress') {
      icon = Icons.update_rounded;
      iconColor = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFEF3C7);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _C.textPri,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM d, h:mm a',
                      ).format(notification.createdAt),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: _C.textSec,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.body,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: _C.textSec,
                    height: 1.4,
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
