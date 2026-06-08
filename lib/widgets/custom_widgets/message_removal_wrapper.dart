import 'package:flutter/material.dart';

/// Telegram-style message removal animation.
/// Phase 1: Fade out + subtle scale down (300ms, easeOut)
/// Phase 2: Collapse vertical space (200ms, easeInOut)
class MessageRemovalWrapper extends StatefulWidget {
  final Widget child;
  final bool isRemoving;
  final VoidCallback onAnimationComplete;

  const MessageRemovalWrapper({
    super.key,
    required this.child,
    required this.isRemoving,
    required this.onAnimationComplete,
  });

  @override
  State<MessageRemovalWrapper> createState() => _MessageRemovalWrapperState();
}

class _MessageRemovalWrapperState extends State<MessageRemovalWrapper>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _collapseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _collapseAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _collapseAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _collapseController, curve: Curves.easeInOut),
    );

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _collapseController.forward();
      }
    });

    _collapseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });

    if (widget.isRemoving) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startRemovalAnimation();
      });
    }
  }

  void _startRemovalAnimation() {
    if (!_fadeController.isAnimating && !_fadeController.isCompleted) {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(MessageRemovalWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRemoving && !oldWidget.isRemoving) {
      _startRemovalAnimation();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _collapseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _collapseAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}
