import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../domain/models/personal_book.dart';
import '../../providers/auth_provider.dart';
import '../../providers/personal_book_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/animated_list_item.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/personal_book/personal_book_card.dart';
import '../../widgets/personal_book/personal_book_status_filter.dart';

/// Screen that displays a list of personal books for the authenticated user.
///
/// Shows all personal books ordered by updatedAt descending, with the ability
/// to filter by status (want_to_read, reading, read). Includes a floating action
/// button to add new personal books.
///
/// Validates: Requirements 1.1, 2.5, 4.2, 5.1, 5.2, 5.3, 9.1, 9.2, 9.3
class PersonalBooksScreen extends ConsumerStatefulWidget {
  const PersonalBooksScreen({super.key});

  @override
  ConsumerState<PersonalBooksScreen> createState() =>
      _PersonalBooksScreenState();
}

class _PersonalBooksScreenState extends ConsumerState<PersonalBooksScreen>
    with SingleTickerProviderStateMixin {
  String _selectedStatus = 'all';
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    // Delay FAB entrance slightly so it pops in after the list
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String status) {
    setState(() => _selectedStatus = status);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Determine which provider to use based on filter selection
    final AsyncValue<List<PersonalBook>> booksAsyncValue;
    if (_selectedStatus == 'all') {
      booksAsyncValue = ref.watch(personalBooksStreamProvider);
    } else {
      booksAsyncValue = ref.watch(
        personalBooksByStatusProvider(_selectedStatus),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.personalBooksTitle),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status filter
          PersonalBookStatusFilter(
            selectedStatus: _selectedStatus,
            onStatusSelected: _onFilterChanged,
          ),
          // Books list
          Expanded(
            child: booksAsyncValue.when(
              data: (books) => books.isEmpty
                  ? _EmptyState(onAddBook: _navigateToCreateBook)
                  : _BooksList(books: books),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => _ErrorState(
                error: error,
                onRetry: () => ref.refresh(
                  _selectedStatus == 'all'
                      ? personalBooksStreamProvider
                      : personalBooksByStatusProvider(_selectedStatus),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: _navigateToCreateBook,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _navigateToCreateBook() {
    context.push(AppRoutes.createPersonalBook);
  }
}

/// Widget that displays the list of personal books.
class _BooksList extends StatelessWidget {
  final List<PersonalBook> books;

  const _BooksList({required this.books});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: books.length,
      itemBuilder: (context, index) => AnimatedListItem(
        index: index,
        child: PersonalBookCard(book: books[index]),
      ),
    );
  }
}

/// Empty state widget shown when the user has no personal books.
class _EmptyState extends StatelessWidget {
  final VoidCallback onAddBook;

  const _EmptyState({required this.onAddBook});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.personalBookEmptyTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.personalBookEmptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAddBook,
              icon: const Icon(Icons.add),
              label: Text(l10n.addPersonalBook),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state widget shown when the stream fails.
class _ErrorState extends ConsumerWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Show SnackBar with error message without blocking navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.personalBookErrorLoading),
          action: SnackBarAction(
            label: l10n.retry,
            onPressed: onRetry,
          ),
        ),
      );
    });

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.personalBookErrorLoading,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}