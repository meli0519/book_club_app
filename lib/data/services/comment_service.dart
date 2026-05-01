import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/comment.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns a real-time stream of comments for a book.
  /// Requirement 7.1, 7.4
  Stream<List<Comment>> watchBookComments(String bookId) {
    try {
      return _firestore
          .collection('books')
          .doc(bookId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Comment.fromMap(doc.data(), doc.id))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw Exception('Error watching book comments: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching book comments: $e');
    }
  }

  /// Returns a real-time stream of comments for a meeting.
  /// Requirement 7.2, 7.4
  Stream<List<Comment>> watchMeetingComments(String meetingId) {
    try {
      return _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Comment.fromMap(doc.data(), doc.id))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw Exception('Error watching meeting comments: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching meeting comments: $e');
    }
  }

  /// Adds a comment to a book's subcollection.
  Future<void> addBookComment(String bookId, Comment comment) async {
    try {
      await _firestore
          .collection('books')
          .doc(bookId)
          .collection('comments')
          .add({
        ...comment.toMap(),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception('Error adding book comment: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error adding book comment: $e');
    }
  }

  /// Adds a comment to a meeting's subcollection.
  Future<void> addMeetingComment(String meetingId, Comment comment) async {
    try {
      await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('comments')
          .add({
        ...comment.toMap(),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception('Error adding meeting comment: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error adding meeting comment: $e');
    }
  }
}
