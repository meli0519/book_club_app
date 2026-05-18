import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/app_user.dart';
import '../../../domain/models/meeting.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/rating_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/role_guard.dart';
import '../../widgets/rating/average_rating_display.dart';
import '../../widgets/rating/meeting_rating_widget.dart';
import 'create_edit_meeting_screen.dart';

/// Displays all meetings for a book, ordered by date ascending.
/// Requirement 6.5
class MeetingScreen extends ConsumerWidget {
  final String bookId;

  const MeetingScreen({required this.bookId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final meetingsAsync = ref.watch(meetingsStreamProvider(bookId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.meetingScreenTitle),
        actions: [
          // Leaders can add meetings
          RoleGuard(
            requiredRole: UserRole.leader,
            child: IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.addMeeting,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CreateEditMeetingScreen(bookId: bookId),
                ),
              ),
            ),
          ),
        ],
      ),
      body: meetingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(l10n.bookDetailError),
        ),
        data: (meetings) {
          if (meetings.isEmpty) {
            return Center(
              child: Text(
                l10n.noMeetings,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            itemBuilder: (context, index) =>
                _MeetingCard(meeting: meetings[index], bookId: bookId),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meeting card
// ---------------------------------------------------------------------------

class _MeetingCard extends ConsumerWidget {
  final Meeting meeting;
  final String bookId;

  const _MeetingCard({required this.meeting, required this.bookId});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteMeetingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final service = ref.read(meetingServiceProvider);
      await service.deleteMeeting(meeting.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.meetingDeletedSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.meetingDeleteError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Date
                Expanded(
                  child: Text(
                    dateFormat.format(meeting.date),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                // Leader-only actions
                RoleGuard(
                  requiredRole: UserRole.leader,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: l10n.editMeeting,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateEditMeetingScreen(
                              bookId: bookId,
                              meeting: meeting,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        tooltip: l10n.deleteMeeting,
                        onPressed: () =>
                            _confirmDelete(context, ref, l10n),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (meeting.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                meeting.notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            _MeetingAverageRating(meetingId: meeting.id),
            const SizedBox(height: 4),
            _ViewAllRatingsButton(bookId: bookId, meetingId: meeting.id),
            const SizedBox(height: 8),
            _MeetingRatingSection(meetingId: meeting.id),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// View all ratings button
// ---------------------------------------------------------------------------

class _ViewAllRatingsButton extends StatelessWidget {
  final String bookId;
  final String meetingId;

  const _ViewAllRatingsButton({
    required this.bookId,
    required this.meetingId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        icon: const Icon(Icons.people_outline, size: 16),
        label: Text(l10n.viewAllRatings),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        onPressed: () =>
            context.push(AppRoutes.meetingRatings(bookId, meetingId)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meeting average rating widget
// ---------------------------------------------------------------------------

/// Shows the average rating for a meeting using [AverageRatingDisplayWidget].
/// Watches [meetingAverageRatingProvider] and handles loading/error states.
/// Requirement 8.4
class _MeetingAverageRating extends ConsumerWidget {
  final String meetingId;

  const _MeetingAverageRating({required this.meetingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(meetingAverageRatingProvider(meetingId));

    return ratingAsync.when(
      loading: () => const SizedBox(
        height: 20,
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (avg) => AverageRatingDisplayWidget(averageRating: avg),
    );
  }
}

// ---------------------------------------------------------------------------
// Meeting rating section (per-member rating)
// ---------------------------------------------------------------------------

/// Shows the [MeetingRatingWidget] for the currently authenticated user.
/// Requirement 8.1
class _MeetingRatingSection extends ConsumerWidget {
  final String meetingId;

  const _MeetingRatingSection({required this.meetingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final currentUser = authAsync.valueOrNull;
    if (currentUser == null) return const SizedBox.shrink();

    return MeetingRatingWidget(
      meetingId: meetingId,
      currentUserId: currentUser.uid,
    );
  }
}
