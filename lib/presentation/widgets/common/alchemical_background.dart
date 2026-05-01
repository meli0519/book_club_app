import 'dart:math';
import 'package:flutter/material.dart';

/// Decorative background inspired by the Alquimia Literaria logo.
/// Creates a mystical atmosphere with floating emerald particles.
class AlchemicalBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const AlchemicalBackground({
    required this.child,
    this.isDark = false,
    super.key,
  });

  @override
  State<AlchemicalBackground> createState() => _AlchemicalBackgroundState();
}

class _AlchemicalBackgroundState extends State<AlchemicalBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
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
        // Background color
        Container(
          decoration: BoxDecoration(
            gradient: widget.isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D1B2A),
                      Color(0xFF1A2332),
                      Color(0xFF0D1B2A),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF8F9FA),
                      Color(0xFFE8F5F1),
                      Color(0xFFF8F9FA),
                    ],
                  ),
          ),
        ),
        // Animated particles
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ParticlePainter(
                animation: _controller.value,
                isDark: widget.isDark,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double animation;
  final bool isDark;
  final Random _random = Random(42); // Fixed seed for consistent particles

  _ParticlePainter({
    required this.animation,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark
              ? const Color(0xFF2D9B7F)
              : const Color(0xFF4ECDB3))
          .withValues(alpha: isDark ? 0.3 : 0.2);

    // Generate particles
    for (int i = 0; i < 30; i++) {
      final x = _random.nextDouble() * size.width;
      final baseY = _random.nextDouble() * size.height;
      
      // Animate particles floating up
      final y = (baseY + (animation * size.height * 0.5)) % size.height;
      
      final radius = _random.nextDouble() * 4 + 2;
      
      // Vary opacity based on position
      final opacity = (0.2 + (sin(animation * 2 * pi + i) * 0.3)).clamp(0.0, 1.0);
      paint.color = paint.color.withValues(alpha: opacity);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
