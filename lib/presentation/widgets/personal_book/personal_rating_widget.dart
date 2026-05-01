import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import '../../../domain/models/personal_book.dart';
import '../rating/star_rating_selector.dart';

/// A 5-star rating control for personal books.
/// Only visible/enabled when the book's status is 'read'.
class PersonalRatingWidget extends StatelessWidget {
  final String status;
  final int? currentRating;
  final ValueChanged<int> onRatingChanged;

  const PersonalRatingWidget({
    required this.status,
    this.currentRating,
    required this.onRatingChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRead = status == PersonalBookStatus.read;

    if (!isRead) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.personalBookRatingLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        StarRatingSelectorWidget(
          currentRating: currentRating ?? 0,
          onRatingSelected: onRatingChanged,
          starSize: 32,
        ),
        if (currentRating != null && currentRating! > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.personalBookRatingValue(currentRating!),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}

/// Returns true if the rating widget should be visible for the given status.
bool shouldShowRating(String status) {
  return status == PersonalBookStatus.read;
}