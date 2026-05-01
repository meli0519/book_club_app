import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/comment_service.dart';
import '../../domain/models/comment.dart';
import 'auth_provider.dart';

final commentServiceProvider =
    Provider<CommentService>((ref) => CommentService());

/// Stream of comments for a given book.
final bookCommentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, bookId) {
  final membershipAsync = ref.watch(membershipStatusProvider);
  final membershipState = membershipAsync.valueOrNull;

  if (membershipState == null ||
      membershipState.status != MembershipStatus.active) {
    return const Stream.empty();
  }

  final service = ref.watch(commentServiceProvider);
  return service.watchBookComments(bookId);
});

/// Stream of comments for a given meeting.
final meetingCommentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, meetingId) {
  final membershipAsync = ref.watch(membershipStatusProvider);
  final membershipState = membershipAsync.valueOrNull;

  if (membershipState == null ||
      membershipState.status != MembershipStatus.active) {
    return const Stream.empty();
  }

  final service = ref.watch(commentServiceProvider);
  return service.watchMeetingComments(meetingId);
});
