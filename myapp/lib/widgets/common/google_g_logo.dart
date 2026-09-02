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
      child: CustomPaint(
        painter: _GoogleGLogoPainter(),
      ),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;
    final double thickness = w * 0.20;
    final double midR = r - thickness / 2;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: midR);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt;

    // 1. Red Segment (Top: -145° to -15°)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      rect,
      -math.pi * 0.81,
      math.pi * 0.73,
      false,
      paint,
    );

    // 2. Yellow Segment (Left: -220° to -145°)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      rect,
      -math.pi * 1.22,
      math.pi * 0.41,
      false,
      paint,
    );

    // 3. Green Segment (Bottom: 32° to 140°)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      rect,
      math.pi * 0.18,
      math.pi * 0.60,
      false,
      paint,
    );

    // 4. Blue Segment (Right: -15° to 32°)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      rect,
      -math.pi * 0.08,
      math.pi * 0.26,
      false,
      paint,
    );

    // 5. Blue Horizontal Crossbar extending to center
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTWH(
      cx - thickness * 0.05,
      cy - thickness / 2,
      r + thickness * 0.05,
      thickness,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
