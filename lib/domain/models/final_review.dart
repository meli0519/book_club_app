import 'package:cloud_firestore/cloud_firestore.dart';

class FinalReview {
  final String authorId;
  final List<String> favoritePhrases;
  final Map<String, String> answers; // questionId -> answer
  final DateTime updatedAt;

  const FinalReview({
    required this.authorId,
    required this.favoritePhrases,
    required this.answers,
    required this.updatedAt,
  });

  factory FinalReview.fromMap(Map<String, dynamic> map, String id) {
    return FinalReview(
      authorId: map['authorId'] as String,
      favoritePhrases: List<String>.from(map['favoritePhrases'] as List),
      answers: Map<String, String>.from(map['answers'] as Map),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'favoritePhrases': favoritePhrases,
      'answers': answers,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
