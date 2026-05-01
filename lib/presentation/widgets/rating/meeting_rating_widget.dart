import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

import '../../../domain/models/rating.dart';
import '../../providers/rating_provider.dart';
import 'star_rating_selector.dart';

/// Widget that handles rating a Meeting with an optional comment.
/// Shows a read-only summary of the user's existing rating (Req 23.4),
/// and allows editing it. No status restriction — any member can rate. (Req 8.1)
class MeetingRatingWidget extends ConsumerStatefulWidget {
  final String meetingId;
  final String currentUserId;

  const MeetingRatingWidget({
    required this.meetingId,
    required this.currentUserId,
    super.key,
  });

  @override
  ConsumerState<MeetingRatingWidget> createState() =>
      _MeetingRatingWidgetState();
}

class _MeetingRatingWidgetState extends ConsumerState<MeetingRatingWidget> {
  bool _isSubmitting = false;
  bool _isEditing = false;
  final _commentController = TextEditingController();
  int? _selectedRating;
  bool _initialized = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _providerKey =>
      '${widget.meetingId}|${widget.currentUserId}';

  void _initFromExisting(Rating? existing) {
    if (_initialized) return;
    _initialized = true;
    if (existing != null) {
      _selectedRating = existing.value;
      _commentController.text = existing.comment ?? '';
    }
  }

  Future<void> _submit(int value) async {
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(ratingServiceProvider);
      final comment = _commentController.text.trim();
      await service.upsertMeetingRating(
        widget.meetingId,
        Rating(
          authorId: widget.currentUserId,
          value: value,
          comment: comment.isNotEmpty ? comment : null,
        ),
      );
      setState(() {
        _selectedRating = value;
        _isEditing = false;
      });
      ref.invalidate(userMeetingRatingProvider(_providerKey));
      ref.invalidate(userMeetingRatingFullProvider(_providerKey));
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

  Future<void> _saveComment() async {
    final rating = _selectedRating;
    if (rating == null) return;
    await _submit(rating);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final userRatingAsync =
        ref.watch(userMeetingRatingFullProvider(_providerKey));

    return userRatingAsync.when(
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text(e.toString()),
      data: (existingRating) {
        _initFromExisting(existingRating);

        final hasRating = existingRating != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Read-only summary (shown when user has already rated) ──────
            if (hasRating && !_isEditing) ...[
              _CurrentRatingSummary(
                rating: existingRating,
                l10n: l10n,
                onEditTap: () => setState(() => _isEditing = true),
              ),
            ] else ...[
              // ── Edit / new rating controls ────────────────────────────────
              Text(
                l10n.rateThisMeeting,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (_isSubmitting)
                const SizedBox(
                  height: 40,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                StarRatingSelectorWidget(
                  currentRating: _selectedRating ?? 0,
                  onRatingSelected: (v) => setState(() => _selectedRating = v),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: l10n.ratingCommentLabel,
                  hintText: l10n.ratingCommentHint,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasRating) ...[
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() => _isEditing = false),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: (_isSubmitting || _selectedRating == null)
                        ? null
                        : _saveComment,
                    child: Text(l10n.saveRatingComment),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Read-only summary of the user's current rating
// ---------------------------------------------------------------------------

class _CurrentRatingSummary extends StatelessWidget {
  final Rating rating;
  final AppLocalizations l10n;
  final VoidCallback onEditTap;

  const _CurrentRatingSummary({
    required this.rating,
    required this.l10n,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filledColor = theme.colorScheme.primary;
    final emptyColor = theme.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: label + stars + score
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.yourRating,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(width: 8),
              ...List.generate(5, (i) {
                final filled = (i + 1) <= rating.value;
                return Icon(
                  filled ? Icons.star : Icons.star_border,
                  size: 20,
                  color: filled ? filledColor : emptyColor,
                );
              }),
              const SizedBox(width: 6),
              Text(
                l10n.yourRatingValue(rating.value),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // Row 2: edit button aligned to the right
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEditTap,
              icon: const Icon(Icons.edit, size: 16),
              label: Text(l10n.editRating),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.yourRatingComment,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rating.comment!,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
