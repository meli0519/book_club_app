import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/review_question.dart';

/// Service for CRUD operations on the global `reviewQuestions` collection.
/// Requirement 9.6
class ReviewQuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _collection = 'reviewQuestions';

  /// Returns a real-time stream of all review questions ordered by [order].
  Stream<List<ReviewQuestion>> watchReviewQuestions() {
    try {
      return _firestore
          .collection(_collection)
          .orderBy('order')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ReviewQuestion.fromMap(doc.data(), doc.id))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw Exception('Error watching review questions: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching review questions: $e');
    }
  }

  /// Returns a single review question by [questionId], or null if not found.
  Future<ReviewQuestion?> getReviewQuestion(String questionId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(questionId).get();
      if (!doc.exists) return null;
      return ReviewQuestion.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Error getting review question: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting review question: $e');
    }
  }

  /// Creates a new review question and returns its generated ID.
  Future<String> createReviewQuestion(ReviewQuestion question) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'question': question.question,
        'order': question.order,
        'createdAt': Timestamp.fromDate(question.createdAt),
      });
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Error creating review question: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error creating review question: $e');
    }
  }

  /// Updates only the provided [fields] of the review question with [questionId].
  Future<void> updateReviewQuestion(
    String questionId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _firestore.collection(_collection).doc(questionId).update(fields);
    } on FirebaseException catch (e) {
      throw Exception('Error updating review question: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating review question: $e');
    }
  }

  /// Deletes the review question with [questionId].
  Future<void> deleteReviewQuestion(String questionId) async {
    try {
      await _firestore.collection(_collection).doc(questionId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Error deleting review question: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error deleting review question: $e');
    }
  }
}
