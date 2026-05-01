import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverUrl;
  final String status; // 'reading' | 'read'
  final String createdBy;
  final DateTime createdAt;
  final DateTime? finishedAt;
  final List<String> reviewQuestionIds; // IDs de las preguntas de reseña

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverUrl,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.finishedAt,
    this.reviewQuestionIds = const [],
  });

  factory Book.fromMap(Map<String, dynamic> map, String id) {
    try {
      return Book(
        id: id,
        title: map['title'] as String? ?? '',
        author: map['author'] as String? ?? '',
        description: map['description'] as String? ?? '',
        coverUrl: map['coverUrl'] as String? ?? '',
        status: map['status'] as String? ?? 'reading',
        createdBy: map['createdBy'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        finishedAt: map['finishedAt'] != null
            ? (map['finishedAt'] as Timestamp).toDate()
            : null,
        reviewQuestionIds: map['reviewQuestionIds'] != null
            ? List<String>.from(map['reviewQuestionIds'] as List)
            : [],
      );
    } catch (e) {
      throw Exception('Error parsing Book from map: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'coverUrl': coverUrl,
      'status': status,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (finishedAt != null) 'finishedAt': Timestamp.fromDate(finishedAt!),
      'reviewQuestionIds': reviewQuestionIds,
    };
  }
}
