import 'package:cloud_firestore/cloud_firestore.dart';

import 'book.dart';

/// Constants for personal book categories (user-level, not club-level).
class UserBookCategory {
  static const wantToRead = 'wantToRead';
  static const reading = 'reading';
  static const read = 'read';

  static const all = [wantToRead, reading, read];

  UserBookCategory._();
}

/// Represents a user's personal categorization of a book.
/// Stored in Firestore at: users/{userId}/library/{bookId}
class UserBookEntry {
  final String userId;
  final String bookId;
  final String category; // UserBookCategory constant
  final DateTime updatedAt;

  const UserBookEntry({
    required this.userId,
    required this.bookId,
    required this.category,
    required this.updatedAt,
  });

  factory UserBookEntry.fromMap(
    Map<String, dynamic> map,
    String bookId,
    String userId,
  ) {
    return UserBookEntry(
      userId: userId,
      bookId: bookId,
      category: map['category'] as String? ?? UserBookCategory.wantToRead,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Combines a [UserBookEntry] with the full [Book] data and its average rating.
/// Used by the library screen to display cover, title, author, and rating.
class UserBookWithDetails {
  final UserBookEntry entry;
  final Book book;
  final double? averageRating;

  const UserBookWithDetails({
    required this.entry,
    required this.book,
    this.averageRating,
  });
}
