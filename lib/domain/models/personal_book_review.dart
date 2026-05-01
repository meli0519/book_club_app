import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a review for a personal book.
///
/// Unlike club book reviews (FinalReview), personal book reviews are simpler
/// and stored directly in the PersonalBook document as a nested field.
/// They include favorite phrases, free-form thoughts, and selected review questions.
class PersonalBookReview {
  final List<String> favoritePhrases;
  final String? thoughts; // Free-form text about the book
  final List<String> selectedQuestionIds; // IDs of selected review questions
  final Map<String, String> questionAnswers; // questionId -> answer
  final DateTime createdAt;

  const PersonalBookReview({
    required this.favoritePhrases,
    this.thoughts,
    this.selectedQuestionIds = const [],
    this.questionAnswers = const {},
    required this.createdAt,
  });

  factory PersonalBookReview.fromMap(Map<String, dynamic> map) {
    try {
      return PersonalBookReview(
        favoritePhrases: List<String>.from(map['favoritePhrases'] as List? ?? []),
        thoughts: map['thoughts'] as String?,
        selectedQuestionIds: List<String>.from(map['selectedQuestionIds'] as List? ?? []),
        questionAnswers: Map<String, String>.from(map['questionAnswers'] as Map? ?? {}),
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error parsing PersonalBookReview from map: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'favoritePhrases': favoritePhrases,
      if (thoughts != null) 'thoughts': thoughts,
      'selectedQuestionIds': selectedQuestionIds,
      'questionAnswers': questionAnswers,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
