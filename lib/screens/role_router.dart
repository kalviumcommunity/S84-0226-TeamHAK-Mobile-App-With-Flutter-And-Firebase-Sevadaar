import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/notification_wrapper.dart';
import 'auth/login_screen.dart';
import 'super_admin/super_admin_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'volunteer/volunteer_dashboard.dart';
import 'volunteer/no_ngo_dashboard.dart';
import 'developer_admin/developer_admin_dashboard.dart';
import 'landing_page.dart';

/// ───────────────────────────────────────────────────────────────
/// ROLE ROUTER — Sevadaar
/// Reads the current user's Firestore role and routes to the
/// correct dashboard. Shows a themed loading screen while fetching.
/// ───────────────────────────────────────────────────────────────
class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  final _authService = AuthService();

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFF06110B),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF4CAF50),
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading your dashboard...',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF81C784),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeToDashboard(UserModel profile) {
    final uid = profile.uid;
    switch (profile.role) {
      case 'developer_admin':
        return NotificationWrapper(
          uid: uid,
          child: const DeveloperAdminDashboard(),
        );
      case 'super_admin':
        return NotificationWrapper(
          uid: uid,
          child: const SuperAdminDashboard(),
        );
      case 'admin':
        return NotificationWrapper(
          uid: uid,
          child: const AdminDashboard(),
        );
      case 'volunteer':
      default:
        // If volunteer has no NGO assigned, show the no-NGO dashboard
        if (profile.ngoId == null || profile.ngoId!.isEmpty) {
          return NotificationWrapper(
            uid: uid,
            child: NoNgoDashboard(currentUser: profile),
          );
        } else {
          return NotificationWrapper(
            uid: uid,
            child: const VolunteerDashboard(),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        return StreamBuilder<UserModel?>(
          stream: _authService.streamUserProfile(firebaseUser.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }

            if (!profileSnapshot.hasData || profileSnapshot.data == null) {
              // Handle case where profile is being created or deleted
              // Check if we are on a platform that doesn't support Firebase
              if (defaultTargetPlatform == TargetPlatform.linux ||
                  defaultTargetPlatform == TargetPlatform.windows) {
                return const LandingPage();
              }
              return const LoginScreen();
            }

            return _routeToDashboard(profileSnapshot.data!);
          },
        );
      },
    );
  }
}
