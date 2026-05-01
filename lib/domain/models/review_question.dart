import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewQuestion {
  final String id;
  final String question;
  final int order;
  final DateTime createdAt;

  const ReviewQuestion({
    required this.id,
    required this.question,
    required this.order,
    required this.createdAt,
  });

  factory ReviewQuestion.fromMap(Map<String, dynamic> map, String id) {
    return ReviewQuestion(
      id: id,
      question: map['question'] as String,
      order: map['order'] as int,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
