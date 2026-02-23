import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/login_screen.dart';

/// ───────────────────────────────────────────────────────────────
/// LANDING / ONBOARDING PAGE — Sevadaar
/// Three-page onboarding with:
///   • Parallax icon offset on swipe
///   • Orbiting decorative dots & rotating rings
///   • Gentle floating motion on illustrations
///   • Staggered entrance animations
///   • Animated page indicators
///   • Gradient CTA button with glow pulse
/// ───────────────────────────────────────────────────────────────
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  // ── Page data ─────────────────────────────────────────────────
  static const _pages = <_PData>[
    _PData(
      icon: Icons.volunteer_activism,
      title: 'Empower\nCommunities',
      body:
          'Seamlessly create tasks, coordinate volunteers,\nand manage operations — all from one\npowerful platform.',
      accent: Color(0xFF4CAF50),
      grad: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
      shadow: Color.fromRGBO(76, 175, 80, 0.30),
      ring: Color.fromRGBO(76, 175, 80, 0.09),
      dot: Color.fromRGBO(76, 175, 80, 0.28),
    ),
    _PData(
      icon: Icons.forum_rounded,
      title: 'Connect &\nCollaborate',
      body:
          'Stay aligned with built-in messaging.\nEvery task auto-creates a group chat,\nkeeping your team connected.',
      accent: Color(0xFF26A69A),
      grad: [Color(0xFF4DB6AC), Color(0xFF00897B)],
      shadow: Color.fromRGBO(38, 166, 154, 0.30),
      ring: Color.fromRGBO(38, 166, 154, 0.09),
      dot: Color.fromRGBO(38, 166, 154, 0.28),
    ),
    _PData(
      icon: Icons.insights_rounded,
      title: 'Track Real\nImpact',
      body:
          'Watch progress unfold in real-time with\ndynamic tracking. Every contribution\ncounts toward your mission.',
      accent: Color(0xFFFFA726),
      grad: [Color(0xFFFFD54F), Color(0xFFF57F17)],
      shadow: Color.fromRGBO(255, 167, 38, 0.30),
      ring: Color.fromRGBO(255, 167, 38, 0.09),
      dot: Color.fromRGBO(255, 167, 38, 0.28),
    ),
  ];

  // ── State ─────────────────────────────────────────────────────
  final _pageCtrl = PageController();
  int _page = 0;

  // ── Animation controllers ─────────────────────────────────────
  late final AnimationController _enterCtrl;
  late final AnimationController _orbitCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _glowCtrl;

  // ── Entrance intervals ────────────────────────────────────────
  late final Animation<double> _eIllustration;
  late final Animation<double> _eTitle;
  late final Animation<double> _eSubtitle;
  late final Animation<double> _eBottom;

  Animation<double> _iv(double s, double e) =>
      Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _enterCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic)));

  // ── Lifecycle ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
    _orbitCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _eIllustration = _iv(0.0, 0.50);
    _eTitle = _iv(0.15, 0.60);
    _eSubtitle = _iv(0.30, 0.75);
    _eBottom = _iv(0.50, 1.00);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _enterCtrl.dispose();
    _orbitCtrl.dispose();
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1510),
      body: AnimatedBuilder(
        animation: Listenable.merge(
            [_enterCtrl, _orbitCtrl, _floatCtrl, _glowCtrl]),
        builder: (context, _) => Stack(
          children: [
            // Ambient color glow behind illustration
            _ambientGlow(),

            Column(
              children: [
                // ── Skip ──
                SafeArea(
                  bottom: false,
                  child: _fade(
                    _eBottom.value,
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: GestureDetector(
                          onTap: () => _pageCtrl.animateToPage(
                            _pages.length - 1,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF81C784),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Paged content ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, i) => _buildPage(i),
                  ),
                ),

                // ── Bottom bar ──
                _fade(
                  _eBottom.value,
                  Padding(
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 28 + bottom),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [_indicators(), _ctaButton()],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Ambient glow ──────────────────────────────────────────────
  Widget _ambientGlow() {
    final d = _pages[_page];
    return Positioned(
      top: -80,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        height: 420,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [d.ring, Colors.transparent],
            radius: 0.9,
          ),
        ),
      ),
    );
  }

  // ── Single page ───────────────────────────────────────────────
  Widget _buildPage(int i) {
    final d = _pages[i];

    // Parallax offset based on page position
    double px = 0;
    if (_pageCtrl.hasClients && _pageCtrl.position.haveDimensions) {
      px = i - (_pageCtrl.page ?? 0.0);
    }

    final floatY = sin(_floatCtrl.value * pi) * 8;
    final orbit = _orbitCtrl.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Illustration ──
          _fade(
            _eIllustration.value,
            Transform.translate(
              offset: Offset(px * 60, floatY),
              child: SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _decorRing(210, d.ring, orbit * 0.35),
                    _decorRing(170, d.ring, orbit * -0.22),
                    for (var j = 0; j < 8; j++)
                      _orbitDot(j, 8, 110, d.dot, orbit),
                    // Hero icon
                    Container(
                      width: 115,
                      height: 115,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: d.grad,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: d.shadow,
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(d.icon, size: 48, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 52),

          // ── Title ──
          _fade(
            _eTitle.value,
            Transform.translate(
              offset: Offset(px * -22, 0),
              child: Text(
                d.title,
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Description ──
          _fade(
            _eSubtitle.value,
            Transform.translate(
              offset: Offset(px * -10, 0),
              child: Text(
                d.body,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFFB0BEC5),
                  height: 1.7,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Decorative ring ───────────────────────────────────────────
  Widget _decorRing(double size, Color color, double angle) {
    return Transform.rotate(
      angle: angle * 2 * pi,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1),
        ),
      ),
    );
  }

  // ── Orbiting dot ──────────────────────────────────────────────
  Widget _orbitDot(
      int i, int total, double radius, Color color, double orbit) {
    final speed = 1.0 + (i % 3) * 0.22;
    final a = (i / total) * 2 * pi + orbit * 2 * pi * speed;
    final dr = radius + (i.isEven ? 6 : -4);
    final sz = 3.0 + (i % 3) * 1.4;

    return Transform.translate(
      offset: Offset(cos(a) * dr, sin(a) * dr),
      child: Container(
        width: sz,
        height: sz,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  // ── Page indicators ───────────────────────────────────────────
  Widget _indicators() {
    return Row(
      children: List.generate(_pages.length, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 8),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active ? _pages[_page].accent : const Color(0xFF2A3F32),
          ),
        );
      }),
    );
  }

  // ── CTA button ────────────────────────────────────────────────
  Widget _ctaButton() {
    final last = _page == _pages.length - 1;
    final g = _glowCtrl.value;
    final d = _pages[_page];

    return GestureDetector(
      onTap: _next,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding:
            EdgeInsets.symmetric(horizontal: last ? 28 : 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: d.grad,
          ),
          boxShadow: [
            BoxShadow(
              color: d.shadow,
              blurRadius: last ? 20 + 10 * g : 14,
              spreadRadius: last ? 1 + 2 * g : 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                last ? 'Get Started' : 'Next',
                key: ValueKey(last),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: last ? 0.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── Util: fade + slide up ─────────────────────────────────────
  Widget _fade(double t, Widget child) => Transform.translate(
        offset: Offset(0, 20 * (1 - t)),
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      );
}

// ═══════════════════════════════════════════════════════════════════
// Page data model
// ═══════════════════════════════════════════════════════════════════

class _PData {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final List<Color> grad;
  final Color shadow;
  final Color ring;
  final Color dot;

  const _PData({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.grad,
    required this.shadow,
    required this.ring,
    required this.dot,
  });
}
