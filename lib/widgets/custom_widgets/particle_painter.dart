import 'package:blink/widgets/custom_widgets/dissolve_particle.dart';
import 'package:flutter/material.dart';

class ParticlePainter extends CustomPainter {
  final List<DissolveParticle> particles;
  final Color color;

  ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      if (particle.opacity > 0) {
        // Vẽ từng hạt vuông nhỏ đại diện cho pixel tin nhắn bị vỡ
        paint.color = color.withAlpha(
          (particle.opacity * 255).clamp(0, 255).toInt(),
        );
        canvas.drawRect(
          Rect.fromLTWH(particle.x, particle.y, particle.size, particle.size),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
