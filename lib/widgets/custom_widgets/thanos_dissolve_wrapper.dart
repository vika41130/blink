import 'dart:math' as math;

import 'package:blink/widgets/custom_widgets/dissolve_particle.dart';
import 'package:blink/widgets/custom_widgets/particle_painter.dart';
import 'package:flutter/material.dart';

class ThanosDissolveWrapper extends StatefulWidget {
  final Widget child;
  final bool isDeleted;
  final Color messageColor;
  final VoidCallback onAnimationComplete;

  const ThanosDissolveWrapper({
    super.key,
    required this.child,
    required this.isDeleted,
    required this.messageColor,
    required this.onAnimationComplete,
  });

  @override
  State<ThanosDissolveWrapper> createState() => _ThanosDissolveWrapperState();
}

class _ThanosDissolveWrapperState extends State<ThanosDissolveWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<DissolveParticle> _particles = [];
  final math.Random _random = math.Random();
  bool _showOriginal = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Thời gian tan biến
    );

    _controller.addListener(() {
      setState(() {
        for (var particle in _particles) {
          particle.update();
        }
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 150; i++) {
      double startX = _random.nextDouble() * 100;
      double startY = _random.nextDouble() * 50;

      _particles.add(
        DissolveParticle(
          x: startX,
          y: startY,
          vx: _random.nextDouble() * 3 + 1,
          vy: (_random.nextDouble() * -4) - 1,
          size: _random.nextDouble() * 3 + 2,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(ThanosDissolveWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDeleted && !oldWidget.isDeleted) {
      _generateParticles();
      setState(() {
        _showOriginal = false;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showOriginal) widget.child,
        if (!_showOriginal)
          CustomPaint(
            painter: ParticlePainter(
              particles: _particles,
              color: widget.messageColor,
            ),
            child: const SizedBox(width: 100, height: 50),
          ),
      ],
    );
  }
}
