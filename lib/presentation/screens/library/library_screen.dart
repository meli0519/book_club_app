import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/user_book_entry.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/library_provider.dart';
import '../../widgets/book/library_book_card.dart';

/// Personal library screen showing books organized by user-level category tabs.
/// Task 20.1 – "Quiero leer", "Leyendo", "Leídos"
/// Task 20.2 – Each tab uses [libraryWithDetailsByCategoryProvider] to show
///             cover, title, author, and average rating.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.libraryTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.libraryTabWantToRead),
              Tab(text: l10n.libraryTabReading),
              Tab(text: l10n.libraryTabRead),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LibraryCategoryTab(
              category: UserBookCategory.wantToRead,
              emptyMessage: l10n.libraryEmptyWantToRead,
            ),
            _LibraryCategoryTab(
              category: UserBookCategory.reading,
              emptyMessage: l10n.libraryEmptyReading,
            ),
            _LibraryCategoryTab(
              category: UserBookCategory.read,
              emptyMessage: l10n.libraryEmptyRead,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab content widget
// ---------------------------------------------------------------------------

class _LibraryCategoryTab extends ConsumerWidget {
  final String category;
  final String emptyMessage;

  const _LibraryCategoryTab({
    required this.category,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync =
        ref.watch(libraryWithDetailsByCategoryProvider(category));

    return booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(AppLocalizations.of(context)!.libraryErrorLoading),
        ),
      ),
      data: (books) {
        if (books.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: books.length,
          itemBuilder: (context, index) =>
              LibraryBookCard(item: books[index]),
        );
      },
    );
  }
}


