import 'package:flutter/material.dart';

/// Wraps a child widget with a staggered fade + slide-up entrance animation.
///
/// Each item in a list receives a [index]-based delay so they cascade in
/// one after another. The animation plays once when the widget is first
/// inserted into the tree.
class AnimatedListItem extends StatefulWidget {
  final Widget child;

  /// Position in the list — drives the stagger delay.
  final int index;

  /// Base delay before the first item starts animating.
  final Duration baseDelay;

  /// Delay added per item index.
  final Duration staggerDelay;

  /// Total duration of the entrance animation.
  final Duration duration;

  const AnimatedListItem({
    required this.child,
    required this.index,
    this.baseDelay = Duration.zero,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 400),
    super.key,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Cap stagger so very long lists don't wait forever (max 600 ms total)
    final cappedIndex = widget.index.clamp(0, 10);
    final delay = widget.baseDelay +
        Duration(
          milliseconds:
              cappedIndex * widget.staggerDelay.inMilliseconds,
        );

    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
