import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../domain/models/personal_book.dart';
import '../../../domain/models/personal_book_review.dart';
import '../../../domain/models/personal_note.dart';
import '../../providers/personal_book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/personal_book/personal_note_field.dart';
import '../../widgets/personal_book/personal_rating_widget.dart';
import '../../widgets/personal_book/personal_book_status_chip.dart';
import '../../widgets/personal_book/personal_review_form.dart';

/// Screen that displays the complete details of a personal book.
///
/// Shows all fields including cover, title, author, description, status,
/// startedAt, and finishedAt. Also provides editable notes and rating
/// (when status is 'read').
///
/// Validates: Requirements 4.1, 4.2, 4.3, 5.4, 6.1, 6.4, 7.1, 7.2, 7.3, 7.4, 9.2, 9.3
class PersonalBookDetailScreen extends ConsumerWidget {
  final String bookId;

  const PersonalBookDetailScreen({required this.bookId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final personalBookAsync = ref.watch(personalBookStreamProvider(bookId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.personalBooksTitle),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.editBook,
            onPressed: () => _navigateToEdit(context, bookId),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: l10n.delete,
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: personalBookAsync.when(
        data: (book) {
          if (book == null) {
            return _BookNotFound(l10n: l10n);
          }
          final authState = ref.watch(authStateProvider).valueOrNull;
          return _BookDetailContent(
            book: book,
            userId: authState?.uid ?? '',
            onNoteAdded: (note) => _saveNote(context, ref, note),
            onNoteDeleted: (note) => _deleteNote(context, ref, note),
            onNoteUpdated: (oldNote, newNote) =>
                _updateNote(context, ref, oldNote, newNote),
            onRatingChanged: (rating) => _saveRating(context, ref, rating),
            onReviewSubmitted: (review) => _saveReview(context, ref, review),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorState(
          error: error,
          l10n: l10n,
          onRetry: () => ref.refresh(personalBookStreamProvider(bookId)),
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, String bookId) {
    context.push(AppRoutes.editPersonalBook(bookId));
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final personalBook = ref.read(personalBookStreamProvider(bookId)).valueOrNull;

    if (personalBook == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.personalBookDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _deleteBook(context, ref);
    }
  }

  Future<void> _deleteBook(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final personalBookService = ref.read(personalBookServiceProvider);
    final authState = ref.read(authStateProvider).valueOrNull;

    if (authState == null) return;

    try {
      await personalBookService.deletePersonalBook(authState.uid, bookId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personalBookDeletedSuccess)),
        );
        context.push(AppRoutes.personalBooks);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personalBookDeleteError)),
        );
      }
    }
  }

  Future<void> _saveNote(
    BuildContext context,
    WidgetRef ref,
    PersonalNote note,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final personalBookService = ref.read(personalBookServiceProvider);
    final authState = ref.read(authStateProvider).valueOrNull;

    if (authState == null) return;

    try {
      await personalBookService.addNote(authState.uid, bookId, note);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personalBookUpdatedSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personalBookSaveError)),
        );
      }
    }
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    PersonalNote note,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final personalBookService = ref.read(personalBookServiceProvider);
    final authState = ref.read(authStateProvider).valueOrNull;

    if (authState == null) return;

    try {
      await personalBookService.removeNote(authState.uid, bookId, note);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personalBookSaveError)),
        );
      }
    }
  }

  Future<void> _updateNote(
    BuildContext context,
    WidgetRef ref,
    PersonalNote oldNote,
    PersonalNote newNote,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final personalBookService = ref.read(personalBookServiceProvider);
    final authState = ref.read(authStateProvider).valueOrNull;

    if (authState == null) return;

    try {
      await personalBookService.updateNote(
        authState.uid,
        bookId,
        oldNote,
        newNote,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commentEditError)),
        );
      }
    }
  }
  Future<void> _saveRating(
    BuildContext context,
    WidgetRef ref,
    double rating,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final personalBookService = ref.read(personalBookServiceProvider);
    final authState = ref.read(authStateProvider).valueOrNull;

    if (authState == null) return;

    try {
      await personalBookService.updatePersonalBook(
        authState.uid,
        bookId,
        {'rating': rating},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personalBookUpdatedSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personalBookSaveError)),
        );
      }
    }
  }

  Future<void> _saveReview(
    BuildContext context,
    WidgetRef ref,
    PersonalBookReview review,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final personalBookService = ref.read(personalBookServiceProvider);
    final authState = ref.read(authStateProvider).valueOrNull;

    if (authState == null) return;

    try {
      await personalBookService.updatePersonalBook(
        authState.uid,
        bookId,
        {'review': review.toMap()},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personalBookReviewSubmittedSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personalBookReviewSubmitError)),
        );
      }
    }
  }
}

/// Widget that displays the complete content of a personal book.
class _BookDetailContent extends StatelessWidget {
  final PersonalBook book;
  final String userId;
  final Future<void> Function(PersonalNote note) onNoteAdded;
  final Future<void> Function(PersonalNote note) onNoteDeleted;
  final Future<void> Function(PersonalNote oldNote, PersonalNote newNote) onNoteUpdated;
  final ValueChanged<double> onRatingChanged;
  final Future<void> Function(PersonalBookReview review) onReviewSubmitted;

  const _BookDetailContent({
    required this.book,
    required this.userId,
    required this.onNoteAdded,
    required this.onNoteDeleted,
    required this.onNoteUpdated,
    required this.onRatingChanged,
    required this.onReviewSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover image
          _BookCover(coverUrl: book.coverUrl),
          const SizedBox(height: 16),

          // Title and author
          Text(
            book.title,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Status chip
          PersonalBookStatusChip(status: book.status),
          const SizedBox(height: 16),

          // Description (if available)
          if (book.description != null && book.description!.isNotEmpty) ...[
            Text(
              l10n.personalBookDescriptionLabel,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              book.description!,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          // Started at (if available)
          if (book.startedAt != null) ...[
            Text(
              l10n.personalBookStartedAt,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(book.startedAt!, l10n),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          // Finished at (if available)
          if (book.finishedAt != null) ...[
            Text(
              l10n.personalBookFinishedAt,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(book.finishedAt!, l10n),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          // Rating widget (only visible when status is 'read')
          PersonalRatingWidget(
            status: book.status,
            currentRating: book.rating,
            onRatingChanged: onRatingChanged,
          ),
          const SizedBox(height: 24),

          // Comments field
          PersonalNoteField(
            userId: userId,
            notes: book.notes,
            onAddNote: onNoteAdded,
            onDeleteNote: onNoteDeleted,
            onUpdateNote: onNoteUpdated,
            enabled: true,
          ),
          const SizedBox(height: 24),

          // Review form (only visible when status is 'read')
          PersonalReviewForm(
            book: book,
            onSubmit: onReviewSubmitted,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Widget that displays the book cover image or a placeholder.
class _BookCover extends StatelessWidget {
  final String? coverUrl;

  const _BookCover({this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            coverUrl!,
            width: 150,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _PlaceholderCover(theme: theme),
          ),
        ),
      );
    }

    return _PlaceholderCover(theme: theme);
  }
}

/// Placeholder shown when no cover image is available.
class _PlaceholderCover extends StatelessWidget {
  final ThemeData theme;

  const _PlaceholderCover({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.book,
        size: 64,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Widget shown when the book is not found.
class _BookNotFound extends StatelessWidget {
  final AppLocalizations l10n;

  const _BookNotFound({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.bookNotFound,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
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
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.l10n,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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