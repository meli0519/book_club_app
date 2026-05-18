import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/personal_book.dart';
import '../../routes/app_router.dart';
import '../common/tappable_scale.dart';
import '../rating/star_rating_widget.dart';
import 'personal_book_status_chip.dart';

/// A card widget that displays a personal book's cover, title, author and status.
/// Tapping navigates to PersonalBookDetailScreen.
class PersonalBookCard extends StatelessWidget {
  final PersonalBook book;

  const PersonalBookCard({required this.book, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = book.status == PersonalBookStatus.read;
    final hasRating = book.rating != null;

    return TappableScale(
      onTap: () => context.push(AppRoutes.personalBookDetail(book.id)),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            SizedBox(
              width: 80,
              height: 110,
              child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _CoverPlaceholder(),
                    )
                  : const _CoverPlaceholder(),
            ),
            // Book info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Show rating if book is read and has rating, otherwise show status chip
                    if (isRead && hasRating)
                      StarRatingWidget(averageRating: book.rating)
                    else
                      PersonalBookStatusChip(status: book.status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.book, size: 40),
    );
  }
}