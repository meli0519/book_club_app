import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Displays the average rating as filled/empty stars + numeric value.
/// Shows "Sin calificaciones" / "No ratings yet" when [averageRating] is null.
/// Requirement 8.4
class AverageRatingDisplayWidget extends StatelessWidget {
  final double? averageRating;
  final double starSize;

  const AverageRatingDisplayWidget({
    required this.averageRating,
    this.starSize = 20.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (averageRating == null) {
      return Text(
        l10n.noRatingsYet,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final filled = averageRating!.floor();
    final hasHalf = (averageRating! - filled) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon;
          if (starValue <= filled) {
            icon = Icons.star;
          } else if (starValue == filled + 1 && hasHalf) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
          return Icon(
            icon,
            size: starSize,
            color: Theme.of(context).colorScheme.primary,
          );
        }),
        const SizedBox(width: 6),
        Text(
          averageRating!.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
