import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/comment.dart';

class CommentService {
  final FirebaseFirestore _firestore;

  CommentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
  /// Requirements 8.1, 8.2, 8.3, 8.4
  Future<void> addBookComment(String bookId, Comment comment) async {
    if (comment.stickers.length > 5) {
      throw Exception('Máximo 5 stickers permitidos');
    }
    // Stickers are user-uploaded URLs — no catalog validation needed.

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
  /// Requirements 8.1, 8.2, 8.3, 8.4
  Future<void> addMeetingComment(String meetingId, Comment comment) async {
    if (comment.stickers.length > 5) {
      throw Exception('Máximo 5 stickers permitidos');
    }
    // Stickers are user-uploaded URLs — no catalog validation needed.

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

  /// Updates the text and stickers of an existing book comment.
  /// Only the comment author should call this.
  Future<void> updateBookComment(
    String bookId,
    String commentId,
    String newText,
    List<String> newStickers,
  ) async {
    if (newText.isEmpty || newText.length > 1000) {
      throw Exception('El comentario debe tener entre 1 y 1000 caracteres');
    }
    if (newStickers.length > 5) {
      throw Exception('Máximo 5 stickers permitidos');
    }
    try {
      await _firestore
          .collection('books')
          .doc(bookId)
          .collection('comments')
          .doc(commentId)
          .update({
        'text': newText,
        'stickers': newStickers,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception('Error updating book comment: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating book comment: $e');
    }
  }

  /// Deletes a book comment by its id.
  /// Only the comment author or a leader should call this.
  Future<void> deleteBookComment(String bookId, String commentId) async {
    try {
      await _firestore
          .collection('books')
          .doc(bookId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception('Error deleting book comment: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error deleting book comment: $e');
    }
  }

  /// Updates the text and stickers of an existing meeting comment.
  /// Only the comment author should call this.
  Future<void> updateMeetingComment(
    String meetingId,
    String commentId,
    String newText,
    List<String> newStickers,
  ) async {
    if (newText.isEmpty || newText.length > 1000) {
      throw Exception('El comentario debe tener entre 1 y 1000 caracteres');
    }
    if (newStickers.length > 5) {
      throw Exception('Máximo 5 stickers permitidos');
    }
    try {
      await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('comments')
          .doc(commentId)
          .update({
        'text': newText,
        'stickers': newStickers,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception('Error updating meeting comment: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating meeting comment: $e');
    }
  }

  /// Deletes a meeting comment by its id.
  /// Only the comment author or a leader should call this.
  Future<void> deleteMeetingComment(String meetingId, String commentId) async {
    try {
      await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception('Error deleting meeting comment: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error deleting meeting comment: $e');
    }
  }
}
