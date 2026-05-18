/// A [Rating] enriched with the author's display name, photo and email.
/// Used by [RatingsScreen] to show per-member ratings.
class RatingWithUser {
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String authorEmail;
  final double value; // 0.5–5.0 in 0.5 increments
  final String? comment;

  const RatingWithUser({
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.authorEmail,
    required this.value,
    this.comment,
  });
}
