import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:book_club_app/l10n/app_localizations.dart';

import '../../../domain/models/book.dart';
import '../../../domain/models/meeting.dart';
import '../../../domain/models/comment.dart';
import '../../../domain/models/final_review.dart';
import '../../../domain/models/review_question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/rating_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/rating/average_rating_display.dart';
import '../../widgets/rating/book_rating_widget.dart';
import '../../widgets/common/role_guard.dart';
import '../../widgets/common/expandable_phrase_chip.dart';
import '../../widgets/review/final_review_form.dart';
import '../../widgets/comment/comment_form.dart';
import '../../widgets/comment/comment_edit_dialog.dart';
import '../../widgets/comment/sticker_display.dart';
import '../../../domain/models/app_user.dart';
import '../meetings/meeting_screen.dart';

/// Displays full details of a book: cover, title, author, description,
/// status label, meetings list, comments list, and average rating.
/// Requirements 5.2, 5.3, 5.4
class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({required this.bookId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bookAsync = ref.watch(bookStreamProvider(bookId));

    return Scaffold(
      body: bookAsync.when(
        // Task 7.4: loading indicator
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.bookDetailError)),
        data: (book) {
          if (book == null) {
            return Center(child: Text(l10n.bookNotFound));
          }
          return _BookDetailContent(book: book);
        },
      ),
    );
  }
}

class _BookDetailContent extends ConsumerWidget {
  final Book book;

  const _BookDetailContent({required this.book});

