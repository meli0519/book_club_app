import '../models/comment.dart';

/// Abstract interface for comment operations on books and meetings.
/// Requirements 7.1, 7.2, 7.4
abstract class CommentRepository {
  /// Returns a real-time stream of comments for a book subcollection.
  /// Requirement 7.1, 7.4
  Stream<List<Comment>> watchBookComments(String bookId);

  /// Returns a real-time stream of comments for a meeting subcollection.
  /// Requirement 7.2, 7.4
  Stream<List<Comment>> watchMeetingComments(String meetingId);

  /// Adds a comment to `books/{bookId}/comments`.
  /// Requirement 7.1
  Future<void> addBookComment(String bookId, Comment comment);

  /// Adds a comment to `meetings/{meetingId}/comments`.
  /// Requirement 7.2
  Future<void> addMeetingComment(String meetingId, Comment comment);
}
