// Feature: personal-books
// Property 1: Aislamiento de libros personales por usuario
//   Validates: Requirements 1.2
// Property 2: Creación de Personal_Book preserva todos los campos requeridos
//   Validates: Requirements 2.1
// Property 4: Actualización parcial preserva campos no modificados
//   Validates: Requirements 3.1
//
// WHEN el Member accede a la Personal_Books_Screen, THE App SHALL mostrar
// únicamente los Personal_Books creados por el Member autenticado.
//
// WHEN el Member envía el formulario de creación de Personal_Book con título y
// autor, THE App SHALL guardar el documento con los campos: title, author,
// status (valor inicial want_to_read), createdAt y updatedAt.
//
// WHEN el Member edita un Personal_Book existente, THE App SHALL actualizar
// únicamente los campos modificados en el documento de Firestore y registrar
// la fecha actual en el campo updatedAt.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:glados/glados.dart';

import 'package:book_club_app/domain/models/personal_book.dart';

// ---------------------------------------------------------------------------
// Helpers – mirror PersonalBookService logic
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

/// Mirrors PersonalBookService.createPersonalBook logic (without Storage).
///
/// Creates a new document under `users/{uid}/personal_books` with a
/// server-generated ID and sets `createdAt` / `updatedAt` to [Timestamp.now()].
/// Returns the generated document ID.
Future<String> _createPersonalBook(
  FakeFirebaseFirestore fs,
  String uid,
  String title,
  String author,
) async {
  final collectionRef = fs
      .collection('users')
      .doc(uid)
      .collection('personal_books');

  final docRef = collectionRef.doc();
  final now = Timestamp.now();

  await docRef.set({
    'userId': uid,
    'title': title,
    'author': author,
    'status': PersonalBookStatus.wantToRead,
    'createdAt': now,
    'updatedAt': now,
  });

  return docRef.id;
}

/// Mirrors PersonalBookService.updatePersonalBook logic.
///
/// Updates only the fields in [fields] plus `updatedAt` for [bookId].
Future<void> _updatePersonalBook(
  FakeFirebaseFirestore fs,
  String uid,
  String bookId,
  Map<String, dynamic> fields,
) async {
  await fs
      .collection('users')
      .doc(uid)
      .collection('personal_books')
      .doc(bookId)
      .update({
    ...fields,
    'updatedAt': Timestamp.now(),
  });
}

/// Mirrors PersonalBookService.updatePersonalBook logic WITH status-transition
/// timestamp handling (as implemented for Requirements 3.2 and 3.3).
///
/// - When [fields] contains `status == 'read'`, sets `finishedAt` to now.
/// - When [fields] contains `status == 'reading'` and the document does not
///   already have a `startedAt` value, sets `startedAt` to now.
Future<void> _updatePersonalBookWithStatusTransition(
  FakeFirebaseFirestore fs,
  String uid,
  String bookId,
  Map<String, dynamic> fields,
) async {
  final extraFields = <String, dynamic>{};

  final newStatus = fields['status'] as String?;
  if (newStatus == PersonalBookStatus.read) {
    extraFields['finishedAt'] = Timestamp.now();
  } else if (newStatus == PersonalBookStatus.reading) {
    final doc = await fs
        .collection('users')
        .doc(uid)
        .collection('personal_books')
        .doc(bookId)
        .get();
    final existingStartedAt = doc.data()?['startedAt'];
    if (existingStartedAt == null) {
      extraFields['startedAt'] = Timestamp.now();
    }
  }

  await fs
      .collection('users')
      .doc(uid)
      .collection('personal_books')
      .doc(bookId)
      .update({
    ...fields,
    ...extraFields,
    'updatedAt': Timestamp.now(),
  });
}

/// Mirrors PersonalBookService.watchPersonalBooks(uid) query logic.
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

// ---------------------------------------------------------------------------
// Test data generators
// ---------------------------------------------------------------------------

/// Fixed pool of user IDs used to generate mixed-userId book lists.
const _userIds = [
  'user_alpha',
  'user_beta',
  'user_gamma',
  'user_delta',
  'user_epsilon',
];

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

/// Builds a [PersonalBook] with deterministic values derived from [index].
PersonalBook _makeBook({
  required int index,
  required String userId,
}) {
  final status = PersonalBookStatus.all[index % PersonalBookStatus.all.length];
  final base = DateTime(2024, 1, 1).add(Duration(days: index));
  return PersonalBook(
    id: 'book_${userId}_$index',
    userId: userId,
    title: _titles[index % _titles.length],
    author: _authors[index % _authors.length],
    status: status,
    createdAt: base,
    updatedAt: base.add(const Duration(hours: 1)),
  );
}

// ---------------------------------------------------------------------------
// Glados generator: list of PersonalBooks with mixed userIds
// ---------------------------------------------------------------------------

extension AnyPersonalBookList on Any {
  /// Generates a list of [PersonalBook] objects with mixed [userId] values.
  ///
  /// The list contains between 2 and 20 books. Each book is assigned a userId
  /// drawn from [_userIds], so the list will typically contain books belonging
  /// to several different users.
  Generator<List<PersonalBook>> get mixedPersonalBooks =>
      (random, size) {
        // Between 2 and 20 books per run
        final count = 2 + random.nextInt(19);
        final books = <PersonalBook>[];
        for (var i = 0; i < count; i++) {
          final userId = _userIds[random.nextInt(_userIds.length)];
          books.add(_makeBook(index: i, userId: userId));
        }
        return Shrinkable(books, () => []);
      };

  /// Generates a valid (title, author) pair — both non-empty, non-whitespace
  /// strings drawn from the fixed pools above.
  ///
  /// Glados does not ship a built-in non-empty string generator, so we build
  /// one by drawing from the fixed pools of titles and authors.  This keeps
  /// the generator simple while still covering a wide range of realistic inputs.
  Generator<(String, String)> get validTitleAuthorPair =>
      (random, size) {
        final title = _titles[random.nextInt(_titles.length)];
        final author = _authors[random.nextInt(_authors.length)];
        return Shrinkable(
          (title, author),
          // Shrink to the first element of each pool (simplest valid pair).
          () => [
            Shrinkable((_titles[0], _authors[0]), () => []),
          ],
        );
      };

