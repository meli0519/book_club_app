// Feature: book-club-app
// Property 8: Listado de libros siempre ordenado por createdAt descendente
// Validates: Requirements 5.1

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/book.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a book document in Firestore and returns its ID.
Future<String> _createBook(
  FakeFirebaseFirestore fakeFirestore, {
  required String title,
  required String author,
  required DateTime createdAt,
}) async {
  final docRef = fakeFirestore.collection('books').doc();
  await docRef.set({
    'title': title,
    'author': author,
    'description': 'Description',
    'coverUrl': 'https://example.com/cover.jpg',
    'status': 'reading',
    'createdBy': 'user_1',
    'createdAt': Timestamp.fromDate(createdAt),
    'reviewQuestionIds': [],
  });
  return docRef.id;
}

/// Fetches books from Firestore ordered by createdAt descending (mirrors BookService.watchBooks).
Future<List<Book>> _fetchBooksDescending(
  FakeFirebaseFirestore fakeFirestore,
) async {
  final snapshot = await fakeFirestore
      .collection('books')
      .orderBy('createdAt', descending: true)
      .get();
  return snapshot.docs
      .map((doc) => Book.fromMap(doc.data(), doc.id))
      .toList();
}

// ---------------------------------------------------------------------------
// Test data generators
// ---------------------------------------------------------------------------

/// Generates a list of N distinct DateTime values spread across a date range.
List<DateTime> _generateDates(int count, DateTime base) {
  return List.generate(count, (i) => base.add(Duration(hours: i * 13)));
}

/// Generates shuffled dates to simulate out-of-order insertion.
List<DateTime> _shuffleDates(List<DateTime> dates) {
  final shuffled = List<DateTime>.from(dates);
  // Simple deterministic shuffle using index swaps
  for (int i = shuffled.length - 1; i > 0; i--) {
    final j = (i * 7 + 3) % (i + 1);
    final tmp = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = tmp;
  }
  return shuffled;
}

// ---------------------------------------------------------------------------
// P8: Listado de libros siempre ordenado por createdAt descendente
// ---------------------------------------------------------------------------

