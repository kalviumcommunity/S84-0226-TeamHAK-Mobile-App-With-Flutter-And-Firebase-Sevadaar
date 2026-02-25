import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  const AuthHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      child: CustomPaint(
        painter: _HeaderPainter(),
        child: SafeArea(
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 42,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gradient background
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6A74F8), Color(0xFF9298F0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.lineTo(0, size.height * 0.75);
    
    // Wavy curve matching the image
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.65, 
      size.width * 0.5, size.height * 0.8
    );
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 1.0, 
      size.width, size.height * 0.75
    );
    
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Draw illustrations (lamps, clock, plant)
    final illustrationPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Lamp 1 (Left)
    canvas.drawRect(Rect.fromLTWH(size.width * 0.18, 0, 3, size.height * 0.25), illustrationPaint);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width * 0.18 + 1.5, size.height * 0.25), width: 80, height: 60),
      3.14, 3.14, true, illustrationPaint
    );

    // Lamp 2 (Center-ish)
    canvas.drawRect(Rect.fromLTWH(size.width * 0.48, 0, 3, size.height * 0.15), illustrationPaint);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width * 0.48 + 1.5, size.height * 0.15), width: 60, height: 40),
      3.14, 3.14, true, illustrationPaint
    );

    // Clock (Right)
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.15), 30, illustrationPaint);
    // Clock hands
    final handsPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.78, size.height * 0.15), Offset(size.width * 0.78, size.height * 0.15 - 15), handsPaint);
    canvas.drawLine(Offset(size.width * 0.78, size.height * 0.15), Offset(size.width * 0.78 + 10, size.height * 0.15 + 10), handsPaint);

    // Plant (Bottom Right)
    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width * 0.68, size.height * 0.82), width: 90, height: 70),
      0, 3.14, true, illustrationPaint
    );
    
    // Leaves
    final leafPath = Path();
    leafPath.moveTo(size.width * 0.68, size.height * 0.82);
    leafPath.quadraticBezierTo(size.width * 0.55, size.height * 0.6, size.width * 0.7, size.height * 0.5);
    leafPath.quadraticBezierTo(size.width * 0.75, size.height * 0.65, size.width * 0.68, size.height * 0.82);
    canvas.drawPath(leafPath, illustrationPaint);
    
    final leafPath2 = Path();
    leafPath2.moveTo(size.width * 0.68, size.height * 0.82);
    leafPath2.quadraticBezierTo(size.width * 0.8, size.height * 0.6, size.width * 0.9, size.height * 0.55);
    leafPath2.quadraticBezierTo(size.width * 0.95, size.height * 0.7, size.width * 0.68, size.height * 0.82);
    canvas.drawPath(leafPath2, illustrationPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
