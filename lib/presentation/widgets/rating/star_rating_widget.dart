import 'package:flutter/material.dart';

/// Displays an average rating as filled/half/empty stars plus a numeric value.
/// Shows nothing when [averageRating] is null.
/// Requirement 8.4, 17.3
class StarRatingWidget extends StatelessWidget {
  final double? averageRating;
  final double starSize;

  const StarRatingWidget({
    required this.averageRating,
    this.starSize = 18.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (averageRating == null) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    final filled = averageRating!.floor();
    final hasHalf = (averageRating! - filled) >= 0.5;
    final color = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          final IconData icon;
          if (starValue <= filled) {
            icon = Icons.star;
          } else if (starValue == filled + 1 && hasHalf) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
          return Icon(icon, size: starSize, color: color);
        }),
        const SizedBox(width: 4),
        Text(
          averageRating!.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
