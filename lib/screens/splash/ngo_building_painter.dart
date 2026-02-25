import 'dart:math';
import 'package:flutter/material.dart';

/// CustomPainter that progressively draws a realistic, fully-coloured
/// two-storey NGO community-centre building.
///
/// Colour palette:
///   Ground/earth    – warm brown-grey
///   Foundation/slab – concrete grey
///   Walls           – warm cream / beige
///   Roof/parapet    – dark slate-grey
///   Columns         – off-white / marble
///   Windows (glass) – light sky-blue
///   Window frames   – dark grey
///   Door            – rich walnut brown
///   Steps           – sandstone tan
///   Flag            – saffron-orange
///   Sign board      – white with dark border
///
/// Drawing phases mapped to [progress]:
///   0.00 – 0.30  Ground line + foundation slab
///   0.30 – 0.60  Walls, floor line, roof, columns, pediment
///   0.60 – 0.75  Windows, door, steps, sign, flag, brick texture
///   0.75 – 1.00  (handled externally – volunteers / text)
class NgoBuildingPainter extends CustomPainter {
  final double progress;
  final Color strokeColor;
  final double walkProgress;
  final double connectionProgress;

  NgoBuildingPainter({
    required this.progress,
    this.strokeColor = const Color(0xFF2196F3),
    this.walkProgress = 0.0,
    this.connectionProgress = 0.0,
  });

  // ── Colour palette ────────────────────────────────────────
  static const Color _ground       = Color(0xFF8D7B68); // earthy brown
  static const Color _concrete     = Color(0xFF9E9E9E); // grey concrete
  static const Color _wallFill     = Color(0xFFF5ECD7); // warm cream
  static const Color _wallEdge     = Color(0xFFBDB19A); // darker cream edge
  static const Color _roofFill     = Color(0xFF546E7A); // dark slate
  static const Color _roofEdge     = Color(0xFF37474F); // deep blue-grey
  static const Color _columnFill   = Color(0xFFF0EBE0); // off-white marble
  static const Color _columnEdge   = Color(0xFFB0A898); // stone edge
  static const Color _glassFill    = Color(0xFFBBDEFB); // light blue glass
  static const Color _glassEdge    = Color(0xFF455A64); // dark grey frame
  static const Color _doorFill     = Color(0xFF6D4C31); // walnut brown
  static const Color _doorEdge     = Color(0xFF4E342E); // deep brown
  static const Color _doorHandle   = Color(0xFFD4AF37); // brass gold
  static const Color _stepFill     = Color(0xFFD7C9A8); // sandstone
  static const Color _stepEdge     = Color(0xFFA89B7E); // sandstone edge
  static const Color _flagPole     = Color(0xFF78909C); // steel grey
  static const Color _flagFill     = Color(0xFFFF9800); // saffron orange
  static const Color _signFill     = Color(0xFFFFFFFF); // white
  static const Color _signEdge     = Color(0xFF546E7A); // slate
  static const Color _brickLine    = Color(0xFFCDBAA0); // subtle brick hint
  static const Color _corniceColor = Color(0xFFB0A898); // moulding tone
  static const Color _pedimentFill = Color(0xFFECE4D4); // light cream
  static const Color _grassGreen   = Color(0xFF7CB342); // grass
  static const Color _bushGreen    = Color(0xFF33691E); // deep bush
  static const Color _bushLeaf     = Color(0xFF689F38); // light leaf
  static const Color _pathStone    = Color(0xFFBCAAA4); // stone path
  static const Color _lampWarm     = Color(0xFFFFB74D); // warm lamp
  static const Color _warmGlow     = Color(0xFFFFF3E0); // window glow
  static const Color _shadow       = Color(0x1A000000); // building shadow

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double groundY = size.height * 0.80;

    // ── Main building envelope ──────────────────────────────
    final double bW = size.width * 0.58;
    final double bH = size.height * 0.46;
    final double bLeft = cx - bW / 2;
    final double bRight = cx + bW / 2;
    final double bTop = groundY - bH;

    final double floorDivY = bTop + bH * 0.48;
    final double roofThick = bH * 0.045;
    final double roofOverhang = bW * 0.04;

    final double porticoW = bW * 0.36;
    final double porticoH = bH * 0.30;
    final double porticoLeft = cx - porticoW / 2;
    final double porticoRight = cx + porticoW / 2;
    final double porticoTop = floorDivY - porticoH * 0.10;

    final double stepsW = porticoW * 0.80;
    final double stepH = bH * 0.04;
    final double foundH = bH * 0.055;

