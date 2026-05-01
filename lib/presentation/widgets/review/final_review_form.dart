import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/final_review.dart';
import '../../../domain/models/review_question.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../common/expandable_phrase_chip.dart';

/// Form for submitting a FinalReview.
/// - Shows the form when the user has not yet submitted a review.
/// - Shows a read-only summary once submitted (one review per user per book).
/// - Requires at least one favorite phrase and all questions answered.
/// Requirement 9.1, 9.3, 9.4
class FinalReviewForm extends ConsumerWidget {
  final String bookId;
  final List<String> reviewQuestionIds;

  const FinalReviewForm({
    required this.bookId,
    required this.reviewQuestionIds,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final questionsAsync = ref.watch(reviewQuestionsStreamProvider);

    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return questionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (allQuestions) {
            final questions = allQuestions
                .where((q) => reviewQuestionIds.contains(q.id))
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));

            final existingAsync = ref.watch(
              userBookReviewProvider('$bookId|${user.uid}'),
            );

            return existingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (existing) {
                // Already submitted → show read-only summary
                if (existing != null) {
                  return _ReviewSubmittedSummary(
                    review: existing,
                    questions: questions,
                  );
                }

                // Not yet submitted → show the form
                return _ReviewFormBody(
                  bookId: bookId,
                  questions: questions,
                  authorId: user.uid,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Read-only summary shown after the review is submitted
// ---------------------------------------------------------------------------

class _ReviewSubmittedSummary extends StatelessWidget {
  final FinalReview review;
  final List<ReviewQuestion> questions;

  const _ReviewSubmittedSummary({
    required this.review,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with checkmark
            Row(
              children: [
                Icon(Icons.check_circle,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.reviewSubmittedSuccess,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Favorite phrases
            if (review.favoritePhrases.isNotEmpty) ...[
              Text(l10n.favoritePhrases,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: review.favoritePhrases
                    .map((p) => ExpandablePhraseChip(
                          phrase: p,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Q&A
            ...questions.map((q) {
              final answer = review.answers[q.id] ?? '—';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.question,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(answer, style: theme.textTheme.bodySmall),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editable form body (shown only when no review exists yet)
// ---------------------------------------------------------------------------

class _ReviewFormBody extends ConsumerStatefulWidget {
  final String bookId;
  final List<ReviewQuestion> questions;
  final String authorId;

  const _ReviewFormBody({
    required this.bookId,
    required this.questions,
    required this.authorId,
  });

  @override
  ConsumerState<_ReviewFormBody> createState() => _ReviewFormBodyState();
}

class _ReviewFormBodyState extends ConsumerState<_ReviewFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _phraseController = TextEditingController();
  final List<String> _favoritePhrases = [];
  late final Map<String, TextEditingController> _answerControllers;
  bool _isSaving = false;
  bool _showPhraseError = false;

  @override
  void initState() {
    super.initState();
    _answerControllers = {
      for (final q in widget.questions)
        q.id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    _phraseController.dispose();
    for (final c in _answerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPhrase() {
    final text = _phraseController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _favoritePhrases.add(text);
      _phraseController.clear();
      _showPhraseError = false;
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;

    // Require at least one favorite phrase
    if (_favoritePhrases.isEmpty) {
      setState(() => _showPhraseError = true);
      return;
    }

    // Validate all question answers
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final answers = <String, String>{
        for (final q in widget.questions)
          q.id: _answerControllers[q.id]!.text.trim(),
      };

      final review = FinalReview(
        authorId: widget.authorId,
        favoritePhrases: List<String>.from(_favoritePhrases),
        answers: answers,
        updatedAt: DateTime.now(),
      );

      final service = ref.read(reviewServiceProvider);
      await service.upsertFinalReview(widget.bookId, review);

      // Invalidate so the parent switches to the summary view
      ref.invalidate(
          userBookReviewProvider('${widget.bookId}|${widget.authorId}'));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reviewSubmittedSuccess)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.reviewSubmitError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // No questions configured for this book
    if (widget.questions.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.noReviewQuestionsConfigured,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.finalReviewTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ── Favorite phrases (at least one required) ─────────────────
              Text(l10n.favoritePhrases,
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                l10n.favoritePhraseRequired,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phraseController,
                      decoration: InputDecoration(
                        hintText: l10n.favoritePhrasesHint,
                        border: const OutlineInputBorder(),
                        errorText: _showPhraseError
                            ? l10n.favoritePhraseRequiredError
                            : null,
                      ),
                      onSubmitted: (_) => _addPhrase(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ElevatedButton(
                      onPressed: _addPhrase,
                      child: Text(l10n.addPhrase),
                    ),
                  ),
                ],
              ),
              if (_favoritePhrases.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _favoritePhrases
                      .map(
                        (phrase) => ExpandablePhraseChip(
                          phrase: phrase,
                          onDeleted: () => setState(
                              () => _favoritePhrases.remove(phrase)),
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 16),

              // ── Questions (all required) ──────────────────────────────────
              ...widget.questions.map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _answerControllers[q.id],
                      decoration: InputDecoration(
                        labelText: q.question,
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.fieldRequired;
                        }
                        return null;
                      },
                    ),
                  )),

              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.submitReview),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
