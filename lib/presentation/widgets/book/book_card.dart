import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/book.dart';
import '../../providers/rating_provider.dart';
import '../../routes/app_router.dart';
import '../common/tappable_scale.dart';
import '../rating/star_rating_widget.dart';

/// A card widget that displays a book's cover, title, author and status.
/// Tapping navigates to BookDetailScreen.
class BookCard extends ConsumerWidget {
  final Book book;

  const BookCard({required this.book, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRead = book.status == 'read';
    final ratingAsync = ref.watch(bookAverageRatingProvider(book.id));
    final averageRating = ratingAsync.valueOrNull;

    return TappableScale(
      onTap: () => context.push(AppRoutes.bookDetail(book.id)),
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
              child: book.coverUrl.isNotEmpty
                  ? Image.network(
                      book.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _CoverPlaceholder(),
                    )
                  : _CoverPlaceholder(),
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
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Show rating if book is read, otherwise show status chip
                    if (isRead && averageRating != null)
                      StarRatingWidget(averageRating: averageRating)
                    else
                      _StatusChip(isRead: isRead),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.book, size: 40),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isRead;

  const _StatusChip({required this.isRead});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isRead
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isRead ? '✓ Leído' : '📖 Leyendo',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isRead
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
