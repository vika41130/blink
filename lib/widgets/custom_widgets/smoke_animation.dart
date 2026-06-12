import 'dart:math';
import 'package:flutter/material.dart';

/// Shows a flying smoke effect at the given position using an Overlay.
void showSmokeEffect(BuildContext context, Offset position) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder:
        (_) =>
            _SmokeOverlay(position: position, onComplete: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _SmokeOverlay extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const _SmokeOverlay({required this.position, required this.onComplete});

  @override
  State<_SmokeOverlay> createState() => _SmokeOverlayState();
}

class _SmokeOverlayState extends State<_SmokeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _particles = List.generate(20, (_) => _createParticle());
    _controller.forward().then((_) => widget.onComplete());
  }

  _Particle _createParticle() {
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 120 + 40;
    return _Particle(
      dx: cos(angle) * speed,
      dy: sin(angle) * speed - 60, // bias upward for flying effect
      size: _random.nextDouble() * 16 + 8,
      startOpacity: _random.nextDouble() * 0.4 + 0.6,
      rotationSpeed: (_random.nextDouble() - 0.5) * 4,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Stack(
          children:
              _particles.map((p) {
                final curve = Curves.easeOut.transform(t);
                final x = widget.position.dx + p.dx * curve;
                final y = widget.position.dy + p.dy * curve;
                final opacity = p.startOpacity * (1.0 - t);
                final size = p.size * (1.0 + t * 1.5);
                return Positioned(
                  left: x - size / 2,
                  top: y - size / 2,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: p.rotationSpeed * t * pi,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.8),
                              Colors.grey.shade500.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

class _Particle {
  final double dx;
  final double dy;
  final double size;
  final double startOpacity;
  final double rotationSpeed;

  _Particle({
    required this.dx,
    required this.dy,
    required this.size,
    required this.startOpacity,
    required this.rotationSpeed,
  });
}