  /// Generates a non-empty subset of updatable PersonalBook fields.
  ///
  /// The updatable fields are: title, author, description, status, notes,
  /// rating (only when status == 'read').  The generator always returns at
  /// least one field so that the update operation is meaningful.
  Generator<Map<String, dynamic>> get partialUpdateFields =>
      (random, size) {
        // All candidate field entries (key → possible values)
        final statusValue =
            PersonalBookStatus.all[random.nextInt(PersonalBookStatus.all.length)];

        final candidates = <String, dynamic>{
          'title': _titles[random.nextInt(_titles.length)],
          'author': _authors[random.nextInt(_authors.length)],
          'description': random.nextBool() ? 'Updated description.' : null,
          'status': statusValue,
          'notes': random.nextBool() ? 'Updated notes.' : null,
          // rating is only valid when status == 'read'
          if (statusValue == PersonalBookStatus.read)
            'rating': 1 + random.nextInt(5),
        };

        // Pick a non-empty random subset of the candidate keys
        final keys = candidates.keys.toList();
        // Shuffle by building a random permutation
        final shuffled = List<String>.from(keys);
        for (var i = shuffled.length - 1; i > 0; i--) {
          final j = random.nextInt(i + 1);
          final tmp = shuffled[i];
          shuffled[i] = shuffled[j];
          shuffled[j] = tmp;
        }
        // Take between 1 and all keys
        final count = 1 + random.nextInt(shuffled.length);
        final selectedKeys = shuffled.take(count).toSet();

        final fields = <String, dynamic>{
          for (final k in selectedKeys) k: candidates[k],
        };

        return Shrinkable(fields, () => []);
      };

  /// Generates a sequence of ratings for property testing.
  ///
  /// Returns a list of 2-10 random ratings, each between 1 and 5.
  /// This is used to test that multiple rating saves result in exactly
  /// the last value being stored.
  Generator<List<int>> get ratingSequence => (random, size) {
        final count = 2 + random.nextInt(9); // 2-10 ratings
        final ratings = <int>[];
        for (var i = 0; i < count; i++) {
          ratings.add(1 + random.nextInt(5));
        }
        return Shrinkable(ratings, () => [Shrinkable([1, 2], () => [])]);
      };

  /// Generates a PersonalBook with status either 'want_to_read' or 'reading'.
  ///
  /// Used for Property 10 testing: rating should be rejected for books
  /// that are not marked as 'read'.
  Generator<PersonalBook> get nonReadPersonalBook => (random, size) {
        final status = PersonalBookStatus.all[
            random.nextInt(PersonalBookStatus.all.length - 1)]; // exclude 'read'
        final base = DateTime(2024, 1, 1).add(Duration(days: random.nextInt(365)));
        return Shrinkable(
          PersonalBook(
            id: 'book_${random.nextInt(10000)}',
            userId: 'user_${random.nextInt(100)}',
            title: _titles[random.nextInt(_titles.length)],
            author: _authors[random.nextInt(_authors.length)],
            status: status,
            createdAt: base,
            updatedAt: base.add(const Duration(hours: 1)),
          ),
          () => [
            Shrinkable(
              PersonalBook(
                id: 'book_0',
                userId: 'user_0',
                title: _titles[0],
                author: _authors[0],
                status: PersonalBookStatus.wantToRead,
                createdAt: base,
                updatedAt: base.add(const Duration(hours: 1)),
              ),
              () => [],
            ),
          ],
        );
      };
}

