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

class NotificationsTab extends StatelessWidget {
  final UserModel currentUser;

  const NotificationsTab({super.key, required this.currentUser});

  Stream<List<NotificationModel>> _streamNotifications() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientUid', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => NotificationModel.fromMap(d.data(), d.id))
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

                  final notifications = snapshot.data ?? [];
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded, 
                            size: 64, 
                            color: _C.textSec.withValues(alpha: 0.5)
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

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final notif = notifications[i];
                      return _NotificationCard(notification: notif);
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
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
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
                      DateFormat('MMM d, h:mm a').format(notification.createdAt),
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
