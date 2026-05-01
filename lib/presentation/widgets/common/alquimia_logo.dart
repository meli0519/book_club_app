import 'package:flutter/material.dart';

/// Animated logo widget for Alquimia Literaria.
/// Displays the club name with mystical styling.
class AlquimiaLogo extends StatefulWidget {
  final double size;
  final bool showText;
  final bool animate;

  const AlquimiaLogo({
    this.size = 120,
    this.showText = true,
    this.animate = true,
    super.key,
  });

  @override
  State<AlquimiaLogo> createState() => _AlquimiaLogoState();
}

class _AlquimiaLogoState extends State<AlquimiaLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Book icon with mystical elements
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark
                                ? const Color(0xFF2D9B7F)
                                : const Color(0xFF4ECDB3))
                            .withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.auto_stories,
                      size: widget.size * 0.6,
                      color: isDark
                          ? const Color(0xFF4ECDB3)
                          : const Color(0xFF2D9B7F),
                    ),
                  ),
                ),
                if (widget.showText) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Alquimia Literaria',
                    style: TextStyle(
                      fontSize: widget.size * 0.2,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      fontFamily: 'serif',
                      color: isDark
                          ? const Color(0xFF4ECDB3)
                          : const Color(0xFF2D9B7F),
                      shadows: [
                        Shadow(
                          color: (isDark
                                  ? const Color(0xFF2D9B7F)
                                  : const Color(0xFF4ECDB3))
                              .withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_fix_high,
                        size: widget.size * 0.12,
                        color: const Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.menu_book,
                        size: widget.size * 0.12,
                        color: const Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.auto_fix_high,
                        size: widget.size * 0.12,
                        color: const Color(0xFFFFD700),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
