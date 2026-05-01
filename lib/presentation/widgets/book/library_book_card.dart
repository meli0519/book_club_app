import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/user_book_entry.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/library_provider.dart';

/// Reusable card widget for displaying a book in the personal library.
/// Shows cover image, title, author, and average rating (if available).
/// Tapping navigates to the book detail screen.
/// A trailing [PopupMenuButton] allows changing the category or removing the book.
class LibraryBookCard extends ConsumerWidget {
  final UserBookWithDetails item;

  const LibraryBookCard({required this.item, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = item.book;
    final rating = item.averageRating;
    final currentCategory = item.entry.category;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/books/${book.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoverImage(coverUrl: book.coverUrl),
              const SizedBox(width: 12),
              Expanded(
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
                    if (rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _CategoryMenu(
                bookId: book.id,
                currentCategory: currentCategory,
                l10n: l10n,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category popup menu
// ---------------------------------------------------------------------------

class _CategoryMenu extends ConsumerWidget {
  final String bookId;
  final String currentCategory;
  final AppLocalizations l10n;

  const _CategoryMenu({
    required this.bookId,
    required this.currentCategory,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: l10n.libraryChangeCategory,
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _onSelected(context, ref, value),
      itemBuilder: (_) => [
        _categoryItem(UserBookCategory.wantToRead, l10n.libraryCategoryWantToRead),
        _categoryItem(UserBookCategory.reading, l10n.libraryCategoryReading),
        _categoryItem(UserBookCategory.read, l10n.libraryCategoryRead),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: '_remove',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.libraryRemoveFromLibrary,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _categoryItem(String category, String label) {
    final isCurrent = category == currentCategory;
    return PopupMenuItem<String>(
      value: category,
      child: Row(
        children: [
          Icon(
            isCurrent ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: isCurrent ? null : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: isCurrent
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _onSelected(BuildContext context, WidgetRef ref, String value) async {
    if (value == '_remove') {
      await _removeBook(context, ref);
    } else {
      await _changeCategory(context, ref, value);
    }
  }

  Future<void> _changeCategory(BuildContext context, WidgetRef ref, String category) async {
    try {
      await ref.read(librarySetCategoryProvider)(bookId, category);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.libraryCategoryChangedSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.libraryCategoryChangeError)),
        );
      }
    }
  }

  Future<void> _removeBook(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(libraryRemoveFromLibraryProvider)(bookId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.libraryRemovedSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.libraryRemoveError)),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Cover image
// ---------------------------------------------------------------------------

class _CoverImage extends StatelessWidget {
  final String coverUrl;

  const _CoverImage({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    const width = 72.0;
    const height = 96.0;

    if (coverUrl.isEmpty) {
      return _placeholder(context, width, height);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        coverUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(context, width, height),
      ),
    );
  }

  Widget _placeholder(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.book_outlined,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
