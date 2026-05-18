import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/rating_service.dart';
import '../../domain/models/rating.dart';
import '../../domain/models/rating_with_user.dart';

final ratingServiceProvider =
    Provider<RatingService>((ref) => RatingService());

/// Stream of the average rating for a given book (null if no ratings).
final bookAverageRatingProvider =
    StreamProvider.family<double?, String>((ref, bookId) {
  final service = ref.watch(ratingServiceProvider);
  return service.watchBookAverageRating(bookId);
});

/// Stream of the average rating for a given meeting (null if no ratings).
final meetingAverageRatingProvider =
    StreamProvider.family<double?, String>((ref, meetingId) {
  final service = ref.watch(ratingServiceProvider);
  return service.watchMeetingAverageRating(meetingId);
});

/// Provider for the current user's rating on a book.
/// Family param: (bookId, userId) encoded as "$bookId|$userId"
final userBookRatingProvider =
    FutureProvider.family<double?, String>((ref, key) {
  final parts = key.split('|');
  final bookId = parts[0];
  final userId = parts[1];
  final service = ref.watch(ratingServiceProvider);
  return service.getUserBookRating(bookId, userId);
});

/// Provider for the current user's rating on a meeting.
/// Family param: (meetingId, userId) encoded as "$meetingId|$userId"
final userMeetingRatingProvider =
    FutureProvider.family<double?, String>((ref, key) {
  final parts = key.split('|');
  final meetingId = parts[0];
  final userId = parts[1];
  final service = ref.watch(ratingServiceProvider);
  return service.getUserMeetingRating(meetingId, userId);
});

/// Provider for the current user's full Rating (including comment) on a meeting.
/// Family param: (meetingId, userId) encoded as "$meetingId|$userId"
final userMeetingRatingFullProvider =
    FutureProvider.family<Rating?, String>((ref, key) {
  final parts = key.split('|');
  final meetingId = parts[0];
  final userId = parts[1];
  final service = ref.watch(ratingServiceProvider);
  return service.getUserMeetingRatingFull(meetingId, userId);
});

/// Stream of all ratings with user info for a given meeting.
/// Used by [RatingsScreen] to display per-member ratings.
/// Requirement 24.1, 24.2
final meetingRatingsWithUsersProvider =
    StreamProvider.family<List<RatingWithUser>, String>((ref, meetingId) {
  final service = ref.watch(ratingServiceProvider);
  return service.watchMeetingRatingsWithUsers(meetingId);
});
