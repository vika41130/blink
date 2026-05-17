import 'package:flutter/material.dart';

class CornerBorderPainter extends CustomPainter {
  final Color strokeColor;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  CornerBorderPainter({
    required this.strokeColor,
    required this.strokeWidth,
    required this.cornerLength,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap =
              StrokeCap.round; // Gives the stroke lines smooth, rounded tips

    final double w = size.width;
    final double h = size.height;
    final double r = cornerRadius;
    final double l = cornerLength;

    // --- Top Left Corner ---
    final pathTopLeft =
        Path()
          ..moveTo(0, l)
          ..lineTo(0, r)
          ..quadraticBezierTo(0, 0, r, 0)
          ..lineTo(l, 0);
    canvas.drawPath(pathTopLeft, paint);

    // --- Top Right Corner ---
    final pathTopRight =
        Path()
          ..moveTo(w - l, 0)
          ..lineTo(w - r, 0)
          ..quadraticBezierTo(w, 0, w, r)
          ..lineTo(w, l);
    canvas.drawPath(pathTopRight, paint);

    // --- Bottom Left Corner ---
    final pathBottomLeft =
        Path()
          ..moveTo(0, h - l)
          ..lineTo(0, h - r)
          ..quadraticBezierTo(0, h, r, h)
          ..lineTo(l, h);
    canvas.drawPath(pathBottomLeft, paint);

    // --- Bottom Right Corner ---
    final pathBottomRight =
        Path()
          ..moveTo(w - l, h)
          ..lineTo(w - r, h)
          ..quadraticBezierTo(w, h, w, h - r)
          ..lineTo(w, h - l);
    canvas.drawPath(pathBottomRight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
