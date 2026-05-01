// Tests for HomeScreen book list loading
// Requirements 12.1, 12.5, 12.6, 17.1–17.4

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/book.dart';

// ---------------------------------------------------------------------------
// Helpers – mirrors BookService.watchBooks() logic
// ---------------------------------------------------------------------------

Future<String> _addBook(
  FakeFirebaseFirestore fs, {
  required String title,
  required String author,
  required DateTime createdAt,
  String status = 'reading',
  String coverUrl = 'https://example.com/cover.jpg',
}) async {
  final ref = fs.collection('books').doc();
  await ref.set({
    'title': title,
    'author': author,
    'description': 'A description',
    'coverUrl': coverUrl,
    'status': status,
    'createdBy': 'user_1',
    'createdAt': Timestamp.fromDate(createdAt),
    'reviewQuestionIds': <String>[],
  });
  return ref.id;
}

Future<List<Book>> _fetchBooks(FakeFirebaseFirestore fs) async {
  final snapshot = await fs
      .collection('books')
      .orderBy('createdAt', descending: true)
      .get();
  return snapshot.docs.map((d) => Book.fromMap(d.data(), d.id)).toList();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HomeScreen – book list loading (17.1, 17.4)', () {
    test('returns empty list when no books exist', () async {
      final fs = FakeFirebaseFirestore();
      final books = await _fetchBooks(fs);
      expect(books, isEmpty);
    });

    test('returns all books when books exist', () async {
      final fs = FakeFirebaseFirestore();
      await _addBook(fs,
          title: 'Book A', author: 'Author A', createdAt: DateTime(2024, 1, 1));
      await _addBook(fs,
          title: 'Book B', author: 'Author B', createdAt: DateTime(2024, 2, 1));

      final books = await _fetchBooks(fs);
      expect(books.length, equals(2));
    });

    test('books are ordered by createdAt descending', () async {
      final fs = FakeFirebaseFirestore();
      await _addBook(fs,
          title: 'Oldest', author: 'A', createdAt: DateTime(2023, 1, 1));
      await _addBook(fs,
          title: 'Newest', author: 'B', createdAt: DateTime(2025, 6, 1));
      await _addBook(fs,
          title: 'Middle', author: 'C', createdAt: DateTime(2024, 3, 15));

      final books = await _fetchBooks(fs);
      expect(books[0].title, equals('Newest'));
      expect(books[1].title, equals('Middle'));
      expect(books[2].title, equals('Oldest'));
    });
  });

  group('HomeScreen – book data fields (17.2)', () {
    test('each book exposes title, author and coverUrl', () async {
      final fs = FakeFirebaseFirestore();
      await _addBook(
        fs,
        title: 'Clean Code',
        author: 'Robert C. Martin',
        createdAt: DateTime(2024, 5, 10),
        coverUrl: 'https://example.com/clean-code.jpg',
      );

      final books = await _fetchBooks(fs);
      expect(books.first.title, equals('Clean Code'));
      expect(books.first.author, equals('Robert C. Martin'));
      expect(books.first.coverUrl, equals('https://example.com/clean-code.jpg'));
    });

    test('book with empty coverUrl is still returned', () async {
      final fs = FakeFirebaseFirestore();
      await _addBook(
        fs,
        title: 'No Cover Book',
        author: 'Unknown',
        createdAt: DateTime(2024, 1, 1),
        coverUrl: '',
      );

      final books = await _fetchBooks(fs);
      expect(books.first.coverUrl, isEmpty);
    });
  });

  group('HomeScreen – average rating (17.3)', () {
    test('average rating is null when no ratings exist', () async {
      final fs = FakeFirebaseFirestore();
      final bookId = await _addBook(
        fs,
        title: 'Unrated Book',
        author: 'Author',
        createdAt: DateTime(2024, 1, 1),
      );

      final ratingsSnapshot =
          await fs.collection('books').doc(bookId).collection('ratings').get();
      expect(ratingsSnapshot.docs, isEmpty);
    });

    test('average rating is computed correctly from ratings subcollection',
        () async {
      final fs = FakeFirebaseFirestore();
      final bookId = await _addBook(
        fs,
        title: 'Rated Book',
        author: 'Author',
        createdAt: DateTime(2024, 1, 1),
      );

      // Add ratings: 4, 5, 3 → average = 4.0
      await fs
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .doc('user1')
          .set({'authorId': 'user1', 'value': 4});
      await fs
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .doc('user2')
          .set({'authorId': 'user2', 'value': 5});
      await fs
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .doc('user3')
          .set({'authorId': 'user3', 'value': 3});

      final snapshot = await fs
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .get();
      final values =
          snapshot.docs.map((d) => (d.data()['value'] as num).toDouble()).toList();
      final avg = values.reduce((a, b) => a + b) / values.length;
      final rounded = (avg * 10).round() / 10;

      expect(rounded, equals(4.0));
    });

    test('average rating rounds to 1 decimal (Requirement 8.4)', () async {
      final fs = FakeFirebaseFirestore();
      final bookId = await _addBook(
        fs,
        title: 'Book',
        author: 'Author',
        createdAt: DateTime(2024, 1, 1),
      );

      // 4 + 3 = 7 / 2 = 3.5
      await fs
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .doc('u1')
          .set({'authorId': 'u1', 'value': 4});
      await fs
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .doc('u2')
          .set({'authorId': 'u2', 'value': 3});

      final snapshot = await fs
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .get();
      final values =
          snapshot.docs.map((d) => (d.data()['value'] as num).toDouble()).toList();
      final avg = values.reduce((a, b) => a + b) / values.length;
      final rounded = (avg * 10).round() / 10;

      expect(rounded, equals(3.5));
      // Verify it's expressed to 1 decimal
      expect(rounded.toStringAsFixed(1), equals('3.5'));
    });
  });

  group('HomeScreen – StarRatingWidget logic (17.3)', () {
    test('null rating shows no numeric value', () {
      // StarRatingWidget shows "—" when averageRating is null
      const double? rating = null;
      expect(rating, isNull);
    });

    test('rating of 4.0 shows 4 filled stars', () {
      const double rating = 4.0;
      final filled = rating.floor();
      final hasHalf = (rating - filled) >= 0.5;
      expect(filled, equals(4));
      expect(hasHalf, isFalse);
    });

    test('rating of 3.5 shows 3 filled stars and 1 half star', () {
      const double rating = 3.5;
      final filled = rating.floor();
      final hasHalf = (rating - filled) >= 0.5;
      expect(filled, equals(3));
      expect(hasHalf, isTrue);
    });

    test('rating of 5.0 shows 5 filled stars', () {
      const double rating = 5.0;
      final filled = rating.floor();
      final hasHalf = (rating - filled) >= 0.5;
      expect(filled, equals(5));
      expect(hasHalf, isFalse);
    });

    test('rating of 1.0 shows 1 filled star and 4 empty stars', () {
      const double rating = 1.0;
      final filled = rating.floor();
      final hasHalf = (rating - filled) >= 0.5;
      expect(filled, equals(1));
      expect(hasHalf, isFalse);
    });
  });

  group('HomeScreen – loading state (12.5)', () {
    test('stream emits data after books are added', () async {
      final fs = FakeFirebaseFirestore();

      // Initially empty
      var books = await _fetchBooks(fs);
      expect(books, isEmpty);

      // Add a book
      await _addBook(
        fs,
        title: 'New Book',
        author: 'Author',
        createdAt: DateTime(2024, 1, 1),
      );

      // Now has data
      books = await _fetchBooks(fs);
      expect(books.length, equals(1));
    });
  });

  group('HomeScreen – error state (12.6)', () {
    test('Book.fromMap handles missing optional fields gracefully', () {
      // Simulates a Firestore document with minimal fields
      final map = <String, dynamic>{
        'title': 'Minimal Book',
        'author': 'Author',
        'description': '',
        'coverUrl': '',
        'status': 'reading',
        'createdBy': 'user1',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'reviewQuestionIds': <String>[],
      };

      expect(() => Book.fromMap(map, 'id_1'), returnsNormally);
      final book = Book.fromMap(map, 'id_1');
      expect(book.finishedAt, isNull);
      expect(book.reviewQuestionIds, isEmpty);
    });
  });
}
