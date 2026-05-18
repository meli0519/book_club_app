import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/personal_book.dart';
import '../../../domain/models/personal_book_review.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/review_provider.dart';
import '../common/expandable_phrase_chip.dart';

/// Form for submitting a review for a personal book.
///
/// - Shows the form when the book status is 'read' and no review exists yet.
/// - Shows a read-only summary once submitted.
/// - Requires at least one favorite phrase.
/// - Allows user to select which review questions to answer.
class PersonalReviewForm extends ConsumerStatefulWidget {
  final PersonalBook book;
  final Future<void> Function(PersonalBookReview review) onSubmit;

  const PersonalReviewForm({
    required this.book,
    required this.onSubmit,
    super.key,
  });

  @override
  ConsumerState<PersonalReviewForm> createState() => _PersonalReviewFormState();
}

class _PersonalReviewFormState extends ConsumerState<PersonalReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _phraseController = TextEditingController();
  final _thoughtsController = TextEditingController();
  final List<String> _favoritePhrases = [];
  bool _isSaving = false;
  bool _showPhraseError = false;

  // Review question answers (questions are pre-selected in the book)
  final Map<String, TextEditingController> _questionControllers = {};

  @override
  void initState() {
    super.initState();

    // If review already exists, populate the form
    if (widget.book.review != null) {
      _favoritePhrases.addAll(widget.book.review!.favoritePhrases);
      _thoughtsController.text = widget.book.review!.thoughts ?? '';
      
      // Initialize controllers for existing question answers
      for (final questionId in widget.book.reviewQuestionIds) {
        _questionControllers[questionId] = TextEditingController(
          text: widget.book.review!.questionAnswers[questionId] ?? '',
        );
      }
    } else {
      // Initialize empty controllers for the book's selected questions
      for (final questionId in widget.book.reviewQuestionIds) {
        _questionControllers[questionId] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _phraseController.dispose();
    _thoughtsController.dispose();
    for (final controller in _questionControllers.values) {
      controller.dispose();
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

    setState(() => _isSaving = true);
    try {
      final review = PersonalBookReview(
        favoritePhrases: List<String>.from(_favoritePhrases),
        thoughts: _thoughtsController.text.trim().isEmpty
            ? null
            : _thoughtsController.text.trim(),
        selectedQuestionIds: List<String>.from(widget.book.reviewQuestionIds),
        questionAnswers: Map<String, String>.fromEntries(
          widget.book.reviewQuestionIds.map((id) => MapEntry(id, _questionControllers[id]?.text ?? '')),
        ),
        createdAt: DateTime.now(),
      );

      await widget.onSubmit(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personalBookReviewSubmittedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.personalBookReviewSubmitError)),
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

    // Only show for books with status 'read'
    if (widget.book.status != PersonalBookStatus.read) {
      return const SizedBox.shrink();
    }

    // If review already exists, show read-only summary
    if (widget.book.review != null) {
      return _ReviewSummary(
        review: widget.book.review!,
        questionIds: widget.book.reviewQuestionIds,
      );
    }

    // Show editable form
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
                l10n.personalBookReviewTitle,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ── Answer review questions ──────────────────────────────────
              if (widget.book.reviewQuestionIds.isNotEmpty) ...[
                _buildQuestionAnswersSection(l10n, theme),
                const SizedBox(height: 16),
              ],

              // ── Favorite phrases (at least one required) ─────────────────
              Text(l10n.favoritePhrases, style: theme.textTheme.labelLarge),
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
                          onDeleted: () =>
                              setState(() => _favoritePhrases.remove(phrase)),
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 16),

              // ── Thoughts (optional free-form text) ────────────────────────
              TextFormField(
                controller: _thoughtsController,
                decoration: InputDecoration(
                  labelText: l10n.personalBookReviewThoughtsLabel,
                  hintText: l10n.personalBookReviewThoughtsHint,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: 2000,
              ),

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

  Widget _buildQuestionAnswersSection(AppLocalizations l10n, ThemeData theme) {
    final questionsAsync = ref.watch(allReviewQuestionsStreamProvider);

    return questionsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (allQuestions) {
        // Filter to only show questions selected for this book
        final selectedQuestions = allQuestions
            .where((q) => widget.book.reviewQuestionIds.contains(q.id))
            .toList();

        if (selectedQuestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reviewQuestionsForBook,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final question in selectedQuestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _questionControllers[question.id],
                  decoration: InputDecoration(
                    labelText: question.question,
                    hintText: l10n.answerPlaceholder,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Read-only summary shown after the review is submitted.
class _ReviewSummary extends ConsumerWidget {
  final PersonalBookReview review;
  final List<String> questionIds;

  const _ReviewSummary({
    required this.review,
    required this.questionIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final questionsAsync = ref.watch(allReviewQuestionsStreamProvider);

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
                  l10n.personalBookReviewSubmittedSuccess,
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
              ...review.favoritePhrases.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ExpandablePhraseChip(
                    phrase: p,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Thoughts
            if (review.thoughts != null && review.thoughts!.isNotEmpty) ...[
              Text(
                l10n.personalBookReviewThoughtsLabel,
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                review.thoughts!,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],

            // Question answers with actual question text
            if (review.questionAnswers.isNotEmpty)
              questionsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (allQuestions) {
                  // Build a lookup map: id -> question text
                  final questionMap = {
                    for (final q in allQuestions) q.id: q.question,
                  };

                  // Show only the questions that belong to this review, in order
                  final answeredQuestions = questionIds
                      .where((id) =>
                          review.questionAnswers.containsKey(id) &&
                          (review.questionAnswers[id]?.isNotEmpty ?? false))
                      .toList();

                  if (answeredQuestions.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: answeredQuestions.map((id) {
                      final questionText = questionMap[id] ?? id;
                      final answer = review.questionAnswers[id]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              questionText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              answer,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
