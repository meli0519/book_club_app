import 'package:cloud_firestore/cloud_firestore.dart';

import 'personal_book_review.dart';
import 'personal_note.dart';

/// Status constants for a [PersonalBook].
class PersonalBookStatus {
  static const wantToRead = 'want_to_read';
  static const reading = 'reading';
  static const read = 'read';

  static const all = [wantToRead, reading, read];

  PersonalBookStatus._();
}

/// Represents a personal book entry in a user's private reading list.
///
/// Stored in Firestore at `users/{uid}/personal_books/{bookId}`.
/// Completely private — only the owning user can read or write it.
class PersonalBook {
  final String id;
  final String userId;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;

  /// One of [PersonalBookStatus] constants: `want_to_read`, `reading`, `read`.
  final String status;

  /// Personal notes written by the user, ordered from newest to oldest.
  final List<PersonalNote> notes;

  /// Rating from 0.5 to 5.0 in 0.5 increments. Only meaningful when [status] == `read`.
  final double? rating;

  /// Review with favorite phrases and thoughts. Only meaningful when [status] == `read`.
  final PersonalBookReview? review;

  /// IDs of the review questions selected for this book.
  final List<String> reviewQuestionIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the user transitions the book to `reading` status (only once).
  final DateTime? startedAt;

  /// Set when the user transitions the book to `read` status.
  final DateTime? finishedAt;

  const PersonalBook({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    required this.status,
    this.notes = const [],
    this.rating,
    this.review,
    this.reviewQuestionIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.finishedAt,
  });

  factory PersonalBook.fromMap(
    Map<String, dynamic> map,
    String id,
    String userId,
  ) {
    try {
      return PersonalBook(
        id: id,
        userId: userId,
        title: map['title'] as String? ?? '',
        author: map['author'] as String? ?? '',
        description: map['description'] as String?,
        coverUrl: map['coverUrl'] as String?,
        status: map['status'] as String? ?? PersonalBookStatus.wantToRead,
        notes: _parseNotes(map['notes']),
        rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
        review: map['review'] != null
            ? PersonalBookReview.fromMap(map['review'] as Map<String, dynamic>)
            : null,
        reviewQuestionIds: map['reviewQuestionIds'] != null
            ? List<String>.from(map['reviewQuestionIds'] as List)
            : [],
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? (map['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        startedAt: map['startedAt'] != null
            ? (map['startedAt'] as Timestamp).toDate()
            : null,
        finishedAt: map['finishedAt'] != null
            ? (map['finishedAt'] as Timestamp).toDate()
            : null,
      );
    } catch (e) {
      throw Exception('Error parsing PersonalBook from map: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'author': author,
      if (description != null) 'description': description,
      if (coverUrl != null) 'coverUrl': coverUrl,
      'status': status,
      if (notes.isNotEmpty) 'notes': notes.map((n) => n.toMap()).toList(),
      if (rating != null) 'rating': rating,
      if (review != null) 'review': review!.toMap(),
      'reviewQuestionIds': reviewQuestionIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
      if (finishedAt != null) 'finishedAt': Timestamp.fromDate(finishedAt!),
    };
  }
}

/// Parses the [notes] field from Firestore, handling legacy formats:
/// - null → empty list
/// - String (old format) → single PersonalNote with that text
/// - List<Map> (new format) → list of PersonalNote
List<PersonalNote> _parseNotes(dynamic raw) {
  if (raw == null) return [];
  // Legacy: notes was stored as a plain String
  if (raw is String) {
    if (raw.isEmpty) return [];
    return [PersonalNote(text: raw, createdAt: DateTime.now())];
  }
  // New format: list of maps
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((n) => PersonalNote.fromMap(Map<String, dynamic>.from(n)))
        .toList();
  }
  return [];
}
