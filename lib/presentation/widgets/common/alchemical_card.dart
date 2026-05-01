import 'package:flutter/material.dart';

/// A card with mystical styling inspired by the Alquimia Literaria aesthetic.
/// Features subtle glow effects and elegant borders.
class AlchemicalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool showGlow;

  const AlchemicalCard({
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.showGlow = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final card = Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2D9B7F).withValues(alpha: 0.3)
              : const Color(0xFF4ECDB3).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: (isDark
                          ? const Color(0xFF2D9B7F)
                          : const Color(0xFF4ECDB3))
                      .withValues(alpha: isDark ? 0.2 : 0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}
