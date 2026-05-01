import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/review_question_service.dart';
import '../../data/services/review_service.dart';
import '../../domain/models/final_review.dart';
import '../../domain/models/review_question.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// ReviewQuestionService providers
// ---------------------------------------------------------------------------

final reviewQuestionServiceProvider =
    Provider<ReviewQuestionService>((ref) => ReviewQuestionService());

/// Stream of all review questions ordered by [order].
/// Guarded by active membership — used in member-facing screens.
final reviewQuestionsStreamProvider =
    StreamProvider<List<ReviewQuestion>>((ref) {
  final membershipAsync = ref.watch(membershipStatusProvider);
  final membershipState = membershipAsync.valueOrNull;

  if (membershipState == null ||
      membershipState.status != MembershipStatus.active) {
    return const Stream.empty();
  }

  final service = ref.watch(reviewQuestionServiceProvider);
  return service.watchReviewQuestions();
});

/// Stream of all review questions without a membership guard.
/// Used in leader-only admin screens (book creation/editing, question management)
/// where the router already enforces the leader role.
final allReviewQuestionsStreamProvider =
    StreamProvider<List<ReviewQuestion>>((ref) {
  final service = ref.watch(reviewQuestionServiceProvider);
  return service.watchReviewQuestions();
});

// ---------------------------------------------------------------------------
// ReviewService providers
// ---------------------------------------------------------------------------

final reviewServiceProvider =
    Provider<ReviewService>((ref) => ReviewService());

/// Stream of all FinalReviews for a given book.
final bookReviewsStreamProvider =
    StreamProvider.family<List<FinalReview>, String>((ref, bookId) {
  final membershipAsync = ref.watch(membershipStatusProvider);
  final membershipState = membershipAsync.valueOrNull;

  if (membershipState == null ||
      membershipState.status != MembershipStatus.active) {
    return const Stream.empty();
  }

  final service = ref.watch(reviewServiceProvider);
  return service.watchBookReviews(bookId);
});

/// Future provider for the current user's review on a book.
/// Family param: "$bookId|$authorId"
final userBookReviewProvider =
    FutureProvider.family<FinalReview?, String>((ref, key) async {
  final parts = key.split('|');
  final bookId = parts[0];
  final authorId = parts[1];
  final service = ref.watch(reviewServiceProvider);
  return service.getUserReview(bookId, authorId);
});
