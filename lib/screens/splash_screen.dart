import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'landing_page.dart';

/// ───────────────────────────────────────────────────────────────
/// SPLASH SCREEN — Sevadaar
/// Premium dark-green themed splash with layered animations:
///   • Expanding ripple rings
///   • Elastic icon entrance + breathing glow
///   • Staggered per-letter reveal with shimmer sweep
///   • Animated divider & tagline
///   • Floating particle field
///   • Smooth scale-fade exit
/// ───────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Constants ──────────────────────────────────────────────────
  static const _title = 'SEVADAAR';

  // ── Controllers ───────────────────────────────────────────────
  late final AnimationController _rippleCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _letterCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _tagCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _exitCtrl;

  // ── Derived Animations ────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoGlow;
  late final List<Animation<double>> _letters;
  late final Animation<double> _tagOpacity;
  late final Animation<double> _tagSlide;
  late final Animation<double> _divider;

  // ── Particles ─────────────────────────────────────────────────
  final List<_Particle> _particles = [];
  final _rng = Random(42);

  // ── Lifecycle ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _seedParticles();
    _buildAnimations();
    _playSplash();
  }

  @override
  void dispose() {
    for (final c in [
      _rippleCtrl,
      _logoCtrl,
      _pulseCtrl,
      _letterCtrl,
      _shimmerCtrl,
      _tagCtrl,
      _particleCtrl,
      _exitCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Setup ─────────────────────────────────────────────────────
  void _seedParticles() {
    for (var i = 0; i < 32; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 2.8 + 0.8,
        speed: _rng.nextDouble() * 0.22 + 0.06,
        opacity: _rng.nextDouble() * 0.28 + 0.04,
      ));
    }
  }

  void _buildAnimations() {
    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _logoScale = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoGlow = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);

    _letterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1050));
    _letters = List.generate(_title.length, (i) {
      final s = i * 0.088;
      return Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _letterCtrl,
        curve: Interval(s, (s + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOutBack),
      ));
    });

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();

    _tagCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _tagOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _tagCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut)));
    _tagSlide = Tween(begin: 14.0, end: 0.0).animate(
        CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOutCubic));
    _divider = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _tagCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  // ── Sequence ──────────────────────────────────────────────────
  Future<void> _playSplash() async {
    await Future.delayed(const Duration(milliseconds: 250));
    _rippleCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 350));
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    _letterCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 450));
    _tagCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    await _exitCtrl.forward();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, a1, a2) => const LandingPage(),
      transitionsBuilder: (_, a, s, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeInOut),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 600),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final iconCenter = Offset(sz.width / 2, sz.height * 0.37);

    return Scaffold(
      backgroundColor: const Color(0xFF06110B),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _rippleCtrl,
          _logoCtrl,
          _pulseCtrl,
          _letterCtrl,
          _shimmerCtrl,
          _tagCtrl,
          _particleCtrl,
          _exitCtrl,
        ]),
        builder: (context, _) {
          final ex = _exitCtrl.value;
          return Opacity(
            opacity: (1.0 - ex).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 1.0 + ex * 0.06,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0E2419),
                      Color(0xFF091A10),
                      Color(0xFF06110B),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Floating particles
                    RepaintBoundary(
                      child: CustomPaint(
                        size: sz,
                        painter:
                            _ParticlePainter(_particles, _particleCtrl.value),
                      ),
                    ),
                    // Ripple rings
                    RepaintBoundary(
                      child: CustomPaint(
                        size: sz,
                        painter:
                            _RipplePainter(iconCenter, _rippleCtrl.value),
                      ),
                    ),
                    // Center content
                    _content(sz),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Content Column ────────────────────────────────────────────
  Widget _content(Size sz) {
    final p = _pulseCtrl.value;
    return Positioned.fill(
      child: Column(
        children: [
          SizedBox(height: sz.height * 0.27),

          // ── Logo circle with glow ──
          Transform.scale(
            scale: _logoScale.value,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF66BB6A),
                    Color(0xFF388E3C),
                    Color(0xFF1B5E20),
                  ],
                  stops: [0.1, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(
                        76, 175, 80, 0.30 * _logoGlow.value + 0.12 * p),
                    blurRadius: 28 + 14 * p,
                    spreadRadius: 6 + 5 * p,
                  ),
                  BoxShadow(
                    color: Color.fromRGBO(
                        129, 199, 132, 0.12 * _logoGlow.value + 0.04 * p),
                    blurRadius: 60 + 18 * p,
                    spreadRadius: 16 + 8 * p,
                  ),
                ],
              ),
              child: const Icon(Icons.volunteer_activism,
                  size: 50, color: Colors.white),
            ),
          ),

          const SizedBox(height: 44),

          // ── Staggered letter reveal ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_title.length, (i) {
              final t = _letters[i].value;
              return Transform.translate(
                offset: Offset(0, 22 * (1 - t)),
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: ShaderMask(
                      shaderCallback: (b) {
                        final s = _shimmerCtrl.value;
                        return LinearGradient(
                          begin: Alignment(-1.5 + 4 * s, 0),
                          end: Alignment(-0.5 + 4 * s, 0),
                          colors: const [
                            Color(0xFFE8F5E9),
                            Color(0xFFFFFFFF),
                            Color(0xFFA5D6A7),
                            Color(0xFFFFFFFF),
                            Color(0xFFE8F5E9),
                          ],
                          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                        ).createShader(b);
                      },
                      child: Text(
                        _title[i],
                        style: GoogleFonts.poppins(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // ── Animated divider ──
          Container(
            width: 50 * _divider.value,
            height: 1.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(76, 175, 80, 0),
                  Color.fromRGBO(76, 175, 80, 0.6 * _tagOpacity.value),
                  Color.fromRGBO(76, 175, 80, 0),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Tagline ──
          Transform.translate(
            offset: Offset(0, _tagSlide.value),
            child: Opacity(
              opacity: _tagOpacity.value,
              child: Text(
                'Serve  •  Connect  •  Impact',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 3,
                  color: const Color(0xFF81C784),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Data & Painters
// ═══════════════════════════════════════════════════════════════════

class _Particle {
  final double x, y, size, speed, opacity;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

/// Draws tiny dots drifting upward to add depth.
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double tick;
  _ParticlePainter(this.particles, this.tick);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final y = ((p.y - tick * p.speed) % 1.0 + 1.0) % 1.0;
      paint.color = Color.fromRGBO(129, 199, 132, p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.tick != tick;
}

/// Draws three concentric expanding rings from [center].
class _RipplePainter extends CustomPainter {
  final Offset center;
  final double progress;
  _RipplePainter(this.center, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final maxR = size.width * 0.7;
    for (var i = 0; i < 3; i++) {
      final d = i * 0.18;
      final t = ((progress - d) / (1.0 - d)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      canvas.drawCircle(
        center,
        maxR * Curves.easeOutCubic.transform(t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Color.fromRGBO(76, 175, 80, (1 - t) * 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) =>
      old.progress != progress;
}
