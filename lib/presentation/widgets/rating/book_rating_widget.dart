import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

import '../../../domain/models/rating.dart';
import '../../providers/rating_provider.dart';
import 'star_rating_selector.dart';

/// Widget that handles rating a Book.
/// - If [bookStatus] == 'reading': shows informative message (Req 8.3)
/// - If [bookStatus] == 'read': shows star selector and submits rating (Req 8.2)
class BookRatingWidget extends ConsumerStatefulWidget {
  final String bookId;
  final String bookStatus;
  final String currentUserId;

  const BookRatingWidget({
    required this.bookId,
    required this.bookStatus,
    required this.currentUserId,
    super.key,
  });

  @override
  ConsumerState<BookRatingWidget> createState() => _BookRatingWidgetState();
}

class _BookRatingWidgetState extends ConsumerState<BookRatingWidget> {
  bool _isSubmitting = false;

  Future<void> _handleRatingSelected(int value) async {
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(ratingServiceProvider);
      await service.upsertBookRating(
        widget.bookId,
        Rating(authorId: widget.currentUserId, value: value),
      );
      // Invalidate so the provider re-fetches the updated rating
      ref.invalidate(
          userBookRatingProvider('${widget.bookId}|${widget.currentUserId}'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.bookStatus == 'reading') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.ratingOnlyForReadBooks,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.secondary),
        ),
      );
    }

    final userRatingAsync = ref.watch(
        userBookRatingProvider('${widget.bookId}|${widget.currentUserId}'));

    return userRatingAsync.when(
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text(e.toString()),
      data: (currentRating) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.rateThisBook,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            if (_isSubmitting)
              const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              StarRatingSelectorWidget(
                currentRating: currentRating ?? 0,
                onRatingSelected: _handleRatingSelected,
              ),
          ],
        );
      },
    );
  }
}
