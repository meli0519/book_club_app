import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/rating.dart';
import '../../domain/models/rating_with_user.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upserts a rating for a book (one per author).
  /// Requirement 8.2
  Future<void> upsertBookRating(String bookId, Rating rating) async {
    try {
      await _firestore
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .doc(rating.authorId)
          .set(rating.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Error upserting book rating: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error upserting book rating: $e');
    }
  }

  /// Upserts a rating for a meeting (one per author).
  /// Requirement 8.1
  Future<void> upsertMeetingRating(String meetingId, Rating rating) async {
    try {
      await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('ratings')
          .doc(rating.authorId)
          .set(rating.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Error upserting meeting rating: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error upserting meeting rating: $e');
    }
  }

  /// Returns the average rating for a book, rounded to 1 decimal.
  /// Requirement 8.4
  Future<double?> getBookAverageRating(String bookId) async {
    try {
      final snapshot = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .get();
      if (snapshot.docs.isEmpty) return null;
      final values = snapshot.docs
          .map((doc) => (doc.data()['value'] as num).toDouble())
          .toList();
      final avg = values.reduce((a, b) => a + b) / values.length;
      // Round to 1 decimal
      return (avg * 10).round() / 10;
    } on FirebaseException catch (e) {
      throw Exception('Error getting book average rating: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting book average rating: $e');
    }
  }

  /// Returns a stream of the average rating for a book, rounded to 1 decimal.
  Stream<double?> watchBookAverageRating(String bookId) {
    try {
      return _firestore
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        final values = snapshot.docs
            .map((doc) => (doc.data()['value'] as num).toDouble())
            .toList();
        final avg = values.reduce((a, b) => a + b) / values.length;
        return (avg * 10).round() / 10;
      });
    } on FirebaseException catch (e) {
      throw Exception('Error watching book average rating: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching book average rating: $e');
    }
  }

  /// Returns the average rating for a meeting, rounded to 1 decimal.
  /// Requirement 8.4
  Future<double?> getMeetingAverageRating(String meetingId) async {
    try {
      final snapshot = await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('ratings')
          .get();
      if (snapshot.docs.isEmpty) return null;
      final values = snapshot.docs
          .map((doc) => (doc.data()['value'] as num).toDouble())
          .toList();
      final avg = values.reduce((a, b) => a + b) / values.length;
      return (avg * 10).round() / 10;
    } on FirebaseException catch (e) {
      throw Exception('Error getting meeting average rating: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting meeting average rating: $e');
    }
  }

  /// Returns the current user's rating for a book, or null if not rated.
  Future<int?> getUserBookRating(String bookId, String userId) async {
    try {
      final doc = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return (doc.data()!['value'] as num).toInt();
    } on FirebaseException catch (e) {
      throw Exception('Error getting user book rating: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting user book rating: $e');
    }
  }

  /// Returns the current user's full Rating for a book, or null if not rated.
  Future<Rating?> getUserBookRatingFull(String bookId, String userId) async {
    try {
      final doc = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return Rating.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Error getting user book rating: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting user book rating: $e');
    }
  }

  /// Returns the current user's rating for a meeting, or null if not rated.
  Future<int?> getUserMeetingRating(String meetingId, String userId) async {
    try {
      final doc = await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('ratings')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return (doc.data()!['value'] as num).toInt();
    } on FirebaseException catch (e) {
      throw Exception('Error getting user meeting rating: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting user meeting rating: $e');
    }
  }

  /// Returns the current user's full Rating for a meeting, or null if not rated.
  Future<Rating?> getUserMeetingRatingFull(
      String meetingId, String userId) async {
    try {
      final doc = await _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('ratings')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return Rating.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Error getting user meeting rating: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting user meeting rating: $e');
    }
  }

  /// Returns a stream of all ratings for a meeting, enriched with user display names.
  /// Requirement 24.1, 24.2
  Stream<List<RatingWithUser>> watchMeetingRatingsWithUsers(
      String meetingId) {
    return _firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('ratings')
        .snapshots()
        .asyncMap((snapshot) async {
      final results = <RatingWithUser>[];
      for (final doc in snapshot.docs) {
        final authorId = doc.data()['authorId'] as String? ?? doc.id;
        final value = (doc.data()['value'] as num?)?.toInt() ?? 0;
        final comment = doc.data()['comment'] as String?;

        // Fetch display name, photo and email from users collection.
        String authorName = authorId;
        String authorPhotoUrl = '';
        String authorEmail = '';
        try {
          final userDoc =
              await _firestore.collection('users').doc(authorId).get();
          if (userDoc.exists) {
            authorName =
                (userDoc.data()?['displayName'] as String?) ?? authorId;
            authorPhotoUrl =
                (userDoc.data()?['photoUrl'] as String?) ?? '';
            authorEmail =
                (userDoc.data()?['email'] as String?) ?? '';
          }
        } catch (_) {
          // Fall back to authorId if user lookup fails.
        }

        results.add(RatingWithUser(
          authorId: authorId,
          authorName: authorName,
          authorPhotoUrl: authorPhotoUrl,
          authorEmail: authorEmail,
          value: value,
          comment: comment,
        ));
      }
      return results;
    });
  }

  /// Returns a stream of the average rating for a meeting, rounded to 1 decimal.
  Stream<double?> watchMeetingAverageRating(String meetingId) {
    try {
      return _firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('ratings')
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        final values = snapshot.docs
            .map((doc) => (doc.data()['value'] as num).toDouble())
            .toList();
        final avg = values.reduce((a, b) => a + b) / values.length;
        return (avg * 10).round() / 10;
      });
    } on FirebaseException catch (e) {
      throw Exception('Error watching meeting average rating: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching meeting average rating: $e');
    }
  }
}
