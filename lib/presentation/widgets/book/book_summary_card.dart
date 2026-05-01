import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/book.dart';
import '../../providers/rating_provider.dart';
import '../../routes/app_router.dart';
import '../common/tappable_scale.dart';
import '../rating/star_rating_widget.dart';

/// Reusable card showing book cover, title, author and average star rating.
/// Tapping navigates to BookDetailScreen.
/// Requirements 5.1, 8.4, 17.2, 17.3
class BookSummaryCard extends ConsumerWidget {
  final Book book;

  const BookSummaryCard({required this.book, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
              height: 120,
              child: book.coverUrl.isNotEmpty
                  ? Image.network(
                      book.coverUrl,
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
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
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
                    StarRatingWidget(averageRating: averageRating),
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
      child: const Center(child: Icon(Icons.book, size: 36)),
    );
  }
}
