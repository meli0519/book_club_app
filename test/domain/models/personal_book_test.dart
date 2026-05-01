// Feature: personal-books
// Property 2: Creación de Personal_Book preserva todos los campos requeridos
// Task 1.1 – Round-trip fromMap/toMap property test for PersonalBook
//
// Validates: Requirements 2.1

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glados/glados.dart';

import 'package:book_club_app/domain/models/personal_book.dart';

// ---------------------------------------------------------------------------
// Custom Arbitrary generators for PersonalBook fields
// ---------------------------------------------------------------------------

extension AnyPersonalBook on Any {
  /// Generates a complete valid PersonalBook with all fields populated.
  Generator<PersonalBook> get personalBook => (random, size) {
        final id = 'book_${random.nextInt(100000)}';
        final userId = 'user_${random.nextInt(100000)}';

        // Required string fields: use a fixed set of valid values
        final titles = [
          'Don Quijote',
          'Cien años de soledad',
          '1984',
          'The Great Gatsby',
          'Brave New World',
          'El nombre de la rosa',
          'Ficciones',
          'Pedro Páramo',
          'La sombra del viento',
          'Harry Potter',
        ];
        final authors = [
          'Miguel de Cervantes',
          'Gabriel García Márquez',
          'George Orwell',
          'F. Scott Fitzgerald',
          'Aldous Huxley',
          'Umberto Eco',
          'Jorge Luis Borges',
          'Juan Rulfo',
          'Carlos Ruiz Zafón',
          'J.K. Rowling',
        ];
        final descriptions = [
          null,
          'Una novela clásica.',
          'A timeless masterpiece.',
          'Highly recommended.',
          'A gripping story.',
        ];
        final notesList = [
          null,
          'Great read!',
          'Loved the ending.',
          'Slow start but worth it.',
          'Would recommend to friends.',
        ];
        final coverUrls = [
          null,
          'https://example.com/cover1.jpg',
          'https://example.com/cover2.jpg',
          'https://storage.googleapis.com/personal_books/uid/bookId/cover',
        ];

        final statusIndex = random.nextInt(PersonalBookStatus.all.length);
        final status = PersonalBookStatus.all[statusIndex];

        // rating is only valid when status == 'read'
        int? rating;
        if (status == PersonalBookStatus.read) {
          final ratingOptions = [null, 1, 2, 3, 4, 5];
          rating = ratingOptions[random.nextInt(ratingOptions.length)];
        }

        // Timestamps: truncate to milliseconds to match Firestore precision.
        // Use days as the unit to stay within nextInt's 2^32 limit.
        final baseDays = DateTime(2020).millisecondsSinceEpoch ~/ 86400000;
        const rangeDays = 365 * 5; // 5 years

        DateTime randomDate() {
          final days = baseDays + random.nextInt(rangeDays);
          return DateTime.fromMillisecondsSinceEpoch(days * 86400000);
        }

        final createdAt = randomDate();
        final updatedAt = randomDate();

        DateTime? startedAt;
        DateTime? finishedAt;
        if (status == PersonalBookStatus.reading ||
            status == PersonalBookStatus.read) {
          if (random.nextBool()) startedAt = randomDate();
        }
        if (status == PersonalBookStatus.read) {
          if (random.nextBool()) finishedAt = randomDate();
        }

        final book = PersonalBook(
          id: id,
          userId: userId,
          title: titles[random.nextInt(titles.length)],
          author: authors[random.nextInt(authors.length)],
          description: descriptions[random.nextInt(descriptions.length)],
          coverUrl: coverUrls[random.nextInt(coverUrls.length)],
          status: status,
          notes: notesList[random.nextInt(notesList.length)],
          rating: rating,
          createdAt: createdAt,
          updatedAt: updatedAt,
          startedAt: startedAt,
          finishedAt: finishedAt,
        );

        return Shrinkable(book, () => []);
      };
}

// ---------------------------------------------------------------------------
// Helper: compare two PersonalBook instances field by field
// (PersonalBook does not implement == / hashCode)
// ---------------------------------------------------------------------------

