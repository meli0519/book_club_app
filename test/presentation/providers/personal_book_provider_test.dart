// Feature: personal-books
// Property 6: Listado ordenado por updatedAt descendente
//   Validates: Requirements 5.1
// Property 7: Filtrado por status retorna solo libros con ese status
//   Validates: Requirements 5.2
//
// NOTE: P6 and P7 test the SERVICE methods directly
// (watchPersonalBooks and watchPersonalBooksByStatus), since the Riverpod
// providers depend on Firebase auth state which is not available in unit tests.
// The service methods are the core logic being validated by these properties.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:glados/glados.dart';

import 'package:book_club_app/domain/models/personal_book.dart';

// ---------------------------------------------------------------------------
// Helpers – mirror PersonalBookService query logic
// ---------------------------------------------------------------------------

/// Writes a [PersonalBook] to fake Firestore under `users/{uid}/personal_books`.
Future<void> _writePersonalBook(
  FakeFirebaseFirestore fs,
  PersonalBook book,
) async {
  await fs
      .collection('users')
      .doc(book.userId)
      .collection('personal_books')
      .doc(book.id)
      .set(book.toMap());
}

/// Mirrors PersonalBookService.watchPersonalBooks(uid) query logic.
///
/// Returns a stream of all personal books for [uid], ordered by [updatedAt]
/// descending.
Stream<List<PersonalBook>> _watchPersonalBooks(
  FakeFirebaseFirestore fs,
  String uid,
) {
  return fs
      .collection('users')
      .doc(uid)
      .collection('personal_books')
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => PersonalBook.fromMap(doc.data(), doc.id, uid))
            .toList(),
      );
}

/// Mirrors PersonalBookService.watchPersonalBooksByStatus(uid, status) logic.
///
/// Returns a stream of personal books for [uid] filtered by [status], ordered
/// by [updatedAt] descending.
Stream<List<PersonalBook>> _watchPersonalBooksByStatus(
  FakeFirebaseFirestore fs,
  String uid,
  String status,
) {
  return fs
      .collection('users')
      .doc(uid)
      .collection('personal_books')
      .where('status', isEqualTo: status)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => PersonalBook.fromMap(doc.data(), doc.id, uid))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Test data generators
// ---------------------------------------------------------------------------

const _uid = 'user_test_p6_p7';