  Future<void> _confirmMarkAsRead(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.markAsReadConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final service = ref.read(bookServiceProvider);
      await service.markAsRead(book.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookMarkedAsRead)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookMarkAsReadError)),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteBookConfirm),
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
      final service = ref.read(bookServiceProvider);
      await service.deleteBook(book.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookDeletedSuccess)),
        );
        context.go(AppRoutes.books);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookDeleteError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isRead = book.status == 'read';
    final dateFormat = DateFormat.yMMMd();

    return CustomScrollView(
      slivers: [
        // App bar with cover image
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          // Ensure back button and action icons are always visible (white)
          // against the cover image background. When collapsed, the AppBar
          // uses its surface color so we keep white for consistency.
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            background: book.coverUrl.isNotEmpty
                ? Image.network(
                    book.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _CoverFallback(),
                  )
                : _CoverFallback(),
          ),
          actions: [
            // Leader-only actions
            RoleGuard(
              requiredRole: UserRole.leader,
              child: Row(
                children: [
                  // Mark as read (only if currently reading)
                  if (!isRead)
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      tooltip: l10n.markAsRead,
                      onPressed: () =>
                          _confirmMarkAsRead(context, ref, l10n),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: l10n.editBook,
                    onPressed: () => context.push(
                      AppRoutes.editBookPath(book.id),
                      extra: book,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    tooltip: l10n.deleteBook,
                    onPressed: () => _confirmDelete(context, ref, l10n),
                  ),
                ],
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: _FadeInSection(
            delay: const Duration(milliseconds: 200),
            child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                // Author
                Text(
                  book.author,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),

                // Task 7.3: Status label
                _StatusLabel(isRead: isRead),

                if (isRead && book.finishedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.finishedAt(dateFormat.format(book.finishedAt!)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],

                const SizedBox(height: 16),

                // Average rating (for read books)
                if (isRead) _AverageRatingSection(bookId: book.id),

                const SizedBox(height: 16),

                // User rating widget (Req 8.2, 8.3)
                _UserRatingSection(bookId: book.id, bookStatus: book.status),

                const SizedBox(height: 16),

                // Description
                Text(
                  book.description.isNotEmpty
                      ? book.description
                      : '—',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Meetings section
                _MeetingsSection(bookId: book.id),

                const SizedBox(height: 24),

                // Comments section
                _CommentsSection(bookId: book.id),

                const SizedBox(height: 24),

                // Final review form (only for read books) — Requirement 9.1
                if (isRead) ...[
                  FinalReviewForm(
                    bookId: book.id,
                    reviewQuestionIds: book.reviewQuestionIds,
                  ),
                  const SizedBox(height: 24),
                ],

                // All member reviews (only for read books) — Requirement 9.5
                if (isRead) _AllReviewsSection(book: book),

                const SizedBox(height: 32),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status label widget (Task 7.3)
// ---------------------------------------------------------------------------

/// Shows "Leyendo actualmente" or "Leído" based on book status.
/// Requirements 5.3, 5.4
class _StatusLabel extends StatelessWidget {
  final bool isRead;

  const _StatusLabel({required this.isRead});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRead
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRead ? Icons.check_circle : Icons.menu_book,
            size: 16,
            color: isRead
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            isRead ? l10n.statusRead : l10n.statusReading,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isRead
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Average rating section
// ---------------------------------------------------------------------------

class _AverageRatingSection extends ConsumerWidget {
  final String bookId;

  const _AverageRatingSection({required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(bookAverageRatingProvider(bookId));

    return ratingAsync.when(
      loading: () => const SizedBox(
        height: 24,
        child: Center(child: LinearProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (avg) => AverageRatingDisplayWidget(averageRating: avg),
    );
  }
}

// ---------------------------------------------------------------------------
// Meetings section
// ---------------------------------------------------------------------------

class _MeetingsSection extends ConsumerWidget {
  final String bookId;

  const _MeetingsSection({required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final meetingsAsync = ref.watch(meetingsStreamProvider(bookId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.meetings,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MeetingScreen(bookId: bookId),
                ),
              ),
              child: Text(l10n.meetingScreenTitle),
            ),
          ],
        ),
        const SizedBox(height: 8),
        meetingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (meetings) {
            if (meetings.isEmpty) {
              return Text(
                l10n.noMeetings,
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            // Show up to 3 most recent meetings as a preview
            final preview = meetings.take(3).toList();
            return Column(
              children: preview
                  .map((m) => _MeetingTile(meeting: m))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MeetingTile extends StatelessWidget {
  final Meeting meeting;

  const _MeetingTile({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.groups, size: 20),
        ),
        title: Text(dateFormat.format(meeting.date)),
        subtitle: meeting.notes.isNotEmpty
            ? Text(
                meeting.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comments section
// ---------------------------------------------------------------------------

class _CommentsSection extends ConsumerWidget {
  final String bookId;

  const _CommentsSection({required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final commentsAsync = ref.watch(bookCommentsProvider(bookId));
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final currentUser = currentUserAsync.valueOrNull;

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
                  .map((c) => _CommentTile(
                        comment: c,
                        bookId: bookId,
                        currentUserId: currentUser?.uid ?? '',
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        // Comment input — only shown when user is loaded
        if (currentUser != null)
          CommentForm(
            parentId: bookId,
            isBook: true,
            currentUserId: currentUser.uid,
            currentUserName: currentUser.displayName,
          ),
      ],
    );
  }
}

enum _CommentAction { edit, delete }

class _CommentTile extends ConsumerWidget {
  final Comment comment;
  final String bookId;
  final String currentUserId;

  const _CommentTile({
    required this.comment,
    required this.bookId,
    required this.currentUserId,
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
      await service.deleteBookComment(bookId, comment.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.commentDeleteError),
          ),
        );
      }
    }
  }

  void _openEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => CommentEditDialog(
        comment: comment,
        parentId: bookId,
        isBook: true,
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

// ---------------------------------------------------------------------------
// User rating section (Req 8.2, 8.3)
// ---------------------------------------------------------------------------

/// Shows [BookRatingWidget] for the currently authenticated user.
/// Handles the case where the user is not yet loaded.
class _UserRatingSection extends ConsumerWidget {
  final String bookId;
  final String bookStatus;

  const _UserRatingSection({
    required this.bookId,
    required this.bookStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return BookRatingWidget(
          bookId: bookId,
          bookStatus: bookStatus,
          currentUserId: user.uid,
        );
      },
    );
  }
}

class _CoverFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    // Use onSurfaceVariant explicitly so the icon is always visible
    // against the container background (fixes invisible icon issue).
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      color: color,
      child: Center(
        child: Icon(Icons.book, size: 80, color: iconColor),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All member reviews section (Requirement 9.5)
// ---------------------------------------------------------------------------

class _AllReviewsSection extends ConsumerWidget {
  final Book book;

  const _AllReviewsSection({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reviewsAsync = ref.watch(bookReviewsStreamProvider(book.id));
    final questionsAsync = ref.watch(reviewQuestionsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.allReviewsTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        reviewsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Text(
                l10n.noReviewsYet,
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            return questionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) {
                // Show reviews even if questions fail to load, just without Q&A
                return Column(
                  children: reviews
                      .map((r) => _ReviewCard(
                            review: r,
                            questions: const [],
                          ))
                      .toList(),
                );
              },
              data: (allQuestions) {
                final bookQuestions = allQuestions
                    .where((q) => book.reviewQuestionIds.contains(q.id))
                    .toList()
                  ..sort((a, b) => a.order.compareTo(b.order));

                return Column(
                  children: reviews
                      .map((r) => _ReviewCard(
                            review: r,
                            questions: bookQuestions,
                          ))
                      .toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final FinalReview review;
  final List<ReviewQuestion> questions;

  const _ReviewCard({required this.review, required this.questions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();
    final theme = Theme.of(context);

    // Resolve author info from Firestore
    final userAsync = ref.watch(userByIdProvider(review.authorId));
    final user = userAsync.valueOrNull;

    final displayName = user?.displayName ?? '…';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  dateFormat.format(review.updatedAt),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),

            // Favorite phrases
            if (review.favoritePhrases.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.favoritePhrases,
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
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
            ],

            // Questions and answers
            if (questions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...questions.map((q) {
                final answer = review.answers[q.id] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.question,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        answer.isNotEmpty ? answer : '—',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fade-in section animation
// ---------------------------------------------------------------------------

/// Fades in its [child] after an optional [delay].
/// Used to animate sections of the book detail screen on entry.
class _FadeInSection extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const _FadeInSection({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  State<_FadeInSection> createState() => _FadeInSectionState();
}

class _FadeInSectionState extends State<_FadeInSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