void main() {
  group(
    'P8: Book list is always ordered by createdAt descending',
    () {
      test(
        'for any collection of books, the list is sorted createdAt desc (2 books)',
        () async {
          final base = DateTime(2024, 1, 1);
          final dates = _generateDates(2, base);

          for (int trial = 0; trial < 20; trial++) {
            final fakeFirestore = FakeFirebaseFirestore();
            final shuffled = _shuffleDates(dates);

            for (int i = 0; i < shuffled.length; i++) {
              await _createBook(
                fakeFirestore,
                title: 'Book $i (trial $trial)',
                author: 'Author $i',
                createdAt: shuffled[i],
              );
            }

            final books = await _fetchBooksDescending(fakeFirestore);

            expect(books.length, equals(2));
            // For every adjacent pair (a, b): a.createdAt >= b.createdAt
            for (int i = 0; i < books.length - 1; i++) {
              expect(
                books[i].createdAt.isAfter(books[i + 1].createdAt) ||
                    books[i]
                        .createdAt
                        .isAtSameMomentAs(books[i + 1].createdAt),
                isTrue,
                reason:
                    'books[$i].createdAt (${books[i].createdAt}) must be >= '
                    'books[${i + 1}].createdAt (${books[i + 1].createdAt})',
              );
            }
          }
        },
      );

      test(
        'for any collection of books, the list is sorted createdAt desc (5 books)',
        () async {
          final base = DateTime(2024, 3, 1);
          final dates = _generateDates(5, base);

          for (int trial = 0; trial < 20; trial++) {
            final fakeFirestore = FakeFirebaseFirestore();
            final shuffled = _shuffleDates(dates);

            for (int i = 0; i < shuffled.length; i++) {
              await _createBook(
                fakeFirestore,
                title: 'Book $i (trial $trial)',
                author: 'Author $i',
                createdAt: shuffled[i],
              );
            }

            final books = await _fetchBooksDescending(fakeFirestore);

            expect(books.length, equals(5));
            for (int i = 0; i < books.length - 1; i++) {
              expect(
                books[i].createdAt.isAfter(books[i + 1].createdAt) ||
                    books[i]
                        .createdAt
                        .isAtSameMomentAs(books[i + 1].createdAt),
                isTrue,
                reason:
                    'books[$i].createdAt must be >= books[${i + 1}].createdAt '
                    '(trial=$trial)',
              );
            }
          }
        },
      );

      test(
        'for any collection of books, the list is sorted createdAt desc (10 books)',
        () async {
          final base = DateTime(2024, 6, 1);
          final dates = _generateDates(10, base);

          for (int trial = 0; trial < 20; trial++) {
            final fakeFirestore = FakeFirebaseFirestore();
            final shuffled = _shuffleDates(dates);

            for (int i = 0; i < shuffled.length; i++) {
              await _createBook(
                fakeFirestore,
                title: 'Book $i (trial $trial)',
                author: 'Author $i',
                createdAt: shuffled[i],
              );
            }

            final books = await _fetchBooksDescending(fakeFirestore);

            expect(books.length, equals(10));
            for (int i = 0; i < books.length - 1; i++) {
              expect(
                books[i].createdAt.isAfter(books[i + 1].createdAt) ||
                    books[i]
                        .createdAt
                        .isAtSameMomentAs(books[i + 1].createdAt),
                isTrue,
                reason:
                    'books[$i].createdAt must be >= books[${i + 1}].createdAt '
                    '(trial=$trial)',
              );
            }
          }
        },
      );

      test(
        'for any collection of books, the list is sorted createdAt desc (50 books)',
        () async {
          final base = DateTime(2023, 1, 1);
          final dates = _generateDates(50, base);

          for (int trial = 0; trial < 5; trial++) {
            final fakeFirestore = FakeFirebaseFirestore();
            final shuffled = _shuffleDates(dates);

            for (int i = 0; i < shuffled.length; i++) {
              await _createBook(
                fakeFirestore,
                title: 'Book $i (trial $trial)',
                author: 'Author $i',
                createdAt: shuffled[i],
              );
            }

            final books = await _fetchBooksDescending(fakeFirestore);

            expect(books.length, equals(50));
            for (int i = 0; i < books.length - 1; i++) {
              expect(
                books[i].createdAt.isAfter(books[i + 1].createdAt) ||
                    books[i]
                        .createdAt
                        .isAtSameMomentAs(books[i + 1].createdAt),
                isTrue,
                reason:
                    'books[$i].createdAt must be >= books[${i + 1}].createdAt '
                    '(trial=$trial)',
              );
            }
          }
        },
      );

      test(
        'empty book collection returns empty list',
        () async {
          final fakeFirestore = FakeFirebaseFirestore();
          final books = await _fetchBooksDescending(fakeFirestore);
          expect(books, isEmpty);
        },
      );

      test(
        'single book collection returns list with one element',
        () async {
          final fakeFirestore = FakeFirebaseFirestore();
          await _createBook(
            fakeFirestore,
            title: 'Only Book',
            author: 'Only Author',
            createdAt: DateTime(2024, 5, 15),
          );
          final books = await _fetchBooksDescending(fakeFirestore);
          expect(books.length, equals(1));
          expect(books.first.title, equals('Only Book'));
        },
      );

      test(
        'books with different dates across months are sorted correctly',
        () async {
          final fakeFirestore = FakeFirebaseFirestore();

          final testDates = [
            DateTime(2024, 12, 1),
            DateTime(2024, 1, 1),
            DateTime(2024, 6, 15),
            DateTime(2023, 11, 30),
            DateTime(2025, 2, 28),
          ];

          for (int i = 0; i < testDates.length; i++) {
            await _createBook(
              fakeFirestore,
              title: 'Book ${testDates[i].year}-${testDates[i].month}',
              author: 'Author $i',
              createdAt: testDates[i],
            );
          }

          final books = await _fetchBooksDescending(fakeFirestore);

          expect(books.length, equals(5));
          // Verify descending order
          for (int i = 0; i < books.length - 1; i++) {
            expect(
              books[i].createdAt.isAfter(books[i + 1].createdAt) ||
                  books[i]
                      .createdAt
                      .isAtSameMomentAs(books[i + 1].createdAt),
              isTrue,
              reason:
                  'books[$i].createdAt (${books[i].createdAt}) must be >= '
                  'books[${i + 1}].createdAt (${books[i + 1].createdAt})',
            );
          }

          // The most recent book (2025-02-28) must be first
          expect(books.first.createdAt.year, equals(2025));
          // The oldest book (2023-11-30) must be last
          expect(books.last.createdAt.year, equals(2023));
        },
      );

      test(
        'Book.fromMap correctly deserializes createdAt for ordering',
        () async {
          final fakeFirestore = FakeFirebaseFirestore();
          final createdAt = DateTime(2024, 7, 4, 12, 30);

          final id = await _createBook(
            fakeFirestore,
            title: 'Test Book',
            author: 'Test Author',
            createdAt: createdAt,
          );

          final doc =
              await fakeFirestore.collection('books').doc(id).get();
          final book = Book.fromMap(doc.data()!, doc.id);

          // createdAt must be deserialized correctly (within 1 second tolerance)
          expect(
            book.createdAt.difference(createdAt).inSeconds.abs(),
            lessThanOrEqualTo(1),
            reason: 'createdAt must be deserialized correctly',
          );
        },
      );
    },
  );
}
