import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

/// Placeholder Admin Dashboard — will be expanded later.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1565C0), Color(0xFF0D47A1)],
                      stops: [0.1, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.25),
                        blurRadius: 22,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.dashboard_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'Admin Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coming soon — manage tasks & volunteers here.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF90CAF9),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 40),
                _signOutButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _signOutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await AuthService().signOut();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF5D1F1F)),
          color: const Color(0xFF3D1212).withValues(alpha: 0.5),
        ),
        child: Text(
          'Sign Out',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFEF9A9A),
          ),
        ),
      ),
    );
  }
}