    // ════════════════════════════════════════════════════════
    // PHASE 1  –  Foundation  (0.0 → 0.3)
    // ════════════════════════════════════════════════════════
    final double p1 = _interval(progress, 0.0, 0.3);

    if (p1 > 0) {
      // Ground surface draws left → right
      final double glLeft = bLeft - 30;
      final double glRight = bRight + 30;
      final double glCur = glLeft + (glRight - glLeft) * min(p1 / 0.5, 1.0);

      // Ground fill (a thin strip of earth)
      final double groundStrip = 5.0;
      canvas.drawRect(
        Rect.fromLTRB(glLeft, groundY, glCur, groundY + groundStrip),
        Paint()..color = _ground.withValues(alpha: min(p1 / 0.5, 1.0) * 0.45)..style = PaintingStyle.fill,
      );
      canvas.drawLine(
        Offset(glLeft, groundY),
        Offset(glCur, groundY),
        Paint()..color = _ground.withValues(alpha: min(p1 / 0.5, 1.0))..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round,
      );

      // Grass patches flanking the building
      final double gOp = min(p1 / 0.5, 1.0);
      if (gOp > 0) {
        canvas.drawRect(
          Rect.fromLTRB(glLeft, groundY + 0.5, bLeft - 8, groundY + 5),
          Paint()..color = _grassGreen.withValues(alpha: gOp * 0.40),
        );
        canvas.drawRect(
          Rect.fromLTRB(bRight + 8, groundY + 0.5, glRight, groundY + 5),
          Paint()..color = _grassGreen.withValues(alpha: gOp * 0.40),
        );
        for (final gx in [glLeft + 15.0, glLeft + 35.0, glRight - 15.0, glRight - 35.0]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(gx, groundY - 1.5), width: 10, height: 5),
            Paint()..color = _grassGreen.withValues(alpha: gOp * 0.30),
          );
        }
      }

      // Foundation slab rises
      final double slabT = _interval(p1, 0.45, 1.0);
      if (slabT > 0) {
        final double curTop = groundY - foundH * slabT;
        final r = Rect.fromLTRB(bLeft - 6, curTop, bRight + 6, groundY);
        canvas.drawRect(r, Paint()..color = _concrete.withValues(alpha: 0.50 * slabT)..style = PaintingStyle.fill);
        canvas.drawRect(r, Paint()..color = _concrete.withValues(alpha: 0.85 * slabT)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }

    // ════════════════════════════════════════════════════════
    // PHASE 2  –  Structure  (0.3 → 0.6)
    // ════════════════════════════════════════════════════════
    final double p2 = _interval(progress, 0.3, 0.6);

    if (p2 > 0) {
      // 2a – Walls rise (0 → 0.40)
      final double wallT = min(p2 / 0.40, 1.0);
      final double curTop = groundY - foundH - (bH - foundH) * wallT;

      // Drop shadow (grows with walls)
      if (wallT > 0.15) {
        canvas.drawRect(
          Rect.fromLTRB(bLeft + 5, curTop + 5, bRight + 5, groundY + 2),
          Paint()..color = _shadow..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      // Wall fill – cream
      if (wallT > 0.05) {
        canvas.drawRect(
          Rect.fromLTRB(bLeft, curTop, bRight, groundY - foundH),
          Paint()..color = _wallFill.withValues(alpha: wallT)..style = PaintingStyle.fill,
        );
        // Subtle gradient overlay for depth
        if (wallT > 0.4) {
          final wallRect = Rect.fromLTRB(bLeft, curTop, bRight, groundY - foundH);
          final gradient = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: wallT * 0.10),
              Colors.transparent,
              _ground.withValues(alpha: wallT * 0.05),
            ],
            stops: const [0.0, 0.6, 1.0],
          );
          canvas.drawRect(wallRect, Paint()..shader = gradient.createShader(wallRect));
        }
      }

      // Wall edges
      canvas.drawLine(Offset(bLeft, groundY - foundH), Offset(bLeft, curTop),
          Paint()..color = _wallEdge.withValues(alpha: wallT)..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);
      canvas.drawLine(Offset(bRight, groundY - foundH), Offset(bRight, curTop),
          Paint()..color = _wallEdge.withValues(alpha: wallT)..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);

      // 2b – Floor divider (0.40 → 0.55)
      final double floorT = _interval(p2, 0.40, 0.55);
      if (floorT > 0 && wallT >= 1.0) {
        // Floor slab band
        final double bandH = 5.0;
        canvas.drawRect(
          Rect.fromLTRB(bLeft, floorDivY - bandH / 2, bLeft + bW * floorT, floorDivY + bandH / 2),
          Paint()..color = _concrete.withValues(alpha: 0.35 * floorT)..style = PaintingStyle.fill,
        );
        // Cornice / moulding line
        canvas.drawLine(
          Offset(bLeft, floorDivY - 3),
          Offset(bLeft + bW * floorT, floorDivY - 3),
          Paint()..color = _corniceColor.withValues(alpha: 0.7 * floorT)..style = PaintingStyle.stroke..strokeWidth = 1.8,
        );
        canvas.drawLine(
          Offset(bLeft, floorDivY),
          Offset(bLeft + bW * floorT, floorDivY),
          Paint()..color = _corniceColor.withValues(alpha: 0.9 * floorT)..style = PaintingStyle.stroke..strokeWidth = 1.5,
        );
      }

      // 2c – Roof slab (0.55 → 0.70)
      final double roofT = _interval(p2, 0.55, 0.70);
      if (roofT > 0 && wallT >= 1.0) {
        // Top wall line
        canvas.drawLine(
          Offset(bLeft, bTop),
          Offset(bLeft + bW * roofT, bTop),
          Paint()..color = _wallEdge..style = PaintingStyle.stroke..strokeWidth = 2.0,
        );

        // Roof slab
        if (roofT > 0.5) {
          final double rslabT = _interval(roofT, 0.5, 1.0);
          final roofRect = Rect.fromLTRB(
            bLeft - roofOverhang,
            bTop - roofThick,
            bLeft - roofOverhang + (bW + roofOverhang * 2) * rslabT,
            bTop,
          );
          canvas.drawRect(roofRect, Paint()..color = _roofFill.withValues(alpha: rslabT)..style = PaintingStyle.fill);
          canvas.drawRect(roofRect, Paint()..color = _roofEdge.withValues(alpha: rslabT)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        }

        // Parapet
        if (roofT >= 1.0) {
          final double paraH = roofThick * 1.6;
          final paraRect = Rect.fromLTRB(
            bLeft - roofOverhang, bTop - roofThick - paraH,
            bRight + roofOverhang, bTop - roofThick,
          );
          canvas.drawRect(paraRect, Paint()..color = _roofFill.withValues(alpha: 0.6)..style = PaintingStyle.fill);
          canvas.drawRect(paraRect, Paint()..color = _roofEdge.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 1.2);
        }
      }

      // 2d – Portico columns (0.70 → 0.85)
      final double colT = _interval(p2, 0.70, 0.85);
      if (colT > 0 && wallT >= 1.0) {
        final double colTopY = porticoTop;
        final double colBotY = groundY - foundH;
        final double colCurTop = colBotY - (colBotY - colTopY) * colT;
        final double colW = porticoW * 0.060;

        _drawColumn(canvas, porticoLeft + colW / 2, colCurTop, colBotY, colW, colT);
        _drawColumn(canvas, porticoRight - colW / 2, colCurTop, colBotY, colW, colT);
      }

      // 2e – Portico canopy / pediment (0.85 → 1.0)
      final double canopyT = _interval(p2, 0.85, 1.0);
      if (canopyT > 0 && wallT >= 1.0) {
        final double canopyY = porticoTop;
        final double peakY = canopyY - porticoH * 0.28;

        // Horizontal beam
        final double beamRight = porticoLeft - 4 + (porticoW + 8) * canopyT;
        canvas.drawRect(
          Rect.fromLTRB(porticoLeft - 4, canopyY - 3, beamRight, canopyY + 1),
          Paint()..color = _roofFill.withValues(alpha: canopyT)..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          Rect.fromLTRB(porticoLeft - 4, canopyY - 3, beamRight, canopyY + 1),
          Paint()..color = _roofEdge.withValues(alpha: canopyT)..style = PaintingStyle.stroke..strokeWidth = 1.0,
        );

        // Triangular pediment
        if (canopyT > 0.4) {
          final double pedT = _interval(canopyT, 0.4, 1.0);
          final pedPath = Path()
            ..moveTo(porticoLeft - 4, canopyY - 3)
            ..lineTo(cx, peakY + (canopyY - 3 - peakY) * (1 - pedT))
            ..lineTo(porticoRight + 4, canopyY - 3)
            ..close();
          canvas.drawPath(pedPath, Paint()..color = _pedimentFill.withValues(alpha: pedT)..style = PaintingStyle.fill);
          canvas.drawPath(pedPath, Paint()..color = _roofEdge.withValues(alpha: pedT * 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        }
      }
    }

    // ════════════════════════════════════════════════════════
    // PHASE 3  –  Details  (0.6 → 0.75)
    // ════════════════════════════════════════════════════════
    final double p3 = _interval(progress, 0.6, 0.75);

    if (p3 > 0) {
      final double o = Curves.easeIn.transform(p3); // opacity multiplier

      // ── Upper-floor windows (4) ───────────────────────────
      final double winW = bW * 0.10;
      final double winH = bH * 0.14;
      final double upperWinY = bTop + (floorDivY - bTop) * 0.50;
      for (final wx in [bLeft + bW * 0.14, bLeft + bW * 0.34, bLeft + bW * 0.66, bLeft + bW * 0.86]) {
        _drawWindow(canvas, wx, upperWinY, winW, winH, o);
      }

      // ── Ground-floor windows (2 pairs) ────────────────────
      final double gfWinW = bW * 0.11;
      final double gfWinH = bH * 0.16;
      final double gfWinY = floorDivY + (groundY - foundH - floorDivY) * 0.42;
      for (final wx in [bLeft + bW * 0.14, bLeft + bW * 0.28, bLeft + bW * 0.72, bLeft + bW * 0.86]) {
        _drawWindow(canvas, wx, gfWinY, gfWinW, gfWinH, o);
      }

      // ── Entrance door (arched double-door) ────────────────
      final double doorW = porticoW * 0.42;
      final double doorH = (groundY - foundH - floorDivY) * 0.78;
      final double doorTopY = groundY - foundH - doorH;
      final double doorL = cx - doorW / 2;
      final double doorR = cx + doorW / 2;

      final doorPath = Path()
        ..moveTo(doorL, groundY - foundH)
        ..lineTo(doorL, doorTopY + doorW * 0.3)
        ..arcToPoint(Offset(doorR, doorTopY + doorW * 0.3),
            radius: Radius.circular(doorW * 0.5), clockwise: true)
        ..lineTo(doorR, groundY - foundH)
        ..close();

      canvas.drawPath(doorPath, Paint()..color = _doorFill.withValues(alpha: o)..style = PaintingStyle.fill);
      canvas.drawPath(doorPath, Paint()..color = _doorEdge.withValues(alpha: o)..style = PaintingStyle.stroke..strokeWidth = 2.0);

      // Centre split
      canvas.drawLine(
        Offset(cx, doorTopY + doorW * 0.15), Offset(cx, groundY - foundH),
        Paint()..color = _doorEdge.withValues(alpha: o * 0.7)..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );

      // Brass handles
      for (final dx in [-doorW * 0.12, doorW * 0.12]) {
        canvas.drawCircle(
          Offset(cx + dx, groundY - foundH - doorH * 0.38), 2.5,
          Paint()..color = _doorHandle.withValues(alpha: o),
        );
      }

      // ── Steps ─────────────────────────────────────────────
      final stO = _interval(p3, 0.4, 0.8);
      if (stO > 0) {
        for (int s = 0; s < 3; s++) {
          final double sPad = s * stepsW * 0.06;
          final double sTop = groundY + s * stepH;
          final stepRect = Rect.fromLTRB(
            cx - stepsW / 2 - sPad, sTop,
            cx + stepsW / 2 + sPad, sTop + stepH,
          );
          canvas.drawRect(stepRect, Paint()..color = _stepFill.withValues(alpha: stO)..style = PaintingStyle.fill);
          canvas.drawRect(stepRect, Paint()..color = _stepEdge.withValues(alpha: stO * 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.2);
        }
      }

      // ── Sign board in pediment ────────────────────────────
      final sO = _interval(p3, 0.5, 0.85);
      if (sO > 0) {
        final double signH = (floorDivY - bTop) * 0.12;
        final double signTop = porticoTop - porticoH * 0.28 - signH * 2.2;
        final signRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, signTop + signH / 2), width: porticoW * 0.40, height: signH),
          const Radius.circular(2),
        );
        canvas.drawRRect(signRect, Paint()..color = _signFill.withValues(alpha: sO)..style = PaintingStyle.fill);
        canvas.drawRRect(signRect, Paint()..color = _signEdge.withValues(alpha: sO * 0.7)..style = PaintingStyle.stroke..strokeWidth = 1.2);
        // Sign text
        final tp = TextPainter(
          text: TextSpan(
            text: 'SEVADAAR',
            style: TextStyle(
              color: _signEdge.withValues(alpha: sO),
              fontSize: signH * 0.52,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, signTop + (signH - tp.height) / 2));
      }

      // ── Flag pole + flag ──────────────────────────────────
      final fO = _interval(p3, 0.6, 1.0);
      if (fO > 0) {
        final double poleX = cx;
        final double poleBot = bTop - roofThick - roofThick * 1.6;
        final double poleTop = poleBot - bH * 0.18;
        final double curPoleTop = poleBot - (poleBot - poleTop) * fO;

        // Pole
        canvas.drawLine(
          Offset(poleX, poleBot), Offset(poleX, curPoleTop),
          Paint()..color = _flagPole.withValues(alpha: fO)..style = PaintingStyle.stroke..strokeWidth = 2.2,
        );

        // Flag
        if (fO > 0.5) {
          final double fT = _interval(fO, 0.5, 1.0);
          final double flagW = bW * 0.08 * fT;
          final double flagH = bH * 0.055;
          final flagRect = Rect.fromLTWH(poleX, curPoleTop, flagW, flagH);
          canvas.drawRect(flagRect, Paint()..color = _flagFill.withValues(alpha: fT)..style = PaintingStyle.fill);
          canvas.drawRect(flagRect, Paint()..color = _flagFill.withValues(alpha: fT * 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.0);
        }

        // Ball finial
        canvas.drawCircle(Offset(poleX, curPoleTop), 2.8,
          Paint()..color = _doorHandle.withValues(alpha: fO), // brass-like
        );
      }

      // ── Brick texture hints ───────────────────────────────
      final brO = _interval(p3, 0.3, 0.7);
      if (brO > 0) {
        final brickPaint = Paint()
          ..color = _brickLine.withValues(alpha: brO * 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6;

        final int rows = 8;
        final double wallTopY = bTop;
        final double wallBot = groundY - foundH;
        final double rowH = (wallBot - wallTopY) / rows;

        for (int r = 1; r < rows; r++) {
          final double y = wallTopY + r * rowH;
          if ((y - floorDivY).abs() < rowH * 0.6) continue;
          canvas.drawLine(Offset(bLeft + 2, y), Offset(porticoLeft - 4, y), brickPaint);
          canvas.drawLine(Offset(porticoRight + 4, y), Offset(bRight - 2, y), brickPaint);
        }
      }

      // ── Pathway from steps to foreground ──────────────────
      final pthO = _interval(p3, 0.45, 0.85);
      if (pthO > 0) {
        final double pathTopY = groundY + 3 * stepH;
        final double pathBotY = size.height;
        final double pathW = stepsW * 0.35;
        final double curPathBot = pathTopY + (pathBotY - pathTopY) * pthO;
        final double topHalfW = pathW * 0.5;
        final double botHalfW = pathW * 0.7;
        final pathPath = Path()
          ..moveTo(cx - topHalfW, pathTopY)
          ..lineTo(cx - botHalfW, curPathBot)
          ..lineTo(cx + botHalfW, curPathBot)
          ..lineTo(cx + topHalfW, pathTopY)
          ..close();
        canvas.drawPath(pathPath, Paint()..color = _pathStone.withValues(alpha: pthO * 0.45)..style = PaintingStyle.fill);
        canvas.drawPath(pathPath, Paint()..color = _pathStone.withValues(alpha: pthO * 0.25)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }

      // ── Bushes / shrubs flanking the entrance ───────────
      final bushO = _interval(p3, 0.55, 0.90);
      if (bushO > 0) {
        for (final side in [-1.0, 1.0]) {
          final double bx = cx + side * stepsW * 0.65;
          final double by = groundY + stepH;
          canvas.drawOval(
            Rect.fromCenter(center: Offset(bx, by - 6), width: 22, height: 14),
            Paint()..color = _bushGreen.withValues(alpha: bushO * 0.75),
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(bx - 3, by - 9), width: 12, height: 9),
            Paint()..color = _bushLeaf.withValues(alpha: bushO * 0.6),
          );
          canvas.drawOval(
            Rect.fromCenter(center: Offset(bx + 5, by - 7), width: 10, height: 8),
            Paint()..color = _bushLeaf.withValues(alpha: bushO * 0.5),
          );
        }
      }

      // ── Entrance lamp fixtures ────────────────────────
      final lampO = _interval(p3, 0.70, 1.0);
      if (lampO > 0) {
        for (final side in [-1.0, 1.0]) {
          final double lx = cx + side * porticoW * 0.42;
          final double ly = floorDivY + (groundY - foundH - floorDivY) * 0.15;
          canvas.drawLine(
            Offset(lx, ly), Offset(lx + side * 5, ly - 4),
            Paint()..color = _flagPole.withValues(alpha: lampO)..strokeWidth = 1.5..strokeCap = StrokeCap.round,
          );
          canvas.drawCircle(
            Offset(lx + side * 5, ly - 6), 4.5,
            Paint()..color = _lampWarm.withValues(alpha: lampO * 0.40),
          );
          canvas.drawCircle(
            Offset(lx + side * 5, ly - 6), 2.5,
            Paint()..color = _lampWarm.withValues(alpha: lampO * 0.80),
          );
        }
      }
    }
  }

  // ── Helper: column with capital & base (marble) ───────────
  void _drawColumn(Canvas canvas, double cx, double top, double bottom,
      double width, double opacity) {
    final shaft = Rect.fromLTRB(cx - width / 2, top, cx + width / 2, bottom);
    canvas.drawRect(shaft, Paint()..color = _columnFill.withValues(alpha: opacity)..style = PaintingStyle.fill);
    canvas.drawRect(shaft, Paint()..color = _columnEdge.withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    if (opacity > 0.5) {
      // Capital
      final double capH = width * 0.6, capW = width * 1.5;
      final capRect = Rect.fromCenter(center: Offset(cx, top + capH / 2), width: capW, height: capH);
      canvas.drawRect(capRect, Paint()..color = _columnFill.withValues(alpha: opacity)..style = PaintingStyle.fill);
      canvas.drawRect(capRect, Paint()..color = _columnEdge.withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.2);

      // Base
      final double baseH = width * 0.5, baseW = width * 1.4;
      final baseRect = Rect.fromCenter(center: Offset(cx, bottom - baseH / 2), width: baseW, height: baseH);
      canvas.drawRect(baseRect, Paint()..color = _columnFill.withValues(alpha: opacity)..style = PaintingStyle.fill);
      canvas.drawRect(baseRect, Paint()..color = _columnEdge.withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }
  }

  // ── Helper: realistic window ──────────────────────────────
  void _drawWindow(Canvas canvas, double cx, double cy, double w, double h, double opacity) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);

    // Glass
    canvas.drawRect(rect, Paint()..color = _glassFill.withValues(alpha: opacity * 0.80)..style = PaintingStyle.fill);

    // Warm interior glow
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 0.65, height: h * 0.65),
      Paint()..color = _warmGlow.withValues(alpha: opacity * 0.30),
    );

    // Subtle reflection highlight (diagonal)
    final reflectionPath = Path()
      ..moveTo(cx - w * 0.3, cy - h / 2)
      ..lineTo(cx - w * 0.1, cy - h / 2)
      ..lineTo(cx - w * 0.4, cy + h * 0.1)
      ..lineTo(cx - w * 0.3, cy - h / 2 + 1)
      ..close();
    canvas.drawPath(reflectionPath, Paint()..color = Colors.white.withValues(alpha: opacity * 0.35)..style = PaintingStyle.fill);

    // Frame
    canvas.drawRect(rect, Paint()..color = _glassEdge.withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // Cross-bars
    final barPaint = Paint()..color = _glassEdge.withValues(alpha: opacity * 0.55)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    canvas.drawLine(Offset(cx, cy - h / 2), Offset(cx, cy + h / 2), barPaint);
    canvas.drawLine(Offset(cx - w / 2, cy), Offset(cx + w / 2, cy), barPaint);

    // Sill
    canvas.drawRect(
      Rect.fromLTRB(cx - w / 2 - 2, cy + h / 2, cx + w / 2 + 2, cy + h / 2 + 3),
      Paint()..color = _concrete.withValues(alpha: opacity * 0.6)..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      Rect.fromLTRB(cx - w / 2 - 2, cy + h / 2, cx + w / 2 + 2, cy + h / 2 + 3),
      Paint()..color = _glassEdge.withValues(alpha: opacity * 0.4)..style = PaintingStyle.stroke..strokeWidth = 0.8,
    );
  }

  double _interval(double t, double begin, double end) {
    return ((t - begin) / (end - begin)).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant NgoBuildingPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════
// VolunteerPainter – draws actual human figures walking in from the
// sides, plus connection lines from each person to the building door.
// ═══════════════════════════════════════════════════════════════════

/// Data for a single painted volunteer figure.
class _VolunteerSpec {
  /// X position the volunteer walks TO (fraction of canvas width).
  final double targetXFrac;

  /// Y baseline (fraction of canvas height, at their feet).
  final double baseYFrac;

  /// Whether they enter from the left (true) or right (false).
  final bool fromLeft;

  /// Stagger delay (0–1 inside the walk window).
  final double delay;

  /// Clothing colour (shirt / top).
  final Color shirtColor;

  /// Trousers colour.
  final Color trouserColor;

  /// Skin tone.
  final Color skinColor;

  /// Hair colour.
  final Color hairColor;

  /// Overall figure scale multiplier.
  final double scale;

  const _VolunteerSpec({
    required this.targetXFrac,
    required this.baseYFrac,
    required this.fromLeft,
    required this.delay,
    required this.shirtColor,
    required this.trouserColor,
    required this.skinColor,
    required this.hairColor,
    this.scale = 1.0,
  });
}

class VolunteerPainter extends CustomPainter {
  /// 0→1 : how far the walk-in has progressed.
  final double walkProgress;

  /// 0→1 : how far the connection-line draw has progressed.
  final double connectionProgress;

  /// Raw controller value – keeps shouldRepaint returning true so
  /// volunteers stay visible through the entire animation + hold.
  final double controllerValue;

  VolunteerPainter({
    required this.walkProgress,
    required this.connectionProgress,
    required this.controllerValue,
  });

  // ── Volunteer roster ──────────────────────────────────────
  static const List<_VolunteerSpec> _volunteers = [
    // Person 1 – far left
    _VolunteerSpec(
      targetXFrac: 0.16,
      baseYFrac: 0.87,
      fromLeft: true,
      delay: 0.0,
      shirtColor: Color(0xFF1565C0), // blue
      trouserColor: Color(0xFF37474F),
      skinColor: Color(0xFFD7A87E),
      hairColor: Color(0xFF3E2723),
      scale: 1.05,
    ),
    // Person 2 – right-side
    _VolunteerSpec(
      targetXFrac: 0.82,
      baseYFrac: 0.88,
      fromLeft: false,
      delay: 0.05,
      shirtColor: Color(0xFF00897B), // teal
      trouserColor: Color(0xFF4E342E),
      skinColor: Color(0xFFC9956B),
      hairColor: Color(0xFF212121),
      scale: 1.0,
    ),
    // Person 3 – centre-left
    _VolunteerSpec(
      targetXFrac: 0.34,
      baseYFrac: 0.92,
      fromLeft: true,
      delay: 0.10,
      shirtColor: Color(0xFF7B1FA2), // purple
      trouserColor: Color(0xFF455A64),
      skinColor: Color(0xFFE0B690),
      hairColor: Color(0xFF5D4037),
      scale: 1.10,
    ),
    // Person 4 – centre-right
    _VolunteerSpec(
      targetXFrac: 0.64,
      baseYFrac: 0.91,
      fromLeft: false,
      delay: 0.15,
      shirtColor: Color(0xFFEF6C00), // orange
      trouserColor: Color(0xFF3E2723),
      skinColor: Color(0xFFDAAE80),
      hairColor: Color(0xFF1B1B1B),
      scale: 1.08,
    ),
    // Person 5 – far right (slightly smaller, further back)
    _VolunteerSpec(
      targetXFrac: 0.90,
      baseYFrac: 0.85,
      fromLeft: false,
      delay: 0.20,
      shirtColor: Color(0xFFC62828), // red
      trouserColor: Color(0xFF424242),
      skinColor: Color(0xFFCFA67A),
      hairColor: Color(0xFF4E342E),
      scale: 0.92,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final v in _volunteers) {
      // Per-person walk progress with stagger
      final double rawT =
          ((walkProgress - v.delay) / (1.0 - v.delay)).clamp(0.0, 1.0);
      final double t = Curves.easeOutCubic.transform(rawT);

      if (t <= 0) continue;

      // Position
      final double targetX = size.width * v.targetXFrac;
      final double startX =
          v.fromLeft ? -size.width * 0.15 : size.width * 1.15;
      final double currentX = startX + (targetX - startX) * t;
      final double baseY = size.height * v.baseYFrac;

      // Figure proportions (scaled)
      final double figH = size.height * 0.095 * v.scale;
      final double headR = figH * 0.155;
      final double torsoH = figH * 0.34;
      final double torsoW = figH * 0.24;
      final double legH = figH * 0.34;
      final double armLen = figH * 0.28;
      final double limbW = figH * 0.075;

      final double neckY = baseY - legH - torsoH - headR * 2;
      final double shoulderY = neckY + headR * 0.3;

      // Opacity fades in during first 20 % of personal walk
      final double opacity = (t / 0.20).clamp(0.0, 1.0);

      // ── walking sway (subtle) ────────────────────────────
      final double swing = sin(walkProgress * 12 + v.delay * 30) * 2.5 * (1 - t);

      canvas.save();
      canvas.translate(swing, 0);

      // ── Legs ─────────────────────────────────────────────
      final legYTop = baseY - legH;
      // leg stride offset
      final double stride =
          sin(walkProgress * 14 + v.delay * 20) * figH * 0.07 * (1 - t);
      _fillRect(canvas, currentX - torsoW * 0.35, legYTop,
          limbW, legH, v.trouserColor, opacity, dx: stride);
      _fillRect(canvas, currentX + torsoW * 0.35 - limbW, legYTop,
          limbW, legH, v.trouserColor, opacity, dx: -stride);

      // Shoes
      final double shoeH = figH * 0.04;
      _fillRect(canvas, currentX - torsoW * 0.35 + stride, baseY - shoeH,
          limbW + 2, shoeH, const Color(0xFF37474F), opacity);
      _fillRect(canvas, currentX + torsoW * 0.35 - limbW - stride, baseY - shoeH,
          limbW + 2, shoeH, const Color(0xFF37474F), opacity);

      // ── Torso ────────────────────────────────────────────
      final double torsoTop = baseY - legH - torsoH;
      _fillRRect(canvas, currentX - torsoW / 2, torsoTop,
          torsoW, torsoH, 3.0, v.shirtColor, opacity);

      // ── Arms ─────────────────────────────────────────────
      final double armSwing =
          sin(walkProgress * 14 + v.delay * 20) * 0.25 * (1 - t);
      _drawArm(canvas, currentX - torsoW / 2, shoulderY, armLen, limbW,
          v.shirtColor, v.skinColor, opacity, armSwing, isLeft: true);
      _drawArm(canvas, currentX + torsoW / 2, shoulderY, armLen, limbW,
          v.shirtColor, v.skinColor, opacity, -armSwing, isLeft: false);

      // ── Head ─────────────────────────────────────────────
      final double headCY = neckY + headR * 0.15;
      // Hair (slightly larger circle behind head)
      canvas.drawCircle(
        Offset(currentX, headCY - headR * 0.15),
        headR * 1.15,
        Paint()..color = v.hairColor.withValues(alpha: opacity),
      );
      // Face
      canvas.drawCircle(
        Offset(currentX, headCY),
        headR,
        Paint()..color = v.skinColor.withValues(alpha: opacity),
      );
      // Eyes
      final double eyeR = headR * 0.10;
      canvas.drawCircle(
        Offset(currentX - headR * 0.30, headCY - headR * 0.10),
        eyeR,
        Paint()..color = Colors.brown.withValues(alpha: opacity * 0.85),
      );
      canvas.drawCircle(
        Offset(currentX + headR * 0.30, headCY - headR * 0.10),
        eyeR,
        Paint()..color = Colors.brown.withValues(alpha: opacity * 0.85),
      );
      // Mouth (tiny arc)
      final mouthPath = Path()
        ..addArc(
          Rect.fromCenter(
            center: Offset(currentX, headCY + headR * 0.30),
            width: headR * 0.55,
            height: headR * 0.30,
          ),
          0.1, pi - 0.2,
        );
      canvas.drawPath(
        mouthPath,
        Paint()
          ..color = const Color(0xFFBF360C).withValues(alpha: opacity * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round,
      );

      canvas.restore();
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  /// Filled rectangle with optional horizontal shift [dx].
  void _fillRect(Canvas canvas, double x, double y, double w, double h,
      Color color, double opacity, {double dx = 0}) {
    canvas.drawRect(
      Rect.fromLTWH(x + dx, y, w, h),
      Paint()..color = color.withValues(alpha: opacity),
    );
  }

  /// Filled rounded rectangle.
  void _fillRRect(Canvas canvas, double x, double y, double w, double h,
      double r, Color color, double opacity) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      Paint()..color = color.withValues(alpha: opacity),
    );
  }

  /// Draws an arm: upper arm (sleeve colour) + forearm/hand (skin).
  void _drawArm(Canvas canvas, double shoulderX, double shoulderY,
      double length, double width, Color sleeveColor, Color skinColor,
      double opacity, double swingRad, {required bool isLeft}) {
    canvas.save();
    canvas.translate(shoulderX, shoulderY);
    canvas.rotate(swingRad);

    // Upper arm (sleeve)
    _fillRect(canvas, -width / 2, 0, width, length * 0.55,
        sleeveColor, opacity);
    // Forearm + hand (skin)
    _fillRect(canvas, -width / 2, length * 0.55, width, length * 0.45,
        skinColor, opacity);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VolunteerPainter oldDelegate) {
    // Always repaint while the animation controller is running so
    // the volunteer figures never disappear from the composited layer.
    return true;
  }
}
