import 'package:flutter/material.dart';

/// A row of 5 tappable/draggable stars for selecting a rating in 0.5 increments.
/// [currentRating] of 0.0 means no star is selected.
/// Supports half-star selection (e.g. 3.5) via tap on left/right half of each star
/// or by dragging across the row.
class StarRatingSelectorWidget extends StatelessWidget {
  final double currentRating;
  final ValueChanged<double> onRatingSelected;
  final double starSize;

  const StarRatingSelectorWidget({
    required this.currentRating,
    required this.onRatingSelected,
    this.starSize = 32.0,
    super.key,
  });

  /// Calculates the rating value (0.5 increments) from a local x position
  /// within the full row width.
  double _ratingFromPosition(double localX, double totalWidth) {
    final starWidth = totalWidth / 5;
    final rawStar = localX / starWidth; // 0.0 – 5.0
    // Round to nearest 0.5
    final rounded = (rawStar * 2).ceil() / 2;
    return rounded.clamp(0.5, 5.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a fixed width when unconstrained (e.g. inside a Row with mainAxisSize.min)
        final rowWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : starSize * 5 + 8 * 4; // 5 stars + gaps

        return GestureDetector(
          onTapUp: (details) {
            final value =
                _ratingFromPosition(details.localPosition.dx, rowWidth);
            onRatingSelected(value);
          },
          onHorizontalDragUpdate: (details) {
            final value =
                _ratingFromPosition(details.localPosition.dx, rowWidth);
            onRatingSelected(value);
          },
          child: SizedBox(
            width: rowWidth,
            height: starSize + 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final IconData icon;
                if (starValue <= currentRating.floor()) {
                  icon = Icons.star;
                } else if (starValue == currentRating.ceil() &&
                    currentRating % 1 != 0) {
                  icon = Icons.star_half;
                } else {
                  icon = Icons.star_border;
                }

                return Expanded(
                  child: Semantics(
                    label: 'Rate $starValue out of 5',
                    button: true,
                    child: Icon(
                      icon,
                      size: starSize,
                      color: icon != Icons.star_border
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
