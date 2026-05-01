import 'package:flutter/material.dart';

/// A row of 5 tappable stars for selecting a rating (1–5).
/// [currentRating] of 0 means no star is selected.
/// Requirement 8.1, 8.2
class StarRatingSelectorWidget extends StatelessWidget {
  final int currentRating;
  final ValueChanged<int> onRatingSelected;
  final double starSize;

  const StarRatingSelectorWidget({
    required this.currentRating,
    required this.onRatingSelected,
    this.starSize = 32.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= currentRating;
        return Tooltip(
          message: '$starValue',
          child: Semantics(
            label: 'Rate $starValue out of 5',
            button: true,
            child: GestureDetector(
              onTap: () => onRatingSelected(starValue),
              child: Icon(
                isFilled ? Icons.star : Icons.star_border,
                size: starSize,
                color: isFilled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        );
      }),
    );
  }
}
