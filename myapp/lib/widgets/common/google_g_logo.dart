import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Official Google "G" logo rendered via CustomPainter with 4 brand colors:
/// Blue (#4285F4), Green (#34A853), Yellow (#FBBC05), Red (#EA4335).
class GoogleGLogo extends StatelessWidget {
  final double size;

  const GoogleGLogo({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _GoogleGLogoPainter()),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  const _GoogleGLogoPainter();

  // Angular sweep for each color, expressed as a fraction of pi.
  // These four sweeps sum to exactly 2.0 (i.e. 360deg) so the ring closes
  // with no gaps and no overlaps.
  static const double _redStart = -0.81;
  static const double _redSweep = 0.73;

  static const double _yellowStart = -1.22;
  static const double _yellowSweep = 0.41;

  static const double _greenStart = 0.18;
  static const double _greenSweep = 0.60;

  static const double _blueStart = -0.08;
  static const double _blueSweep = 0.26;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    // Small inset so the stroke never touches the exact edge of the
    // widget's bounding box — prevents 1px clipping/anti-alias artifacts
    // when this is placed inside a button, circular avatar, etc.
    final double r = (math.min(w, h) / 2) * 0.96;

    final double thickness = w * 0.20;
    final double midR = r - thickness / 2;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: midR);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // 1. Red segment (top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      rect,
      math.pi * _redStart,
      math.pi * _redSweep,
      false,
      paint,
    );

    // 2. Yellow segment (left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      rect,
      math.pi * _yellowStart,
      math.pi * _yellowSweep,
      false,
      paint,
    );

    // 3. Green segment (bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      rect,
      math.pi * _greenStart,
      math.pi * _greenSweep,
      false,
      paint,
    );

    // 4. Blue segment (right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      rect,
      math.pi * _blueStart,
      math.pi * _blueSweep,
      false,
      paint,
    );

    // 5. Blue crossbar — fills the transparent interior on the right side,
    // from just past center out to the outer edge of the ring, giving the
    // logo its "G" tail. Only overlaps the already-blue arc region, so no
    // other color gets covered.
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final barRect = Rect.fromLTRB(
      cx - thickness * 0.05, // starts just past center
      cy - thickness / 2,
      cx + r, // ends exactly at the ring's outer radius
      cy + thickness / 2,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant _GoogleGLogoPainter oldDelegate) => false;
}
