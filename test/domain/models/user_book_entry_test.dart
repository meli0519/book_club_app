// Tests for UserBookEntry and UserBookWithDetails models
// Task 20.5 – Library filtering and visualization

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/book.dart';
import 'package:book_club_app/domain/models/user_book_entry.dart';

void main() {
  // -------------------------------------------------------------------------
  // UserBookCategory
  // -------------------------------------------------------------------------
  group('UserBookCategory', () {
    test('all contains exactly 3 categories', () {
      expect(UserBookCategory.all.length, equals(3));
    });

    test('all contains wantToRead, reading, and read', () {
      expect(UserBookCategory.all, contains(UserBookCategory.wantToRead));
      expect(UserBookCategory.all, contains(UserBookCategory.reading));
      expect(UserBookCategory.all, contains(UserBookCategory.read));
    });
  });

  // -------------------------------------------------------------------------
  // UserBookEntry.fromMap
  // -------------------------------------------------------------------------
  group('UserBookEntry.fromMap', () {
    test('correctly deserializes all fields', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final map = <String, dynamic>{
        'category': UserBookCategory.reading,
        'updatedAt': Timestamp.fromDate(now),
      };

      final entry = UserBookEntry.fromMap(map, 'book_1', 'user_1');

      expect(entry.userId, equals('user_1'));
      expect(entry.bookId, equals('book_1'));
      expect(entry.category, equals(UserBookCategory.reading));
      expect(entry.updatedAt, equals(now));
    });

    test('defaults category to wantToRead when field is missing', () {
      final map = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      final entry = UserBookEntry.fromMap(map, 'book_2', 'user_2');

      expect(entry.category, equals(UserBookCategory.wantToRead));
    });

    test('correctly deserializes wantToRead category', () {
      final map = <String, dynamic>{
        'category': UserBookCategory.wantToRead,
        'updatedAt': Timestamp.fromDate(DateTime(2024, 3, 1)),
      };

      final entry = UserBookEntry.fromMap(map, 'book_3', 'user_3');
      expect(entry.category, equals(UserBookCategory.wantToRead));
    });

    test('correctly deserializes read category', () {
      final map = <String, dynamic>{
        'category': UserBookCategory.read,
        'updatedAt': Timestamp.fromDate(DateTime(2024, 4, 1)),
      };

      final entry = UserBookEntry.fromMap(map, 'book_4', 'user_4');
      expect(entry.category, equals(UserBookCategory.read));
    });
  });

  // -------------------------------------------------------------------------
  // UserBookEntry.toMap
  // -------------------------------------------------------------------------
  group('UserBookEntry.toMap', () {
    test('correctly serializes all fields', () {
      final now = DateTime(2024, 7, 20, 14, 0);
      final entry = UserBookEntry(
        userId: 'user_5',
        bookId: 'book_5',
        category: UserBookCategory.read,
        updatedAt: now,
      );

      final map = entry.toMap();

      expect(map['category'], equals(UserBookCategory.read));
      expect(map['updatedAt'], isA<Timestamp>());
      expect((map['updatedAt'] as Timestamp).toDate(), equals(now));
    });

    test('toMap does not include userId or bookId', () {
      final entry = UserBookEntry(
        userId: 'user_6',
        bookId: 'book_6',
        category: UserBookCategory.reading,
        updatedAt: DateTime(2024, 1, 1),
      );

      final map = entry.toMap();

      expect(map.containsKey('userId'), isFalse);
      expect(map.containsKey('bookId'), isFalse);
    });

    test('roundtrip fromMap → toMap preserves category and updatedAt', () {
      final now = DateTime(2024, 8, 10, 9, 0);
      final original = UserBookEntry(
        userId: 'user_7',
        bookId: 'book_7',
        category: UserBookCategory.reading,
        updatedAt: now,
      );

      final map = original.toMap();
      final restored = UserBookEntry.fromMap(map, 'book_7', 'user_7');

      expect(restored.category, equals(original.category));
      expect(restored.updatedAt, equals(original.updatedAt));
      expect(restored.userId, equals(original.userId));
      expect(restored.bookId, equals(original.bookId));
    });
  });

  // -------------------------------------------------------------------------
  // UserBookWithDetails
  // -------------------------------------------------------------------------
  group('UserBookWithDetails', () {
    Book _makeBook(String id) => Book(
          id: id,
          title: 'Test Book $id',
          author: 'Test Author',
          description: 'A description',
          coverUrl: 'https://example.com/cover.jpg',
          status: 'reading',
          createdBy: 'user_1',
          createdAt: DateTime(2024, 1, 1),
        );

    UserBookEntry _makeEntry(String bookId, String category) => UserBookEntry(
          userId: 'user_1',
          bookId: bookId,
          category: category,
          updatedAt: DateTime(2024, 6, 1),
        );

    test('holds entry, book, and optional averageRating', () {
      final entry = _makeEntry('b1', UserBookCategory.reading);
      final book = _makeBook('b1');

      final item = UserBookWithDetails(
        entry: entry,
        book: book,
        averageRating: 4.5,
      );

      expect(item.entry, equals(entry));
      expect(item.book, equals(book));
      expect(item.averageRating, equals(4.5));
    });

    test('averageRating defaults to null', () {
      final item = UserBookWithDetails(
        entry: _makeEntry('b2', UserBookCategory.wantToRead),
        book: _makeBook('b2'),
      );

      expect(item.averageRating, isNull);
    });
  });
}
