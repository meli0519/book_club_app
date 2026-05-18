import 'package:flutter/material.dart';
import '../../../domain/models/rating_with_user.dart';
import '../../../l10n/app_localizations.dart';

/// Displays a single member's rating: avatar, name, email, stars, and optional comment.
/// Requirement 24.2
class RatingListItem extends StatelessWidget {
  final RatingWithUser rating;

  const RatingListItem({required this.rating, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final filledColor = theme.colorScheme.primary;
    final emptyColor = theme.colorScheme.outline;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar: photo if available, else initial
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: rating.authorPhotoUrl.isNotEmpty
                      ? NetworkImage(rating.authorPhotoUrl)
                      : null,
                  child: rating.authorPhotoUrl.isEmpty
                      ? Text(
                          rating.authorName.isNotEmpty
                              ? rating.authorName[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                // Name + email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.authorName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (rating.authorEmail.isNotEmpty)
                        Text(
                          rating.authorEmail,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Stars
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final starValue = i + 1;
                    final filled = starValue <= rating.value.floor();
                    final isHalf = starValue == rating.value.ceil() &&
                        rating.value % 1 != 0;
                    return Icon(
                      filled
                          ? Icons.star
                          : isHalf
                              ? Icons.star_half
                              : Icons.star_border,
                      size: 18,
                      color: (filled || isHalf) ? filledColor : emptyColor,
                    );
                  }),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.ratingValue(rating.value),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                rating.comment!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
