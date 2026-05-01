import 'package:flutter/material.dart';

/// Displays a star rating with mystical golden stars.
/// Inspired by the stars in the Alquimia Literaria logo.
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color? color;
  final bool showValue;

  const StarRatingDisplay({
    required this.rating,
    this.maxRating = 5,
    this.size = 20,
    this.color,
    this.showValue = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starColor = color ?? const Color(0xFFFFD700); // Magic gold

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxRating, (index) {
          final starValue = index + 1;
          IconData icon;
          
          if (rating >= starValue) {
            icon = Icons.star;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }

          return Icon(
            icon,
            size: size,
            color: starColor,
          );
        }),
        if (showValue) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: starColor,
            ),
          ),
        ],
      ],
    );
  }
}