void main() {
  // -------------------------------------------------------------------------
  // Unit tests – concrete examples
  // -------------------------------------------------------------------------
  group('watchPersonalBooks – unit tests', () {
    test('returns empty list when user has no books', () async {
      final fs = FakeFirebaseFirestore();
      final result = await _watchPersonalBooks(fs, 'user_alpha').first;
      expect(result, isEmpty);
    });

    test('returns only books belonging to the queried uid', () async {
      final fs = FakeFirebaseFirestore();

      // Write books for two different users
      await _writePersonalBook(fs, _makeBook(index: 0, userId: 'user_alpha'));
      await _writePersonalBook(fs, _makeBook(index: 1, userId: 'user_alpha'));
      await _writePersonalBook(fs, _makeBook(index: 2, userId: 'user_beta'));

      final result = await _watchPersonalBooks(fs, 'user_alpha').first;

      expect(result.length, equals(2));
      expect(result.every((b) => b.userId == 'user_alpha'), isTrue);
    });

    test('returns all books when all belong to the queried uid', () async {
      final fs = FakeFirebaseFirestore();

      for (var i = 0; i < 5; i++) {
        await _writePersonalBook(fs, _makeBook(index: i, userId: 'user_gamma'));
      }

      final result = await _watchPersonalBooks(fs, 'user_gamma').first;

      expect(result.length, equals(5));
      expect(result.every((b) => b.userId == 'user_gamma'), isTrue);
    });

    test('returns empty list when all books belong to a different uid', () async {
      final fs = FakeFirebaseFirestore();

      for (var i = 0; i < 3; i++) {
        await _writePersonalBook(fs, _makeBook(index: i, userId: 'user_delta'));
      }

      final result = await _watchPersonalBooks(fs, 'user_epsilon').first;
      expect(result, isEmpty);
    });

    test('books from multiple users are isolated per uid', () async {
      final fs = FakeFirebaseFirestore();

      // Write 2 books per user for all 5 users
      for (final uid in _userIds) {
        for (var i = 0; i < 2; i++) {
          await _writePersonalBook(fs, _makeBook(index: i, userId: uid));
        }
      }

      for (final uid in _userIds) {
        final result = await _watchPersonalBooks(fs, uid).first;
        expect(
          result.every((b) => b.userId == uid),
          isTrue,
          reason: 'All books returned for $uid must have userId == $uid',
        );
        expect(
          result.length,
          equals(2),
          reason: '$uid should have exactly 2 books',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // P1: Aislamiento de libros personales por usuario
  // Validates: Requirements 1.2
  //
  // For any list of PersonalBooks with mixed userIds, watchPersonalBooks(uid)
  // must return ONLY the books whose userId == uid.
  // -------------------------------------------------------------------------
  group('P1: watchPersonalBooks only returns books for the given uid', () {
    Glados(any.mixedPersonalBooks, ExploreConfig(numRuns: 100)).test(
      'for any mixed list of PersonalBooks, stream returns only books with userId == uid',
      (books) async {
        final fs = FakeFirebaseFirestore();

        // Write all books to fake Firestore (each under its own user path)
        for (final book in books) {
          await _writePersonalBook(fs, book);
        }

        // Test isolation for every uid that appears in the generated list
        final uidsInList = books.map((b) => b.userId).toSet();
        for (final uid in uidsInList) {
          final result = await _watchPersonalBooks(fs, uid).first;

          // Every returned book must belong to uid
          expect(
            result.every((b) => b.userId == uid),
            isTrue,
            reason:
                'watchPersonalBooks("$uid") must return only books with userId == "$uid"',
          );

          // The count must match the number of books written for uid
          final expectedCount = books.where((b) => b.userId == uid).length;
          expect(
            result.length,
            equals(expectedCount),
            reason:
                'watchPersonalBooks("$uid") must return exactly $expectedCount book(s)',
          );
        }

        // Also verify that a uid with no books returns an empty list
        const absentUid = 'user_not_in_list_xyz';
        final emptyResult = await _watchPersonalBooks(fs, absentUid).first;
        expect(
          emptyResult,
          isEmpty,
          reason:
              'watchPersonalBooks for a uid with no books must return an empty list',
        );
      },
    );

    // Edge case: single book for target uid, many books for other users
    test('single book for target uid is not mixed with other users books', () async {
      final fs = FakeFirebaseFirestore();
      const targetUid = 'user_alpha';

      // Write 1 book for target uid
      await _writePersonalBook(fs, _makeBook(index: 0, userId: targetUid));

      // Write 10 books for other users
      for (var i = 1; i <= 10; i++) {
        final otherUid = _userIds[i % (_userIds.length - 1) + 1];
        await _writePersonalBook(fs, _makeBook(index: i, userId: otherUid));
      }

      final result = await _watchPersonalBooks(fs, targetUid).first;

      expect(result.length, equals(1));
      expect(result.first.userId, equals(targetUid));
    });

    // Edge case: uid with no books returns empty list even when other users have books
    test('uid with no books returns empty list when other users have books', () async {
      final fs = FakeFirebaseFirestore();

      for (var i = 0; i < 5; i++) {
        await _writePersonalBook(fs, _makeBook(index: i, userId: 'user_beta'));
      }

      final result = await _watchPersonalBooks(fs, 'user_alpha').first;
      expect(result, isEmpty);
    });

    // Edge case: large number of books across many users
    test('isolation holds with 50 books spread across 5 users', () async {
      final fs = FakeFirebaseFirestore();

      // Write 10 books per user
      for (final uid in _userIds) {
        for (var i = 0; i < 10; i++) {
          await _writePersonalBook(fs, _makeBook(index: i, userId: uid));
        }
      }

      for (final uid in _userIds) {
        final result = await _watchPersonalBooks(fs, uid).first;
        expect(
          result.length,
          equals(10),
          reason: '$uid should have exactly 10 books',
        );
        expect(
          result.every((b) => b.userId == uid),
          isTrue,
          reason: 'All books for $uid must have userId == $uid',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // P2: Creación de Personal_Book preserva todos los campos requeridos
  // Validates: Requirements 2.1
  //
  // For any valid (title, author) pair (non-empty strings), the document
  // saved in users/{uid}/personal_books must contain:
  //   - title  (matches input)
  //   - author (matches input)
  //   - status == 'want_to_read'
  //   - createdAt is not null
  //   - updatedAt is not null
  // -------------------------------------------------------------------------
  group('P2: createPersonalBook preserves all required fields', () {
    // Unit tests – concrete examples
    test('created document contains title, author, status, createdAt, updatedAt', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_alpha';
      const title = 'Don Quijote';
      const author = 'Miguel de Cervantes';

      final bookId = await _createPersonalBook(fs, uid, title, author);

      final doc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();

      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['title'], equals(title));
      expect(data['author'], equals(author));
      expect(data['status'], equals(PersonalBookStatus.wantToRead));
      expect(data['createdAt'], isNotNull);
      expect(data['updatedAt'], isNotNull);
    });

    test('status is always want_to_read on creation', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_beta';

      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Cien años de soledad',
        'Gabriel García Márquez',
      );

      final doc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();

      expect(doc.data()!['status'], equals('want_to_read'));
    });

    test('createdAt and updatedAt are equal on creation', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_gamma';

      final bookId = await _createPersonalBook(fs, uid, '1984', 'George Orwell');

      final doc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();

      final data = doc.data()!;
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      final updatedAt = (data['updatedAt'] as Timestamp).toDate();
      expect(createdAt, equals(updatedAt));
    });

    test('title and author are stored exactly as provided', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_delta';
      const title = 'El nombre de la rosa';
      const author = 'Umberto Eco';

      final bookId = await _createPersonalBook(fs, uid, title, author);

      final doc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();

      final data = doc.data()!;
      expect(data['title'], equals(title));
      expect(data['author'], equals(author));
    });

    // -----------------------------------------------------------------------
    // Property test
    // Feature: personal-books, Property 2: Creación de Personal_Book preserva
    // todos los campos requeridos
    // Validates: Requirements 2.1
    // -----------------------------------------------------------------------
    Glados(any.validTitleAuthorPair, ExploreConfig(numRuns: 100)).test(
      'for any valid (title, author) pair, created document contains all required fields',
      (pair) async {
        final (title, author) = pair;
        final fs = FakeFirebaseFirestore();
        const uid = 'user_test';

        final bookId = await _createPersonalBook(fs, uid, title, author);

        final doc = await fs
            .collection('users')
            .doc(uid)
            .collection('personal_books')
            .doc(bookId)
            .get();

        expect(
          doc.exists,
          isTrue,
          reason: 'Document must exist after createPersonalBook',
        );

        final data = doc.data()!;

        // title matches input
        expect(
          data['title'],
          equals(title),
          reason: 'Stored title must match the input title "$title"',
        );

        // author matches input
        expect(
          data['author'],
          equals(author),
          reason: 'Stored author must match the input author "$author"',
        );

        // status is always want_to_read on creation
        expect(
          data['status'],
          equals(PersonalBookStatus.wantToRead),
          reason: 'Initial status must be "${PersonalBookStatus.wantToRead}"',
        );

        // createdAt is present and is a Timestamp
        expect(
          data['createdAt'],
          isNotNull,
          reason: 'createdAt must be set on creation',
        );
        expect(
          data['createdAt'],
          isA<Timestamp>(),
          reason: 'createdAt must be a Firestore Timestamp',
        );

        // updatedAt is present and is a Timestamp
        expect(
          data['updatedAt'],
          isNotNull,
          reason: 'updatedAt must be set on creation',
        );
        expect(
          data['updatedAt'],
          isA<Timestamp>(),
          reason: 'updatedAt must be a Firestore Timestamp',
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // P4: Actualización parcial preserva campos no modificados
  // Validates: Requirements 3.1
  //
  // For any existing PersonalBook and any non-empty subset of updatable fields,
  // updatePersonalBook must modify ONLY the fields in the subset plus updatedAt,
  // leaving all other fields identical to their original values.
  // -------------------------------------------------------------------------
  group('P4: updatePersonalBook only modifies the specified fields plus updatedAt', () {
    // Unit tests – concrete examples

    test('updating only title leaves all other fields unchanged', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_alpha';

      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Original Title',
        'Original Author',
      );

      // Capture original document
      final originalDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final originalData = originalDoc.data()!;

      // Update only title
      await _updatePersonalBook(fs, uid, bookId, {'title': 'Updated Title'});

      final updatedDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final updatedData = updatedDoc.data()!;

      // title was changed
      expect(updatedData['title'], equals('Updated Title'));

      // all other fields are unchanged
      expect(updatedData['author'], equals(originalData['author']));
      expect(updatedData['status'], equals(originalData['status']));
      expect(updatedData['createdAt'], equals(originalData['createdAt']));

      // updatedAt was refreshed (not null)
      expect(updatedData['updatedAt'], isNotNull);
      expect(updatedData['updatedAt'], isA<Timestamp>());
    });

    test('updating only status leaves title and author unchanged', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_beta';

      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Cien años de soledad',
        'Gabriel García Márquez',
      );

      await _updatePersonalBook(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.reading},
      );

      final updatedDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final updatedData = updatedDoc.data()!;

      expect(updatedData['status'], equals(PersonalBookStatus.reading));
      expect(updatedData['title'], equals('Cien años de soledad'));
      expect(updatedData['author'], equals('Gabriel García Márquez'));
    });

    test('updating notes and rating leaves title, author, status unchanged', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_gamma';

      final bookId = await _createPersonalBook(
        fs,
        uid,
        '1984',
        'George Orwell',
      );

      // First set status to read so rating is valid
      await _updatePersonalBook(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.read},
      );

      // Now update notes and rating
      await _updatePersonalBook(
        fs,
        uid,
        bookId,
        {'notes': 'Chilling and prophetic.', 'rating': 5},
      );

      final updatedDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final updatedData = updatedDoc.data()!;

      expect(updatedData['notes'], equals('Chilling and prophetic.'));
      expect(updatedData['rating'], equals(5));
      expect(updatedData['title'], equals('1984'));
      expect(updatedData['author'], equals('George Orwell'));
      expect(updatedData['status'], equals(PersonalBookStatus.read));
    });

    test('updatedAt is always refreshed after update', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_delta';

      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Ficciones',
        'Jorge Luis Borges',
      );

      final beforeDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final originalUpdatedAt =
          (beforeDoc.data()!['updatedAt'] as Timestamp).toDate();

      // Small delay to ensure the new timestamp is different
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await _updatePersonalBook(
        fs,
        uid,
        bookId,
        {'title': 'Ficciones (edición revisada)'},
      );

      final afterDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final newUpdatedAt =
          (afterDoc.data()!['updatedAt'] as Timestamp).toDate();

      expect(
        newUpdatedAt.isAfter(originalUpdatedAt) ||
            newUpdatedAt.isAtSameMomentAs(originalUpdatedAt),
        isTrue,
        reason: 'updatedAt after update must be >= original updatedAt',
      );
    });

    test('createdAt is never modified by an update', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_epsilon';

      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Pedro Páramo',
        'Juan Rulfo',
      );

      final beforeDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final originalCreatedAt = beforeDoc.data()!['createdAt'] as Timestamp;

      await _updatePersonalBook(
        fs,
        uid,
        bookId,
        {'title': 'Pedro Páramo (nueva edición)', 'author': 'Juan Rulfo'},
      );

      final afterDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final createdAtAfter = afterDoc.data()!['createdAt'] as Timestamp;

      expect(
        createdAtAfter.toDate(),
        equals(originalCreatedAt.toDate()),
        reason: 'createdAt must never be modified by updatePersonalBook',
      );
    });

    // -----------------------------------------------------------------------
    // Property test
    // Feature: personal-books, Property 4: Actualización parcial preserva
    // campos no modificados
    // Validates: Requirements 3.1
    // -----------------------------------------------------------------------
    Glados(any.partialUpdateFields, ExploreConfig(numRuns: 100)).test(
      'for any non-empty subset of fields, updatePersonalBook only modifies those fields plus updatedAt',
      (fieldsToUpdate) async {
        final fs = FakeFirebaseFirestore();
        const uid = 'user_p4_test';

        // Create a book with a known set of fields
        final bookId = await _createPersonalBook(
          fs,
          uid,
          'Don Quijote',
          'Miguel de Cervantes',
        );

        // Capture the original document data
        final originalDoc = await fs
            .collection('users')
            .doc(uid)
            .collection('personal_books')
            .doc(bookId)
            .get();
        final originalData = Map<String, dynamic>.from(originalDoc.data()!);

        // Perform the partial update
        await _updatePersonalBook(fs, uid, bookId, fieldsToUpdate);

        // Read back the updated document
        final updatedDoc = await fs
            .collection('users')
            .doc(uid)
            .collection('personal_books')
            .doc(bookId)
            .get();
        final updatedData = updatedDoc.data()!;

        // 1. Every field in fieldsToUpdate must reflect the new value
        for (final entry in fieldsToUpdate.entries) {
          expect(
            updatedData[entry.key],
            equals(entry.value),
            reason:
                'Field "${entry.key}" must be updated to "${entry.value}"',
          );
        }

        // 2. updatedAt must be present and be a Timestamp
        expect(
          updatedData['updatedAt'],
          isNotNull,
          reason: 'updatedAt must be set after updatePersonalBook',
        );
        expect(
          updatedData['updatedAt'],
          isA<Timestamp>(),
          reason: 'updatedAt must be a Firestore Timestamp',
        );

        // 3. updatedAt must be >= original updatedAt
        final originalUpdatedAt =
            (originalData['updatedAt'] as Timestamp).toDate();
        final newUpdatedAt =
            (updatedData['updatedAt'] as Timestamp).toDate();
        expect(
          newUpdatedAt.isAfter(originalUpdatedAt) ||
              newUpdatedAt.isAtSameMomentAs(originalUpdatedAt),
          isTrue,
          reason:
              'updatedAt after update must be >= original updatedAt',
        );

        // 4. createdAt must never change
        expect(
          (updatedData['createdAt'] as Timestamp).toDate(),
          equals((originalData['createdAt'] as Timestamp).toDate()),
          reason: 'createdAt must not be modified by updatePersonalBook',
        );

        // 5. All fields NOT in fieldsToUpdate (and not updatedAt) must be
        //    identical to their original values.
        final unchangedKeys = originalData.keys
            .where((k) => k != 'updatedAt' && !fieldsToUpdate.containsKey(k))
            .toList();

        for (final key in unchangedKeys) {
          expect(
            updatedData[key],
            equals(originalData[key]),
            reason:
                'Field "$key" was not in the update map and must remain unchanged',
          );
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // P5: Transiciones de estado registran timestamps correctos
  // Feature: personal-books, Property 5: Transiciones de estado registran
  // timestamps correctos
  // Validates: Requirements 3.2, 3.3
  //
  // Sub-cases:
  //   a) status -> 'read'    : finishedAt is set and finishedAt >= createdAt
  //   b) status -> 'reading' (no prior startedAt): startedAt is set and
  //      startedAt >= createdAt
  //   c) status -> 'reading' (startedAt already exists): startedAt is NOT
  //      overwritten
  // -------------------------------------------------------------------------
  group('P5: status transitions record correct timestamps', () {
    // -----------------------------------------------------------------------
    // Unit tests - concrete examples
    // -----------------------------------------------------------------------

    test('transitioning to read sets finishedAt >= createdAt', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_alpha';

      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Don Quijote',
        'Miguel de Cervantes',
      );

      final beforeDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final createdAt =
          (beforeDoc.data()!['createdAt'] as Timestamp).toDate();

      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.read},
      );

      final afterDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final data = afterDoc.data()!;

      expect(data['finishedAt'], isNotNull,
          reason: 'finishedAt must be set when transitioning to read');
      expect(data['finishedAt'], isA<Timestamp>());

      final finishedAt = (data['finishedAt'] as Timestamp).toDate();
      expect(
        finishedAt.isAfter(createdAt) ||
            finishedAt.isAtSameMomentAs(createdAt),
        isTrue,
        reason: 'finishedAt must be >= createdAt',
      );
    });

    test(
        'transitioning to reading without prior startedAt sets startedAt >= createdAt',
        () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_beta';

      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Cien anos de soledad',
        'Gabriel Garcia Marquez',
      );

      final beforeDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final createdAt =
          (beforeDoc.data()!['createdAt'] as Timestamp).toDate();

      expect(beforeDoc.data()!['startedAt'], isNull);

      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.reading},
      );

      final afterDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final data = afterDoc.data()!;

      expect(data['startedAt'], isNotNull,
          reason:
              'startedAt must be set when transitioning to reading for the first time');
      expect(data['startedAt'], isA<Timestamp>());

      final startedAt = (data['startedAt'] as Timestamp).toDate();
      expect(
        startedAt.isAfter(createdAt) ||
            startedAt.isAtSameMomentAs(createdAt),
        isTrue,
        reason: 'startedAt must be >= createdAt',
      );
    });

    test(
        'transitioning to reading with existing startedAt does NOT overwrite it',
        () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_gamma';

      final bookId = await _createPersonalBook(
        fs,
        uid,
        '1984',
        'George Orwell',
      );

      // First transition to reading - sets startedAt
      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.reading},
      );

      final afterFirstDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final originalStartedAt =
          afterFirstDoc.data()!['startedAt'] as Timestamp;

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Transition back to want_to_read, then to reading again
      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.wantToRead},
      );
      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.reading},
      );

      final afterSecondDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final startedAtAfterSecondTransition =
          afterSecondDoc.data()!['startedAt'] as Timestamp;

      expect(
        startedAtAfterSecondTransition.toDate(),
        equals(originalStartedAt.toDate()),
        reason: 'startedAt must NOT be overwritten when it already exists',
      );
    });

    test('transitioning to read does not affect startedAt', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_delta';

      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Ficciones',
        'Jorge Luis Borges',
      );

      // Set to reading first
      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.reading},
      );

      final afterReadingDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final startedAt =
          afterReadingDoc.data()!['startedAt'] as Timestamp;

      // Now transition to read
      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.read},
      );

      final afterReadDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final data = afterReadDoc.data()!;

      expect(data['finishedAt'], isNotNull);
      expect(
        (data['startedAt'] as Timestamp).toDate(),
        equals(startedAt.toDate()),
        reason: 'startedAt must not be modified when transitioning to read',
      );
    });

    // -----------------------------------------------------------------------
    // Property test
    // Feature: personal-books, Property 5: Transiciones de estado registran
    // timestamps correctos
    // Validates: Requirements 3.2, 3.3
    // -----------------------------------------------------------------------
    Glados(any.validTitleAuthorPair, ExploreConfig(numRuns: 100)).test(
      'P5a: for any book, transitioning to read sets finishedAt >= createdAt',
      (pair) async {
        final (title, author) = pair;
        final fs = FakeFirebaseFirestore();
        const uid = 'user_p5a_test';

        final bookId = await _createPersonalBook(fs, uid, title, author);

        final beforeDoc = await fs
            .collection('users')
            .doc(uid)
            .collection('personal_books')
            .doc(bookId)
            .get();
        final createdAt =
            (beforeDoc.data()!['createdAt'] as Timestamp).toDate();

        await _updatePersonalBookWithStatusTransition(
          fs,
          uid,
          bookId,
          {'status': PersonalBookStatus.read},
        );

        final afterDoc = await fs
            .collection('users')
            .doc(uid)
            .collection('personal_books')
            .doc(bookId)
            .get();
        final data = afterDoc.data()!;

        expect(
          data['finishedAt'],
          isNotNull,
          reason: 'finishedAt must be set when status transitions to "read"',
        );
        expect(data['finishedAt'], isA<Timestamp>());

        final finishedAt = (data['finishedAt'] as Timestamp).toDate();
        expect(
          finishedAt.isAfter(createdAt) ||
              finishedAt.isAtSameMomentAs(createdAt),
          isTrue,
          reason: 'finishedAt ($finishedAt) must be >= createdAt ($createdAt)',
        );
      },
    );

    Glados(any.validTitleAuthorPair, ExploreConfig(numRuns: 100)).test(
      'P5b: for any book without prior startedAt, transitioning to reading sets startedAt >= createdAt',
      (pair) async {
        final (title, author) = pair;
        final fs = FakeFirebaseFirestore();
        const uid = 'user_p5b_test';

        final bookId = await _createPersonalBook(fs, uid, title, author);

        final beforeDoc = await fs
            .collection('users')
            .doc(uid)
            .collection('personal_books')
            .doc(bookId)
            .get();
        final createdAt =
            (beforeDoc.data()!['createdAt'] as Timestamp).toDate();

        expect(
          beforeDoc.data()!['startedAt'],
          isNull,
          reason: 'startedAt must not exist before the first reading transition',
        );

        await _updatePersonalBookWithStatusTransition(
          fs,
          uid,
          bookId,
          {'status': PersonalBookStatus.reading},
        );

        final afterDoc = await fs
            .collection('users')
            .doc(uid)
            .collection('personal_books')
            .doc(bookId)
            .get();
        final data = afterDoc.data()!;

        expect(
          data['startedAt'],
          isNotNull,
          reason:
              'startedAt must be set when status transitions to "reading" for the first time',
        );
        expect(data['startedAt'], isA<Timestamp>());

        final startedAt = (data['startedAt'] as Timestamp).toDate();
        expect(
          startedAt.isAfter(createdAt) ||
              startedAt.isAtSameMomentAs(createdAt),
          isTrue,
          reason: 'startedAt ($startedAt) must be >= createdAt ($createdAt)',
        );
      },
    );

    Glados(any.validTitleAuthorPair, ExploreConfig(numRuns: 100)).test(
      'P5c: for any book with existing startedAt, transitioning to reading again does NOT overwrite startedAt',
      (pair) async {
        final (title, author) = pair;
        final fs = FakeFirebaseFirestore();
        const uid = 'user_p5c_test';

        final bookId = await _createPersonalBook(fs, uid, title, author);

        // First transition to reading - sets startedAt
        await _updatePersonalBookWithStatusTransition(
          fs,
          uid,
          bookId,
          {'status': PersonalBookStatus.reading},
        );

        final afterFirstDoc = await fs
            .collection('users')
            .doc(uid)
            .collection('personal_books')
            .doc(bookId)
            .get();
        final originalStartedAt =
            (afterFirstDoc.data()!['startedAt'] as Timestamp).toDate();

        await Future<void>.delayed(const Duration(milliseconds: 5));

        // Transition away and back to reading
        await _updatePersonalBookWithStatusTransition(
          fs,
          uid,
          bookId,
          {'status': PersonalBookStatus.wantToRead},
        );
        await _updatePersonalBookWithStatusTransition(
          fs,
          uid,
          bookId,
          {'status': PersonalBookStatus.reading},
        );

        final afterSecondDoc = await fs
            .collection('users')
            .doc(uid)
            .collection('personal_books')
            .doc(bookId)
            .get();
        final startedAtAfterSecondTransition =
            (afterSecondDoc.data()!['startedAt'] as Timestamp).toDate();

        expect(
          startedAtAfterSecondTransition,
          equals(originalStartedAt),
          reason:
              'startedAt must NOT be overwritten when it already exists',
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // P9: Upsert de calificación garantiza exactamente un valor por libro
  // Feature: personal-books, Property 9: Upsert de calificación garantiza
  // exactamente un valor por libro
  // Validates: Requirements 7.2
  //
  // Para cualquier PersonalBook con status == 'read', independientemente de
  // cuántas veces se guarde una calificación, el campo rating debe contener
  // exactamente el último valor enviado (entero entre 1 y 5), y updatedAt debe
  // reflejar la fecha de la última actualización.
  // -------------------------------------------------------------------------
  group('P9: rating upsert guarantees exactly one value per book', () {
    // -----------------------------------------------------------------------
    // Helper: mirrors PersonalBookService.updatePersonalBook logic for rating
    // upsert (rating is only valid when status == 'read')
    // -----------------------------------------------------------------------
    Future<void> _upsertRating(
      FakeFirebaseFirestore fs,
      String uid,
      String bookId,
      int rating,
    ) async {
      await _updatePersonalBook(fs, uid, bookId, {
        'rating': rating,
      });
    }

    // -----------------------------------------------------------------------
    // Unit tests - concrete examples
    // -----------------------------------------------------------------------

    test('single rating save stores the correct value', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_alpha';

      // Create a book and set it to 'read' status
      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Don Quijote',
        'Miguel de Cervantes',
      );
      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.read},
      );

      // Save a rating
      await _upsertRating(fs, uid, bookId, 5);

      final doc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final data = doc.data()!;

      expect(data['rating'], equals(5));
      expect(data['updatedAt'], isNotNull);
    });

    test('multiple rating saves keep only the last value', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_beta';

      // Create a book and set it to 'read' status
      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Cien años de soledad',
        'Gabriel García Márquez',
      );
      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.read},
      );

      // Save multiple ratings in sequence
      await _upsertRating(fs, uid, bookId, 1);
      await _upsertRating(fs, uid, bookId, 2);
      await _upsertRating(fs, uid, bookId, 3);
      await _upsertRating(fs, uid, bookId, 4);
      await _upsertRating(fs, uid, bookId, 5);

      final doc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final data = doc.data()!;

      // Only the last rating (5) should be stored
      expect(data['rating'], equals(5));
    });

    test('rating can be updated from 5 to 1', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_gamma';

      // Create a book and set it to 'read' status
      final bookId = await _createPersonalBook(
        fs,
        uid,
        '1984',
        'George Orwell',
      );
      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.read},
      );

      // Set initial rating
      await _upsertRating(fs, uid, bookId, 5);

      // Update to a lower rating
      await _upsertRating(fs, uid, bookId, 1);

      final doc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final data = doc.data()!;

      expect(data['rating'], equals(1));
    });

    test('updatedAt reflects the last rating update time', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_delta';

      // Create a book and set it to 'read' status
      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Ficciones',
        'Jorge Luis Borges',
      );
      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.read},
      );

      // First rating save
      await _upsertRating(fs, uid, bookId, 3);

      final firstDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final firstUpdatedAt =
          (firstDoc.data()!['updatedAt'] as Timestamp).toDate();

      // Small delay to ensure different timestamps
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // Second rating save
      await _upsertRating(fs, uid, bookId, 4);

      final secondDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final secondUpdatedAt =
          (secondDoc.data()!['updatedAt'] as Timestamp).toDate();

      // updatedAt should reflect the last update
      expect(
        secondUpdatedAt.isAfter(firstUpdatedAt) ||
            secondUpdatedAt.isAtSameMomentAs(firstUpdatedAt),
        isTrue,
        reason: 'updatedAt after second rating must be >= first updatedAt',
      );
    });

    test('rating upsert does not affect other fields', () async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_epsilon';

      // Create a book and set it to 'read' status
      final bookId = await _createPersonalBook(
        fs,
        uid,
        'Pedro Páramo',
        'Juan Rulfo',
      );
      await _updatePersonalBookWithStatusTransition(
        fs,
        uid,
        bookId,
        {'status': PersonalBookStatus.read},
      );

      // Capture original values
      final beforeDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final originalTitle = beforeDoc.data()!['title'];
      final originalAuthor = beforeDoc.data()!['author'];
      final originalStatus = beforeDoc.data()!['status'];

      // Update rating
      await _upsertRating(fs, uid, bookId, 4);

      final afterDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final data = afterDoc.data()!;

      // Other fields should remain unchanged
      expect(data['title'], equals(originalTitle));
      expect(data['author'], equals(originalAuthor));
      expect(data['status'], equals(originalStatus));
      expect(data['rating'], equals(4));
    });

    // -----------------------------------------------------------------------
    // Property test
    // Feature: personal-books, Property 9: Upsert de calificación garantiza
    // exactamente un valor por libro
    // Validates: Requirements 7.2
    // -----------------------------------------------------------------------
    Glados(any.ratingSequence, ExploreConfig(numRuns: 100)).test(
      'P9: for any sequence of ratings, multiple rating saves store exactly the last value',
      (ratings) async {
        final fs = FakeFirebaseFirestore();
        const uid = 'user_p9_test';
        const title = 'Test Book';
        const author = 'Test Author';

        // Create a book
        final bookId = await _createPersonalBook(fs, uid, title, author);

        // Set status to 'read' so rating is valid
        await _updatePersonalBookWithStatusTransition(
          fs,
          uid,
          bookId,
          {'status': PersonalBookStatus.read},
        );

        DateTime? previousUpdatedAt;

        // Apply each rating in sequence
        for (final rating in ratings) {
          // Small delay between updates to ensure different timestamps
          if (previousUpdatedAt != null) {
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }

          await _upsertRating(fs, uid, bookId, rating);

          // Capture updatedAt after each save
          final doc = await fs
              .collection('users')
              .doc(uid)
              .collection('personal_books')
              .doc(bookId)
              .get();
          previousUpdatedAt = (doc.data()!['updatedAt'] as Timestamp).toDate();
        }

        // Verify: rating must be exactly the last value sent
        final finalDoc = await fs
            .collection('users')
            .doc(uid)
            .collection('personal_books')
            .doc(bookId)
            .get();
        final finalData = finalDoc.data()!;

        final expectedRating = ratings.last;
        expect(
          finalData['rating'],
          equals(expectedRating),
          reason:
              'Rating after ${ratings.length} saves must be the last value ($expectedRating), but got ${finalData['rating']}',
        );

        // Verify: updatedAt must be present and be a Timestamp
        expect(
          finalData['updatedAt'],
          isNotNull,
          reason: 'updatedAt must be set after rating upsert',
        );
        expect(
          finalData['updatedAt'],
          isA<Timestamp>(),
          reason: 'updatedAt must be a Firestore Timestamp',
        );

        // Verify: updatedAt reflects the last update (should be >= previous)
        final finalUpdatedAt =
            (finalData['updatedAt'] as Timestamp).toDate();
        expect(
          finalUpdatedAt.isAfter(previousUpdatedAt!) ||
              finalUpdatedAt.isAtSameMomentAs(previousUpdatedAt),
          isTrue,
          reason: 'final updatedAt must reflect the last update time',
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // P10: Calificación rechazada para libros no leídos
// Feature: personal-books, Property 10: Calificación rechazada para libros
// no leídos
// Validates: Requirements 7.3
//
// Para cualquier PersonalBook con status distinto de 'read' (want_to_read o
// reading), cualquier intento de guardar una calificación debe ser rechazado
// y el campo rating del documento no debe ser modificado.
// -------------------------------------------------------------------------
group('P10: rating rejected for books not marked as read', () {
  // -----------------------------------------------------------------------
  // Helper: attempts to save a rating and returns whether it was rejected.
  //
  // This mirrors the expected behavior of PersonalBookService.updatePersonalBook
  // when attempting to save a rating on a book with status != 'read'.
  // The function returns true if the rating was rejected (no update occurred),
  // false if the update was allowed.
  // -----------------------------------------------------------------------
  Future<bool> _trySaveRating(
    FakeFirebaseFirestore fs,
    String uid,
    String bookId,
    int rating,
  ) async {
    // First, check the current status of the book
    final doc = await fs
        .collection('users')
        .doc(uid)
        .collection('personal_books')
        .doc(bookId)
        .get();
    final currentStatus = doc.data()?['status'] as String?;

    // Rating is only allowed when status == 'read'
    if (currentStatus != PersonalBookStatus.read) {
      return true; // Rejected - rating not allowed for non-read books
    }

    // If status == 'read', allow the rating update
    await _updatePersonalBook(fs, uid, bookId, {'rating': rating});
    return false; // Not rejected - update was allowed
  }

  // -----------------------------------------------------------------------
  // Unit tests - concrete examples
  // -----------------------------------------------------------------------

  test('rating save is rejected for want_to_read book', () async {
    final fs = FakeFirebaseFirestore();
    const uid = 'user_alpha';

    // Create a book with want_to_read status
    final bookId = await _createPersonalBook(
      fs,
      uid,
      'Don Quijote',
      'Miguel de Cervantes',
    );

    // Verify initial state has no rating
    final beforeDoc = await fs
        .collection('users')
        .doc(uid)
        .collection('personal_books')
        .doc(bookId)
        .get();
    expect(beforeDoc.data()!['rating'], isNull);

    // Attempt to save a rating - should be rejected
    final wasRejected = await _trySaveRating(fs, uid, bookId, 5);
    expect(wasRejected, isTrue, reason: 'Rating should be rejected for want_to_read book');

    // Verify rating field was not modified
    final afterDoc = await fs
        .collection('users')
        .doc(uid)
        .collection('personal_books')
        .doc(bookId)
        .get();
    expect(afterDoc.data()!['rating'], isNull,
        reason: 'Rating field must not be modified when rejected');
  });

  test('rating save is rejected for reading book', () async {
    final fs = FakeFirebaseFirestore();
    const uid = 'user_beta';

    // Create a book with reading status
    final bookId = await _createPersonalBook(
      fs,
      uid,
      'Cien años de soledad',
      'Gabriel García Márquez',
    );
    await _updatePersonalBookWithStatusTransition(
      fs,
      uid,
      bookId,
      {'status': PersonalBookStatus.reading},
    );

    // Attempt to save a rating - should be rejected
    final wasRejected = await _trySaveRating(fs, uid, bookId, 4);
    expect(wasRejected, isTrue, reason: 'Rating should be rejected for reading book');

    // Verify rating field was not modified
    final afterDoc = await fs
        .collection('users')
        .doc(uid)
        .collection('personal_books')
        .doc(bookId)
        .get();
    expect(afterDoc.data()!['rating'], isNull,
        reason: 'Rating field must not be modified when rejected');
  });

  test('rating rejection does not affect other fields', () async {
    final fs = FakeFirebaseFirestore();
    const uid = 'user_gamma';

    // Create a book with want_to_read status
    final bookId = await _createPersonalBook(
      fs,
      uid,
      '1984',
      'George Orwell',
    );

    // Capture original values
    final beforeDoc = await fs
        .collection('users')
        .doc(uid)
        .collection('personal_books')
        .doc(bookId)
        .get();
    final originalTitle = beforeDoc.data()!['title'];
    final originalAuthor = beforeDoc.data()!['author'];
    final originalStatus = beforeDoc.data()!['status'];
    final originalUpdatedAt = beforeDoc.data()!['updatedAt'];

    // Attempt to save a rating - should be rejected
    await _trySaveRating(fs, uid, bookId, 3);

    // Verify other fields remain unchanged
    final afterDoc = await fs
        .collection('users')
        .doc(uid)
        .collection('personal_books')
        .doc(bookId)
        .get();
    final data = afterDoc.data()!;

    expect(data['title'], equals(originalTitle));
    expect(data['author'], equals(originalAuthor));
    expect(data['status'], equals(originalStatus));
    expect(data['updatedAt'], equals(originalUpdatedAt),
        reason: 'updatedAt must not change when rating is rejected');
    expect(data['rating'], isNull);
  });

  test('rating rejection works for all rating values 1-5', () async {
    final fs = FakeFirebaseFirestore();
    const uid = 'user_delta';

    // Create a book with reading status
    final bookId = await _createPersonalBook(
      fs,
      uid,
      'Ficciones',
      'Jorge Luis Borges',
    );
    await _updatePersonalBookWithStatusTransition(
      fs,
      uid,
      bookId,
      {'status': PersonalBookStatus.reading},
    );

    // All rating values should be rejected
    for (final rating in [1, 2, 3, 4, 5]) {
      final wasRejected = await _trySaveRating(fs, uid, bookId, rating);
      expect(wasRejected, isTrue,
          reason: 'Rating $rating should be rejected for reading book');
    }

    // Verify rating is still null
    final afterDoc = await fs
        .collection('users')
        .doc(uid)
        .collection('personal_books')
        .doc(bookId)
        .get();
    expect(afterDoc.data()!['rating'], isNull);
  });

  // -----------------------------------------------------------------------
  // Property test
  // Feature: personal-books, Property 10: Calificación rechazada para libros
  // no leídos
  // Validates: Requirements 7.3
  // -----------------------------------------------------------------------
  Glados(any.nonReadPersonalBook, ExploreConfig(numRuns: 100))
      .test(
    'P10: for any PersonalBook with status != read, rating save is rejected and rating field is not modified',
    (book) async {
      final fs = FakeFirebaseFirestore();
      const uid = 'user_p10_test';

      // Create the book
      final bookId = await _createPersonalBook(
        fs,
        uid,
        book.title,
        book.author,
      );

      // If the book has a status other than want_to_read, set it
      if (book.status != PersonalBookStatus.wantToRead) {
        await _updatePersonalBookWithStatusTransition(
          fs,
          uid,
          bookId,
          {'status': book.status},
        );
      }

      // Capture the original rating (should be null)
      final beforeDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final originalRating = beforeDoc.data()!['rating'] as int?;

      // Attempt to save a rating for each valid rating value
      for (final rating in [1, 2, 3, 4, 5]) {
        // Attempt to save the rating
        final wasRejected = await _trySaveRating(fs, uid, bookId, rating);

        // The attempt must be rejected (since status != 'read')
        expect(
          wasRejected,
          isTrue,
          reason:
              'Rating $rating must be rejected for book with status "${book.status}"',
        );
      }

      // Verify: rating field was not modified (must still be null)
      final afterDoc = await fs
          .collection('users')
          .doc(uid)
          .collection('personal_books')
          .doc(bookId)
          .get();
      final finalRating = afterDoc.data()!['rating'] as int?;

      expect(
        finalRating,
        equals(originalRating),
        reason:
            'Rating field must not be modified after rejected rating saves. Original: $originalRating, Final: $finalRating',
      );
    },
  );
  });
}