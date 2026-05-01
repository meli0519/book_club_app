import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/comment.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/comment_provider.dart';
import 'comment_form.dart';

/// Displays a real-time list of comments for a book or meeting.
/// Requirement 7.4 – updates without manual reload via stream.
class CommentList extends ConsumerWidget {
  /// The parent entity id (bookId or meetingId).
  final String parentId;

  /// Whether this is for a book (true) or meeting (false).
  final bool isBook;

  /// The current user's id (for submitting comments).
  final String currentUserId;

  /// The current user's display name (for submitting comments).
  final String currentUserName;

  const CommentList({
    required this.parentId,
    required this.isBook,
    required this.currentUserId,
    required this.currentUserName,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final commentsAsync = isBook
        ? ref.watch(bookCommentsProvider(parentId))
        : ref.watch(meetingCommentsProvider(parentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.comments,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        commentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (comments) {
            if (comments.isEmpty) {
              return Text(
                l10n.noComments,
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            return Column(
              children: comments.map((c) => CommentTile(comment: c)).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        CommentForm(
          parentId: parentId,
          isBook: isBook,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
        ),
      ],
    );
  }
}

/// A single comment tile showing author, date and text.
class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({required this.comment, super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comment.authorName,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  dateFormat.format(comment.createdAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.text),
          ],
        ),
      ),
    );
  }
}
