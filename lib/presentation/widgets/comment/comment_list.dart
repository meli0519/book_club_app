import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/comment.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/comment_provider.dart';
import 'comment_form.dart';
import 'comment_edit_dialog.dart';
import 'sticker_display.dart';

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
              children: comments
                  .map((c) => CommentTile(
                        comment: c,
                        parentId: parentId,
                        isBook: isBook,
                        currentUserId: currentUserId,
                      ))
                  .toList(),
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

/// A single comment tile showing author, date, text and edit/delete actions
/// for the comment's own author.
class CommentTile extends ConsumerWidget {
  final Comment comment;
  final String parentId;
  final bool isBook;
  final String currentUserId;

  const CommentTile({
    required this.comment,
    required this.parentId,
    required this.isBook,
    required this.currentUserId,
    super.key,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCommentConfirm),
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
      final service = ref.read(commentServiceProvider);
      if (isBook) {
        await service.deleteBookComment(parentId, comment.id);
      } else {
        await service.deleteMeetingComment(parentId, comment.id);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commentDeleteError)),
        );
      }
    }
  }

  void _openEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => CommentEditDialog(
        comment: comment,
        parentId: parentId,
        isBook: isBook,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat.yMMMd();
    final isOwner = comment.authorId == currentUserId;

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
                if (isOwner) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<_CommentAction>(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    onSelected: (action) {
                      if (action == _CommentAction.edit) {
                        _openEditDialog(context);
                      } else {
                        _confirmDelete(context, ref);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: _CommentAction.edit,
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(ctx)!.editComment),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _CommentAction.delete,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 18,
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(ctx)!.deleteComment,
                              style: TextStyle(
                                color: Theme.of(ctx).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.text),
            if (comment.stickers.isNotEmpty) ...[
              const SizedBox(height: 6),
              StickerDisplay(stickers: comment.stickers),
            ],
          ],
        ),
      ),
    );
  }
}

enum _CommentAction { edit, delete }