void expectPersonalBooksEqual(PersonalBook actual, PersonalBook expected) {
  expect(actual.id, equals(expected.id), reason: 'id must be preserved');
  expect(actual.userId, equals(expected.userId),
      reason: 'userId must be preserved');
  expect(actual.title, equals(expected.title),
      reason: 'title must be preserved');
  expect(actual.author, equals(expected.author),
      reason: 'author must be preserved');
  expect(actual.description, equals(expected.description),
      reason: 'description must be preserved');
  expect(actual.coverUrl, equals(expected.coverUrl),
      reason: 'coverUrl must be preserved');
  expect(actual.status, equals(expected.status),
      reason: 'status must be preserved');
  expect(actual.notes, equals(expected.notes),
      reason: 'notes must be preserved');
  expect(actual.rating, equals(expected.rating),
      reason: 'rating must be preserved');
  expect(actual.createdAt, equals(expected.createdAt),
      reason: 'createdAt must be preserved');
  expect(actual.updatedAt, equals(expected.updatedAt),
      reason: 'updatedAt must be preserved');
  expect(actual.startedAt, equals(expected.startedAt),
      reason: 'startedAt must be preserved');
  expect(actual.finishedAt, equals(expected.finishedAt),
      reason: 'finishedAt must be preserved');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // PersonalBookStatus
  // -------------------------------------------------------------------------
  group('PersonalBookStatus', () {
    test('all contains exactly 3 statuses', () {
      expect(PersonalBookStatus.all.length, equals(3));
    });

    test('all contains wantToRead, reading, and read', () {
      expect(PersonalBookStatus.all, contains(PersonalBookStatus.wantToRead));
      expect(PersonalBookStatus.all, contains(PersonalBookStatus.reading));
      expect(PersonalBookStatus.all, contains(PersonalBookStatus.read));
    });

    test('wantToRead constant has correct value', () {
      expect(PersonalBookStatus.wantToRead, equals('want_to_read'));
    });

    test('reading constant has correct value', () {
      expect(PersonalBookStatus.reading, equals('reading'));
    });

    test('read constant has correct value', () {
      expect(PersonalBookStatus.read, equals('read'));
    });
  });

  // -------------------------------------------------------------------------
  // PersonalBook.fromMap / toMap — unit tests for specific cases
  // -------------------------------------------------------------------------
  group('PersonalBook.fromMap', () {
    test('correctly deserializes all required fields', () {
      final now = DateTime(2024, 6, 15, 10, 30);
      final map = <String, dynamic>{
        'userId': 'user_1',
        'title': 'Don Quijote',
        'author': 'Cervantes',
        'status': PersonalBookStatus.wantToRead,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final book = PersonalBook.fromMap(map, 'book_1', 'user_1');

      expect(book.id, equals('book_1'));
      expect(book.userId, equals('user_1'));
      expect(book.title, equals('Don Quijote'));
      expect(book.author, equals('Cervantes'));
      expect(book.status, equals(PersonalBookStatus.wantToRead));
      expect(book.createdAt, equals(now));
      expect(book.updatedAt, equals(now));
      expect(book.description, isNull);
      expect(book.coverUrl, isNull);
      expect(book.notes, isNull);
      expect(book.rating, isNull);
      expect(book.startedAt, isNull);
      expect(book.finishedAt, isNull);
    });

    test('correctly deserializes all optional fields when present', () {
      final createdAt = DateTime(2024, 1, 1);
      final updatedAt = DateTime(2024, 3, 1);
      final startedAt = DateTime(2024, 2, 1);
      final finishedAt = DateTime(2024, 2, 28);

      final map = <String, dynamic>{
        'userId': 'user_2',
        'title': '1984',
        'author': 'George Orwell',
        'description': 'A dystopian novel.',
        'coverUrl': 'https://example.com/1984.jpg',
        'status': PersonalBookStatus.read,
        'notes': 'Chilling and prophetic.',
        'rating': 5,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'startedAt': Timestamp.fromDate(startedAt),
        'finishedAt': Timestamp.fromDate(finishedAt),
      };

      final book = PersonalBook.fromMap(map, 'book_2', 'user_2');

      expect(book.description, equals('A dystopian novel.'));
      expect(book.coverUrl, equals('https://example.com/1984.jpg'));
      expect(book.notes, equals('Chilling and prophetic.'));
      expect(book.rating, equals(5));
      expect(book.startedAt, equals(startedAt));
      expect(book.finishedAt, equals(finishedAt));
    });

    test('defaults status to wantToRead when field is missing', () {
      final map = <String, dynamic>{
        'title': 'Test',
        'author': 'Author',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      final book = PersonalBook.fromMap(map, 'book_3', 'user_3');
      expect(book.status, equals(PersonalBookStatus.wantToRead));
    });
  });

  group('PersonalBook.toMap', () {
    test('includes all required fields', () {
      final now = DateTime(2024, 5, 10);
      final book = PersonalBook(
        id: 'book_4',
        userId: 'user_4',
        title: 'Ficciones',
        author: 'Borges',
        status: PersonalBookStatus.wantToRead,
        createdAt: now,
        updatedAt: now,
      );

      final map = book.toMap();

      expect(map.containsKey('userId'), isTrue);
      expect(map.containsKey('title'), isTrue);
      expect(map.containsKey('author'), isTrue);
      expect(map.containsKey('status'), isTrue);
      expect(map.containsKey('createdAt'), isTrue);
      expect(map.containsKey('updatedAt'), isTrue);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('omits null optional fields', () {
      final book = PersonalBook(
        id: 'book_5',
        userId: 'user_5',
        title: 'Pedro Páramo',
        author: 'Juan Rulfo',
        status: PersonalBookStatus.wantToRead,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final map = book.toMap();

      expect(map.containsKey('description'), isFalse);
      expect(map.containsKey('coverUrl'), isFalse);
      expect(map.containsKey('notes'), isFalse);
      expect(map.containsKey('rating'), isFalse);
      expect(map.containsKey('startedAt'), isFalse);
      expect(map.containsKey('finishedAt'), isFalse);
    });

    test('includes optional fields when present', () {
      final startedAt = DateTime(2024, 2, 1);
      final finishedAt = DateTime(2024, 3, 1);
      final book = PersonalBook(
        id: 'book_6',
        userId: 'user_6',
        title: 'Cien años de soledad',
        author: 'García Márquez',
        description: 'Magical realism.',
        coverUrl: 'https://example.com/cien.jpg',
        status: PersonalBookStatus.read,
        notes: 'A masterpiece.',
        rating: 5,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 3, 1),
        startedAt: startedAt,
        finishedAt: finishedAt,
      );

      final map = book.toMap();

      expect(map['description'], equals('Magical realism.'));
      expect(map['coverUrl'], equals('https://example.com/cien.jpg'));
      expect(map['notes'], equals('A masterpiece.'));
      expect(map['rating'], equals(5));
      expect(map['startedAt'], isA<Timestamp>());
      expect(map['finishedAt'], isA<Timestamp>());
      expect((map['startedAt'] as Timestamp).toDate(), equals(startedAt));
      expect((map['finishedAt'] as Timestamp).toDate(), equals(finishedAt));
    });
  });

  // -------------------------------------------------------------------------
  // P2: Round-trip fromMap/toMap property test
  // Validates: Requirements 2.1
  //
  // For any valid PersonalBook, converting to a Firestore map and back must
  // produce an object with identical field values.
  // -------------------------------------------------------------------------
  group('P2: PersonalBook fromMap/toMap round-trip preserves all fields', () {
    // Property-based test using glados with at least 100 iterations
    Glados(any.personalBook, ExploreConfig(numRuns: 100)).test(
      'for any valid PersonalBook, fromMap(toMap()) produces an equal object',
      (book) {
        final map = book.toMap();
        final restored = PersonalBook.fromMap(map, book.id, book.userId);
        expectPersonalBooksEqual(restored, book);
      },
    );

    // Edge case: book with all optional fields set to null
    test('round-trip preserves book with all optional fields null', () {
      final now = DateTime(2024, 6, 1, 12, 0, 0, 500); // with milliseconds
      final book = PersonalBook(
        id: 'edge_1',
        userId: 'user_edge',
        title: 'Minimal Book',
        author: 'Minimal Author',
        status: PersonalBookStatus.wantToRead,
        createdAt: now,
        updatedAt: now,
      );

      final map = book.toMap();
      final restored = PersonalBook.fromMap(map, book.id, book.userId);
      expectPersonalBooksEqual(restored, book);
    });

    // Edge case: book with all optional fields set
    test('round-trip preserves book with all optional fields set', () {
      final createdAt = DateTime(2023, 1, 15, 8, 30, 0, 123);
      final updatedAt = DateTime(2024, 3, 20, 14, 0, 0, 456);
      final startedAt = DateTime(2023, 2, 1, 9, 0, 0, 0);
      final finishedAt = DateTime(2023, 12, 31, 23, 59, 0, 999);

      final book = PersonalBook(
        id: 'edge_2',
        userId: 'user_edge_2',
        title: 'Complete Book',
        author: 'Complete Author',
        description: 'A full description.',
        coverUrl: 'https://storage.googleapis.com/cover.jpg',
        status: PersonalBookStatus.read,
        notes: 'Detailed notes about this book.',
        rating: 4,
        createdAt: createdAt,
        updatedAt: updatedAt,
        startedAt: startedAt,
        finishedAt: finishedAt,
      );

      final map = book.toMap();
      final restored = PersonalBook.fromMap(map, book.id, book.userId);
      expectPersonalBooksEqual(restored, book);
    });

    // Edge case: each valid status round-trips correctly
    for (final status in PersonalBookStatus.all) {
      test('round-trip preserves status "$status"', () {
        final now = DateTime(2024, 1, 1);
        final book = PersonalBook(
          id: 'status_test_$status',
          userId: 'user_status',
          title: 'Status Test Book',
          author: 'Status Author',
          status: status,
          createdAt: now,
          updatedAt: now,
        );

        final map = book.toMap();
        final restored = PersonalBook.fromMap(map, book.id, book.userId);
        expect(restored.status, equals(status),
            reason: 'status "$status" must survive round-trip');
      });
    }

    // Edge case: each valid rating (1–5) round-trips correctly
    for (final rating in [1, 2, 3, 4, 5]) {
      test('round-trip preserves rating $rating', () {
        final now = DateTime(2024, 1, 1);
        final book = PersonalBook(
          id: 'rating_test_$rating',
          userId: 'user_rating',
          title: 'Rating Test Book',
          author: 'Rating Author',
          status: PersonalBookStatus.read,
          rating: rating,
          createdAt: now,
          updatedAt: now,
        );

        final map = book.toMap();
        final restored = PersonalBook.fromMap(map, book.id, book.userId);
        expect(restored.rating, equals(rating),
            reason: 'rating $rating must survive round-trip');
      });
    }

    // Edge case: Timestamp precision — milliseconds are preserved
    test('round-trip preserves DateTime values at millisecond precision', () {
      final createdAt = DateTime(2024, 6, 15, 10, 30, 45, 123);
      final updatedAt = DateTime(2024, 7, 20, 14, 0, 0, 999);

      final book = PersonalBook(
        id: 'precision_test',
        userId: 'user_precision',
        title: 'Precision Test',
        author: 'Precision Author',
        status: PersonalBookStatus.wantToRead,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final map = book.toMap();
      final restored = PersonalBook.fromMap(map, book.id, book.userId);

      expect(restored.createdAt.millisecondsSinceEpoch,
          equals(createdAt.millisecondsSinceEpoch),
          reason: 'createdAt milliseconds must be preserved');
      expect(restored.updatedAt.millisecondsSinceEpoch,
          equals(updatedAt.millisecondsSinceEpoch),
          reason: 'updatedAt milliseconds must be preserved');
    });
  });
}
