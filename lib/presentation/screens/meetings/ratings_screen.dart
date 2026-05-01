import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/rating_with_user.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/rating_provider.dart';
import '../../widgets/rating/average_rating_display.dart';
import '../../widgets/rating/rating_list_item.dart';

/// Sort options for the ratings list.
/// Requirement 24.3
enum _SortOrder { byScore, byName }

/// Displays all member ratings for a meeting.
/// Shows average at the top, then a sortable list of individual ratings.
/// Requirements 24.1, 24.2, 24.3, 24.4
class RatingsScreen extends ConsumerStatefulWidget {
  final String meetingId;

  const RatingsScreen({required this.meetingId, super.key});

  @override
  ConsumerState<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends ConsumerState<RatingsScreen> {
  _SortOrder _sortOrder = _SortOrder.byScore;

  List<RatingWithUser> _sorted(List<RatingWithUser> ratings) {
    final copy = List<RatingWithUser>.from(ratings);
    switch (_sortOrder) {
      case _SortOrder.byScore:
        copy.sort((a, b) => b.value.compareTo(a.value));
      case _SortOrder.byName:
        copy.sort((a, b) =>
            a.authorName.toLowerCase().compareTo(b.authorName.toLowerCase()));
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratingsAsync =
        ref.watch(meetingRatingsWithUsersProvider(widget.meetingId));
    final averageAsync =
        ref.watch(meetingAverageRatingProvider(widget.meetingId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ratingsScreenTitle),
        actions: [
          PopupMenuButton<_SortOrder>(
            tooltip: _sortOrder == _SortOrder.byScore
                ? l10n.sortByScore
                : l10n.sortByName,
            icon: const Icon(Icons.sort),
            onSelected: (order) => setState(() => _sortOrder = order),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _SortOrder.byScore,
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: _sortOrder == _SortOrder.byScore
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.sortByScore),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _SortOrder.byName,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 18,
                      color: _sortOrder == _SortOrder.byName
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.sortByName),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ratingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.bookDetailError)),
        data: (ratings) {
          if (ratings.isEmpty) {
            return Center(
              child: Text(
                l10n.noRatingsForMeeting,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          final sorted = _sorted(ratings);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Average rating header — Requirement 24.4
              _AverageHeader(averageAsync: averageAsync),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) =>
                      RatingListItem(rating: sorted[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Average header widget
// ---------------------------------------------------------------------------

class _AverageHeader extends ConsumerWidget {
  final AsyncValue<double?> averageAsync;

  const _AverageHeader({required this.averageAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.averageRating,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          averageAsync.when(
            loading: () => const SizedBox(
              height: 20,
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (avg) => AverageRatingDisplayWidget(
              averageRating: avg,
              starSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