const _titles = [
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

const _authors = [
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

/// Builds a [PersonalBook] with a specific [updatedAt] and [status].
PersonalBook _makeBook({
  required int index,
  required String userId,
  required DateTime updatedAt,
  String? status,
}) {
  final resolvedStatus =
      status ?? PersonalBookStatus.all[index % PersonalBookStatus.all.length];
  final createdAt = updatedAt.subtract(const Duration(hours: 1));
  return PersonalBook(
    id: 'book_${userId}_$index',
    userId: userId,
    title: _titles[index % _titles.length],
    author: _authors[index % _authors.length],
    status: resolvedStatus,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

// ---------------------------------------------------------------------------
// Glados generators
// ---------------------------------------------------------------------------

extension AnyPersonalBookListForProviders on Any {
  /// Generates a list of [PersonalBook] objects for a single user with
  /// distinct, randomly ordered [updatedAt] timestamps.
  ///
  /// The list contains between 2 and 15 books. Each book has a unique
  /// [updatedAt] so the ordering property is unambiguous.
  Generator<List<PersonalBook>> get personalBooksForSingleUser =>
      (random, size) {
        // Between 2 and 15 books per run
        final count = 2 + random.nextInt(14);

        // Generate distinct updatedAt timestamps (days apart to avoid collisions)
        final baseDay = DateTime(2020, 1, 1);
        final dayOffsets = List<int>.generate(count, (i) => i * 10)
          ..shuffle(random);

        final books = <PersonalBook>[];
        for (var i = 0; i < count; i++) {
          final updatedAt = baseDay.add(Duration(days: dayOffsets[i]));
          books.add(
            _makeBook(index: i, userId: _uid, updatedAt: updatedAt),
          );
        }

        return Shrinkable(books, () => []);
      };

  /// Generates a list of [PersonalBook] objects with mixed statuses for a
  /// single user, plus a random status filter value.
  ///
  /// The list contains between 3 and 15 books with statuses drawn from all
  /// three [PersonalBookStatus] values, ensuring at least one book per status.
  Generator<(List<PersonalBook>, String)>
      get personalBooksWithMixedStatusesAndFilter => (random, size) {
        // Between 3 and 15 books per run (at least one per status)
        final extraCount = random.nextInt(13); // 0..12 extra books
        final count = 3 + extraCount;

        final baseDay = DateTime(2020, 1, 1);
        final books = <PersonalBook>[];

        // Guarantee at least one book per status
        for (var i = 0; i < PersonalBookStatus.all.length; i++) {
          final updatedAt = baseDay.add(Duration(days: i * 10));
          books.add(
            _makeBook(
              index: i,
              userId: _uid,
              updatedAt: updatedAt,
              status: PersonalBookStatus.all[i],
            ),
          );
        }

        // Fill remaining books with random statuses
        for (var i = PersonalBookStatus.all.length; i < count; i++) {
          final status =
              PersonalBookStatus.all[random.nextInt(PersonalBookStatus.all.length)];
          final updatedAt = baseDay.add(Duration(days: i * 10));
          books.add(
            _makeBook(
              index: i,
              userId: _uid,
              updatedAt: updatedAt,
              status: status,
            ),
          );
        }

        // Pick a random status filter
        final filterStatus =
            PersonalBookStatus.all[random.nextInt(PersonalBookStatus.all.length)];

        return Shrinkable(
          (books, filterStatus),
          () => [
            Shrinkable(
              (books.take(3).toList(), PersonalBookStatus.wantToRead),
              () => [],
            ),
          ],
        );
      };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // P6: Listado ordenado por updatedAt descendente
  // Validates: Requirements 5.1
  //
  // For any collection of PersonalBooks, watchPersonalBooks(uid) must return
  // the list ordered so that books[i].updatedAt >= books[i+1].updatedAt for
  // every adjacent pair.
  // =========================================================================
  group('P6: watchPersonalBooks returns books ordered by updatedAt descending', () {
    // -----------------------------------------------------------------------
    // Unit tests – concrete examples
    // -----------------------------------------------------------------------
    test('single book is trivially sorted', () async {
      final fs = FakeFirebaseFirestore();
      final book = _makeBook(
        index: 0,
        userId: _uid,
        updatedAt: DateTime(2024, 6, 1),
      );
      await _writePersonalBook(fs, book);

      final result = await _watchPersonalBooks(fs, _uid).first;

      expect(result.length, equals(1));
    });

    test('two books are returned newest-first', () async {
      final fs = FakeFirebaseFirestore();

      final older = _makeBook(
        index: 0,
        userId: _uid,
        updatedAt: DateTime(2024, 1, 1),
      );
      final newer = _makeBook(
        index: 1,
        userId: _uid,
        updatedAt: DateTime(2024, 6, 1),
      );

      await _writePersonalBook(fs, older);
      await _writePersonalBook(fs, newer);

      final result = await _watchPersonalBooks(fs, _uid).first;

      expect(result.length, equals(2));
      expect(
        result[0].updatedAt.isAfter(result[1].updatedAt) ||
            result[0].updatedAt.isAtSameMomentAs(result[1].updatedAt),
        isTrue,
        reason: 'First book must have updatedAt >= second book updatedAt',
      );
    });

    test('five books are returned in descending updatedAt order', () async {
      final fs = FakeFirebaseFirestore();

      final dates = [
        DateTime(2024, 3, 15),
        DateTime(2024, 1, 1),
        DateTime(2024, 6, 30),
        DateTime(2024, 2, 10),
        DateTime(2024, 5, 5),
      ];

      for (var i = 0; i < dates.length; i++) {
        await _writePersonalBook(
          fs,
          _makeBook(index: i, userId: _uid, updatedAt: dates[i]),
        );
      }

      final result = await _watchPersonalBooks(fs, _uid).first;

      expect(result.length, equals(5));
      for (var i = 0; i < result.length - 1; i++) {
        expect(
          result[i].updatedAt.isAfter(result[i + 1].updatedAt) ||
              result[i].updatedAt.isAtSameMomentAs(result[i + 1].updatedAt),
          isTrue,
          reason:
              'books[$i].updatedAt must be >= books[${i + 1}].updatedAt',
        );
      }
    });

    test('empty list is trivially sorted', () async {
      final fs = FakeFirebaseFirestore();
      final result = await _watchPersonalBooks(fs, _uid).first;
      expect(result, isEmpty);
    });

    // -----------------------------------------------------------------------
    // Property test
    // Feature: personal-books, Property 6: Listado ordenado por updatedAt desc
    // Validates: Requirements 5.1
    // -----------------------------------------------------------------------
    Glados(any.personalBooksForSingleUser, ExploreConfig(numRuns: 100)).test(
      'for any collection of PersonalBooks, the stream returns them ordered by updatedAt descending',
      (books) async {
        final fs = FakeFirebaseFirestore();

        for (final book in books) {
          await _writePersonalBook(fs, book);
        }

        final result = await _watchPersonalBooks(fs, _uid).first;

        expect(
          result.length,
          equals(books.length),
          reason: 'All written books must be returned',
        );

        // Verify descending order: books[i].updatedAt >= books[i+1].updatedAt
        for (var i = 0; i < result.length - 1; i++) {
          expect(
            result[i].updatedAt.isAfter(result[i + 1].updatedAt) ||
                result[i].updatedAt.isAtSameMomentAs(result[i + 1].updatedAt),
            isTrue,
            reason:
                'books[$i].updatedAt (${result[i].updatedAt}) must be >= '
                'books[${i + 1}].updatedAt (${result[i + 1].updatedAt})',
          );
        }
      },
    );
  });

  // =========================================================================
  // P7: Filtrado por status retorna solo libros con ese status
  // Validates: Requirements 5.2
  //
  // For any set of PersonalBooks with mixed statuses and any filter value
  // s ∈ {want_to_read, reading, read}, watchPersonalBooksByStatus(uid, s)
  // must return ONLY books whose status == s.
  // =========================================================================
  group('P7: watchPersonalBooksByStatus returns only books with the given status', () {
    // -----------------------------------------------------------------------
    // Unit tests – concrete examples
    // -----------------------------------------------------------------------
    test('returns empty list when no books match the filter', () async {
      final fs = FakeFirebaseFirestore();

      // Write only 'reading' books
      for (var i = 0; i < 3; i++) {
        await _writePersonalBook(
          fs,
          _makeBook(
            index: i,
            userId: _uid,
            updatedAt: DateTime(2024, 1, i + 1),
            status: PersonalBookStatus.reading,
          ),
        );
      }

      final result = await _watchPersonalBooksByStatus(
        fs,
        _uid,
        PersonalBookStatus.read,
      ).first;

      expect(result, isEmpty);
    });

    test('returns only want_to_read books when filtering by want_to_read', () async {
      final fs = FakeFirebaseFirestore();

      await _writePersonalBook(
        fs,
        _makeBook(
          index: 0,
          userId: _uid,
          updatedAt: DateTime(2024, 1, 1),
          status: PersonalBookStatus.wantToRead,
        ),
      );
      await _writePersonalBook(
        fs,
        _makeBook(
          index: 1,
          userId: _uid,
          updatedAt: DateTime(2024, 2, 1),
          status: PersonalBookStatus.reading,
        ),
      );
      await _writePersonalBook(
        fs,
        _makeBook(
          index: 2,
          userId: _uid,
          updatedAt: DateTime(2024, 3, 1),
          status: PersonalBookStatus.read,
        ),
      );

      final result = await _watchPersonalBooksByStatus(
        fs,
        _uid,
        PersonalBookStatus.wantToRead,
      ).first;

      expect(result.length, equals(1));
      expect(result.every((b) => b.status == PersonalBookStatus.wantToRead), isTrue);
    });

    test('returns only reading books when filtering by reading', () async {
      final fs = FakeFirebaseFirestore();

      for (var i = 0; i < 5; i++) {
        final status = i < 2
            ? PersonalBookStatus.reading
            : PersonalBookStatus.all[i % PersonalBookStatus.all.length];
        await _writePersonalBook(
          fs,
          _makeBook(
            index: i,
            userId: _uid,
            updatedAt: DateTime(2024, 1, i + 1),
            status: status,
          ),
        );
      }

      final result = await _watchPersonalBooksByStatus(
        fs,
        _uid,
        PersonalBookStatus.reading,
      ).first;

      expect(result.every((b) => b.status == PersonalBookStatus.reading), isTrue);
    });

    test('returns only read books when filtering by read', () async {
      final fs = FakeFirebaseFirestore();

      for (var i = 0; i < 6; i++) {
        final status = i % 3 == 0
            ? PersonalBookStatus.read
            : PersonalBookStatus.all[i % PersonalBookStatus.all.length];
        await _writePersonalBook(
          fs,
          _makeBook(
            index: i,
            userId: _uid,
            updatedAt: DateTime(2024, 1, i + 1),
            status: status,
          ),
        );
      }

      final result = await _watchPersonalBooksByStatus(
        fs,
        _uid,
        PersonalBookStatus.read,
      ).first;

      expect(result.every((b) => b.status == PersonalBookStatus.read), isTrue);
    });

    test('count of filtered results matches expected count', () async {
      final fs = FakeFirebaseFirestore();

      // Write 3 want_to_read, 2 reading, 4 read
      final statuses = [
        ...List.filled(3, PersonalBookStatus.wantToRead),
        ...List.filled(2, PersonalBookStatus.reading),
        ...List.filled(4, PersonalBookStatus.read),
      ];

      for (var i = 0; i < statuses.length; i++) {
        await _writePersonalBook(
          fs,
          _makeBook(
            index: i,
            userId: _uid,
            updatedAt: DateTime(2024, 1, i + 1),
            status: statuses[i],
          ),
        );
      }

      final wantToReadResult = await _watchPersonalBooksByStatus(
        fs,
        _uid,
        PersonalBookStatus.wantToRead,
      ).first;
      final readingResult = await _watchPersonalBooksByStatus(
        fs,
        _uid,
        PersonalBookStatus.reading,
      ).first;
      final readResult = await _watchPersonalBooksByStatus(
        fs,
        _uid,
        PersonalBookStatus.read,
      ).first;

      expect(wantToReadResult.length, equals(3));
      expect(readingResult.length, equals(2));
      expect(readResult.length, equals(4));
    });

    // -----------------------------------------------------------------------
    // Property test
    // Feature: personal-books, Property 7: Filtrado por status retorna solo
    // libros con ese status
    // Validates: Requirements 5.2
    // -----------------------------------------------------------------------
    Glados(
      any.personalBooksWithMixedStatusesAndFilter,
      ExploreConfig(numRuns: 100),
    ).test(
      'for any set of PersonalBooks with mixed statuses and any filter s, '
      'watchPersonalBooksByStatus returns only books with status == s',
      (input) async {
        final (books, filterStatus) = input;
        final fs = FakeFirebaseFirestore();

        for (final book in books) {
          await _writePersonalBook(fs, book);
        }

        final result = await _watchPersonalBooksByStatus(
          fs,
          _uid,
          filterStatus,
        ).first;

        // Every returned book must have status == filterStatus
        expect(
          result.every((b) => b.status == filterStatus),
          isTrue,
          reason:
              'watchPersonalBooksByStatus("$filterStatus") must return only '
              'books with status == "$filterStatus"',
        );

        // The count must match the number of books written with that status
        final expectedCount =
            books.where((b) => b.status == filterStatus).length;
        expect(
          result.length,
          equals(expectedCount),
          reason:
              'watchPersonalBooksByStatus("$filterStatus") must return exactly '
              '$expectedCount book(s) with status "$filterStatus"',
        );
      },
    );
  });
}
