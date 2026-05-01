import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/final_review.dart';

/// Service for upsert and watch operations on `books/{bookId}/reviews`.
/// Requirements 9.3, 9.4
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upserts a [FinalReview] for [bookId].
  /// Uses the review's [authorId] as the document ID, guaranteeing exactly
  /// one review per author per book (Requirement 9.4).
  Future<void> upsertFinalReview(String bookId, FinalReview review) async {
    try {
      await _firestore
          .collection('books')
          .doc(bookId)
          .collection('reviews')
          .doc(review.authorId)
          .set({
        'authorId': review.authorId,
        'favoritePhrases': review.favoritePhrases,
        'answers': review.answers,
        'updatedAt': Timestamp.fromDate(review.updatedAt),
      });
    } on FirebaseException catch (e) {
      throw Exception('Error upserting final review: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error upserting final review: $e');
    }
  }

  /// Returns a real-time stream of all [FinalReview]s for [bookId].
  /// Requirement 9.5
  Stream<List<FinalReview>> watchBookReviews(String bookId) {
    try {
      return _firestore
          .collection('books')
          .doc(bookId)
          .collection('reviews')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => FinalReview.fromMap(doc.data(), doc.id))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw Exception('Error watching book reviews: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching book reviews: $e');
    }
  }

  /// Returns the [FinalReview] for [authorId] in [bookId], or null if none.
  Future<FinalReview?> getUserReview(String bookId, String authorId) async {
    try {
      final doc = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('reviews')
          .doc(authorId)
          .get();
      if (!doc.exists) return null;
      return FinalReview.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Error getting user review: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting user review: $e');
    }
  }
}
