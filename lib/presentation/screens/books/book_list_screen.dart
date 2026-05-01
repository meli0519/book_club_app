import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:book_club_app/l10n/app_localizations.dart';

import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/book/book_card.dart';
import '../../widgets/common/animated_list_item.dart';
import '../../widgets/common/app_drawer.dart';

/// Displays the list of all books ordered by createdAt descending.
/// Requirement 5.1, 12.1
class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserAsync = ref.watch(currentUserProvider);
    final isLeader = currentUserAsync.valueOrNull?.isLeader ?? false;
    final booksAsync = ref.watch(booksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.bookListError,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.bookListEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: books.length,
            itemBuilder: (context, index) => AnimatedListItem(
              index: index,
              child: BookCard(book: books[index]),
            ),
          );
        },
      ),
      floatingActionButton: isLeader
          ? FloatingActionButton(
              onPressed: () => context.push(AppRoutes.createBook),
              tooltip: l10n.createBook,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
