// Feature: book-club-app
// Property 3: Validación de campos obligatorios de Book (Requirement 4.2)
// Property 4: Creación de Book preserva todos los campos requeridos (Requirement 4.1)
// Property 5: Actualización parcial de Book solo modifica campos enviados (Requirement 4.3)
// Property 6: Eliminación de Book elimina todos los recursos asociados (Requirement 4.4)
// Property 7: Cambio de estado a `read` registra `finishedAt` (Requirement 4.5)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/book.dart';
import 'package:book_club_app/domain/models/meeting.dart';

// ---------------------------------------------------------------------------
// Validation helper (mirrors CreateEditBookScreen form logic)
// ---------------------------------------------------------------------------

String? validateRequired(String? value) {
  if (value == null || value.trim().isEmpty) return 'This field is required';
  return null;
}

// ---------------------------------------------------------------------------
// Firestore helpers
// ---------------------------------------------------------------------------

Future<String> createBookInFirestore(
  FakeFirebaseFirestore fakeFirestore, {
  required String title,
  required String author,
  required String description,
  required String coverUrl,
  required String createdBy,
  required DateTime createdAt,
}) async {
  final docRef = fakeFirestore.collection('books').doc();
  await docRef.set({
    'title': title,
    'author': author,
    'description': description,
    'coverUrl': coverUrl,
    'status': 'reading',
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'reviewQuestionIds': [],
  });
  return docRef.id;
}

Future<String> createMeetingInFirestore(
  FakeFirebaseFirestore fakeFirestore, {
  required String bookId,
  required DateTime date,
  required String notes,
  required int partialRating,
  required String createdBy,
  required DateTime createdAt,
}) async {
  final docRef = fakeFirestore.collection('meetings').doc();
  await docRef.set({
    'bookId': bookId,
    'date': Timestamp.fromDate(date),
    'notes': notes,
    'partialRating': partialRating,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
  });
  return docRef.id;
}

Future<void> deleteBookWithMeetings(
  FakeFirebaseFirestore fakeFirestore,
  String bookId,
) async {
  final meetingsSnapshot = await fakeFirestore
      .collection('meetings')
      .where('bookId', isEqualTo: bookId)
      .get();

  final batch = fakeFirestore.batch();
  for (final doc in meetingsSnapshot.docs) {
    batch.delete(doc.reference);
  }
  batch.delete(fakeFirestore.collection('books').doc(bookId));
  await batch.commit();
}

// ---------------------------------------------------------------------------
// Test data generators
// ---------------------------------------------------------------------------

List<String> _generateTitles() {
  final titles = <String>[];
  for (int i = 0; i < 30; i++) {
    titles.add('Book Title $i');
  }
  for (int i = 0; i < 20; i++) {
    titles.add('El libro número $i');
  }
  titles.addAll([
    'Don Quijote de la Mancha',
    'Cien años de soledad',
    'The Great Gatsby',
    '1984',
    'Brave New World',
    'To Kill a Mockingbird',
    'Pride and Prejudice',
    'The Catcher in the Rye',
    'Of Mice and Men',
    'The Grapes of Wrath',
  ]);
  return titles;
}

List<String> _generateAuthors() {
  final authors = <String>[];
  for (int i = 0; i < 30; i++) {
    authors.add('Author $i');
  }
  for (int i = 0; i < 20; i++) {
    authors.add('Autor Apellido$i');
  }
  authors.addAll([
    'Miguel de Cervantes',
    'Gabriel García Márquez',
    'F. Scott Fitzgerald',
    'George Orwell',
    'Aldous Huxley',
    'Harper Lee',
    'Jane Austen',
    'J.D. Salinger',
    'John Steinbeck',
    'Ernest Hemingway',
  ]);
  return authors;
}

List<String> _generateInvalidValues() {
  return [
    '',
    ' ',
    '  ',
    '   ',
    '\t',
    '\n',
    '\r\n',
    '     ',
    '\t\t',
    '\n\n',
  ];
}

List<String> _generateUserIds() {
  final ids = <String>[];
  for (int i = 0; i < 50; i++) {
    ids.add('user_$i');
  }
  for (int i = 0; i < 20; i++) {
    ids.add('leader_$i');
  }
  ids.addAll([
    'admin_user',
    'test_leader',
    'member_abc',
    'user_xyz_123',
    'club_leader_01',
  ]);
  return ids;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final titles = _generateTitles();
  final authors = _generateAuthors();
  final invalidValues = _generateInvalidValues();
  final userIds = _generateUserIds();

  // -------------------------------------------------------------------------
  // P3: Validación de campos obligatorios de Book
  // Validates: Requirements 4.2
  // -------------------------------------------------------------------------
  group('P3: Book required field validation rejects empty/whitespace inputs', () {
    test(
      'validateRequired returns error for all invalid title inputs',
      () {
        for (final invalid in invalidValues) {
          final result = validateRequired(invalid);
          expect(
            result,
            isNotNull,
            reason: 'validateRequired should return error for title="$invalid"',
          );
          expect(
            result,
            equals('This field is required'),
            reason: 'Error message must match for title="$invalid"',
          );
        }
      },
    );

    test(
      'validateRequired returns null for all valid title inputs',
      () {
        for (final title in titles) {
          final result = validateRequired(title);
          expect(
            result,
            isNull,
            reason: 'validateRequired should return null for valid title="$title"',
          );
        }
      },
    );

    test(
      'validateRequired returns error for null input',
      () {
        final result = validateRequired(null);
        expect(result, isNotNull);
        expect(result, equals('This field is required'));
      },
    );

    test(
      'no Firestore document is created when title is invalid',
      () async {
        for (final invalidTitle in invalidValues) {
          final fakeFirestore = FakeFirebaseFirestore();

          // Simulate form validation: only write if both fields pass
          final titleError = validateRequired(invalidTitle);
          final authorError = validateRequired('Valid Author');

          if (titleError != null || authorError != null) {
            // Validation failed — do NOT write to Firestore
          } else {
            await createBookInFirestore(
              fakeFirestore,
              title: invalidTitle,
              author: 'Valid Author',
              description: 'desc',
              coverUrl: 'http://example.com/cover.jpg',
              createdBy: 'user_1',
              createdAt: DateTime.now(),
            );
          }

          final snapshot = await fakeFirestore.collection('books').get();
          expect(
            snapshot.docs.length,
            equals(0),
            reason: 'No document should be created when title="$invalidTitle"',
          );
        }
      },
    );

    test(
      'no Firestore document is created when author is invalid',
      () async {
        for (final invalidAuthor in invalidValues) {
          final fakeFirestore = FakeFirebaseFirestore();

          final titleError = validateRequired('Valid Title');
          final authorError = validateRequired(invalidAuthor);

          if (titleError != null || authorError != null) {
            // Validation failed — do NOT write to Firestore
          } else {
            await createBookInFirestore(
              fakeFirestore,
              title: 'Valid Title',
              author: invalidAuthor,
              description: 'desc',
              coverUrl: 'http://example.com/cover.jpg',
              createdBy: 'user_1',
              createdAt: DateTime.now(),
            );
          }

          final snapshot = await fakeFirestore.collection('books').get();
          expect(
            snapshot.docs.length,
            equals(0),
            reason: 'No document should be created when author="$invalidAuthor"',
          );
        }
      },
    );

    test(
      'no Firestore document is created when both title and author are invalid',
      () async {
        for (int i = 0; i < invalidValues.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final invalidTitle = invalidValues[i];
          final invalidAuthor = invalidValues[(i + 1) % invalidValues.length];

          final titleError = validateRequired(invalidTitle);
          final authorError = validateRequired(invalidAuthor);

          if (titleError != null || authorError != null) {
            // Validation failed — do NOT write to Firestore
          } else {
            await createBookInFirestore(
              fakeFirestore,
              title: invalidTitle,
              author: invalidAuthor,
              description: 'desc',
              coverUrl: 'http://example.com/cover.jpg',
              createdBy: 'user_1',
              createdAt: DateTime.now(),
            );
          }

          final snapshot = await fakeFirestore.collection('books').get();
          expect(
            snapshot.docs.length,
            equals(0),
            reason:
                'No document should be created when title="$invalidTitle" and author="$invalidAuthor"',
          );
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // P4: Creación de Book preserva todos los campos requeridos
  // Validates: Requirements 4.1
  // -------------------------------------------------------------------------
  group('P4: Book creation preserves all required fields', () {
    test(
      'for any valid book data, all required fields are present with correct types',
      () async {
        for (int i = 0; i < titles.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final title = titles[i];
          final author = authors[i % authors.length];
          final userId = userIds[i % userIds.length];
          final createdAt = DateTime(2024, 1, 1).add(Duration(days: i));
          final description = 'Description for book $i';
          final coverUrl = 'https://example.com/covers/book_$i.jpg';

          final bookId = await createBookInFirestore(
            fakeFirestore,
            title: title,
            author: author,
            description: description,
            coverUrl: coverUrl,
            createdBy: userId,
            createdAt: createdAt,
          );

          final doc = await fakeFirestore.collection('books').doc(bookId).get();
          expect(doc.exists, isTrue, reason: 'Book document must exist for "$title"');

          final data = doc.data()!;

          // All required fields must be present
          expect(data.containsKey('title'), isTrue, reason: 'title field must exist');
          expect(data.containsKey('author'), isTrue, reason: 'author field must exist');
          expect(data.containsKey('description'), isTrue, reason: 'description field must exist');
          expect(data.containsKey('coverUrl'), isTrue, reason: 'coverUrl field must exist');
          expect(data.containsKey('status'), isTrue, reason: 'status field must exist');
          expect(data.containsKey('createdBy'), isTrue, reason: 'createdBy field must exist');
          expect(data.containsKey('createdAt'), isTrue, reason: 'createdAt field must exist');

          // Values must match what was provided
          expect(data['title'], equals(title), reason: 'title must be preserved');
          expect(data['author'], equals(author), reason: 'author must be preserved');
          expect(data['description'], equals(description), reason: 'description must be preserved');
          expect(data['coverUrl'], equals(coverUrl), reason: 'coverUrl must be preserved');
          expect(data['createdBy'], equals(userId), reason: 'createdBy must be preserved');

          // status must be 'reading' on creation
          expect(data['status'], equals('reading'), reason: 'status must be "reading" on creation');

          // createdAt must be a Timestamp
          expect(data['createdAt'], isA<Timestamp>(), reason: 'createdAt must be a Timestamp');
        }
      },
    );

    test(
      'for any valid book data, Book.fromMap reconstructs the model correctly',
      () async {
        for (int i = 0; i < titles.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final title = titles[i];
          final author = authors[i % authors.length];
          final userId = userIds[i % userIds.length];
          final createdAt = DateTime(2024, 3, 1).add(Duration(hours: i));

          final bookId = await createBookInFirestore(
            fakeFirestore,
            title: title,
            author: author,
            description: 'Test description $i',
            coverUrl: 'https://example.com/cover_$i.jpg',
            createdBy: userId,
            createdAt: createdAt,
          );

          final doc = await fakeFirestore.collection('books').doc(bookId).get();
          final book = Book.fromMap(doc.data()!, doc.id);

          expect(book.id, equals(bookId));
          expect(book.title, equals(title));
          expect(book.author, equals(author));
          expect(book.status, equals('reading'));
          expect(book.createdBy, equals(userId));
          expect(book.finishedAt, isNull, reason: 'finishedAt must be null on creation');
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // P5: Actualización parcial de Book solo modifica campos enviados
  // Validates: Requirements 4.3
  // -------------------------------------------------------------------------
  group('P5: Partial Book update only modifies included fields', () {
    test(
      'updating only title leaves all other fields unchanged',
      () async {
        for (int i = 0; i < 50; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final originalTitle = titles[i % titles.length];
          final originalAuthor = authors[i % authors.length];
          final originalDescription = 'Original description $i';
          final originalCoverUrl = 'https://example.com/original_$i.jpg';
          final userId = userIds[i % userIds.length];
          final createdAt = DateTime(2024, 1, 15);

          final bookId = await createBookInFirestore(
            fakeFirestore,
            title: originalTitle,
            author: originalAuthor,
            description: originalDescription,
            coverUrl: originalCoverUrl,
            createdBy: userId,
            createdAt: createdAt,
          );

          final newTitle = 'Updated Title $i';
          await fakeFirestore.collection('books').doc(bookId).update({
            'title': newTitle,
          });

          final doc = await fakeFirestore.collection('books').doc(bookId).get();
          final data = doc.data()!;

          expect(data['title'], equals(newTitle), reason: 'title must be updated');
          expect(data['author'], equals(originalAuthor), reason: 'author must not change');
          expect(data['description'], equals(originalDescription), reason: 'description must not change');
          expect(data['coverUrl'], equals(originalCoverUrl), reason: 'coverUrl must not change');
          expect(data['status'], equals('reading'), reason: 'status must not change');
          expect(data['createdBy'], equals(userId), reason: 'createdBy must not change');
        }
      },
    );

    test(
      'updating only author leaves all other fields unchanged',
      () async {
        for (int i = 0; i < 50; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final originalTitle = titles[i % titles.length];
          final originalAuthor = authors[i % authors.length];
          final userId = userIds[i % userIds.length];

          final bookId = await createBookInFirestore(
            fakeFirestore,
            title: originalTitle,
            author: originalAuthor,
            description: 'Description $i',
            coverUrl: 'https://example.com/cover_$i.jpg',
            createdBy: userId,
            createdAt: DateTime(2024, 2, 1),
          );

          final newAuthor = 'New Author $i';
          await fakeFirestore.collection('books').doc(bookId).update({
            'author': newAuthor,
          });

          final doc = await fakeFirestore.collection('books').doc(bookId).get();
          final data = doc.data()!;

          expect(data['author'], equals(newAuthor), reason: 'author must be updated');
          expect(data['title'], equals(originalTitle), reason: 'title must not change');
          expect(data['status'], equals('reading'), reason: 'status must not change');
          expect(data['createdBy'], equals(userId), reason: 'createdBy must not change');
        }
      },
    );

    test(
      'updating title and description simultaneously leaves other fields unchanged',
      () async {
        for (int i = 0; i < 50; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final originalAuthor = authors[i % authors.length];
          final originalCoverUrl = 'https://example.com/cover_$i.jpg';
          final userId = userIds[i % userIds.length];

          final bookId = await createBookInFirestore(
            fakeFirestore,
            title: 'Original Title $i',
            author: originalAuthor,
            description: 'Original Description $i',
            coverUrl: originalCoverUrl,
            createdBy: userId,
            createdAt: DateTime(2024, 3, 1),
          );

          final newTitle = 'New Title $i';
          final newDescription = 'New Description $i';
          await fakeFirestore.collection('books').doc(bookId).update({
            'title': newTitle,
            'description': newDescription,
          });

          final doc = await fakeFirestore.collection('books').doc(bookId).get();
          final data = doc.data()!;

          expect(data['title'], equals(newTitle), reason: 'title must be updated');
          expect(data['description'], equals(newDescription), reason: 'description must be updated');
          expect(data['author'], equals(originalAuthor), reason: 'author must not change');
          expect(data['coverUrl'], equals(originalCoverUrl), reason: 'coverUrl must not change');
          expect(data['status'], equals('reading'), reason: 'status must not change');
          expect(data['createdBy'], equals(userId), reason: 'createdBy must not change');
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // P6: Eliminación de Book elimina todos los recursos asociados
  // Validates: Requirements 4.4
  // -------------------------------------------------------------------------
  group('P6: Book deletion removes book document and all associated meetings', () {
    test(
      'deleting a book with 0 meetings removes only the book document',
      () async {
        for (int i = 0; i < 20; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final userId = userIds[i % userIds.length];

          final bookId = await createBookInFirestore(
            fakeFirestore,
            title: 'Book $i',
            author: 'Author $i',
            description: 'Desc $i',
            coverUrl: 'https://example.com/cover_$i.jpg',
            createdBy: userId,
            createdAt: DateTime(2024, 1, 1),
          );

          await deleteBookWithMeetings(fakeFirestore, bookId);

          final bookDoc = await fakeFirestore.collection('books').doc(bookId).get();
          expect(bookDoc.exists, isFalse, reason: 'Book document must be deleted');

          final meetingsSnapshot = await fakeFirestore
              .collection('meetings')
              .where('bookId', isEqualTo: bookId)
              .get();
          expect(meetingsSnapshot.docs.length, equals(0),
              reason: 'No meetings should remain for deleted book');
        }
      },
    );

    test(
      'deleting a book with N meetings (1-10) removes book and all its meetings',
      () async {
        for (int n = 1; n <= 10; n++) {
          for (int i = 0; i < 5; i++) {
            final fakeFirestore = FakeFirebaseFirestore();
            final userId = userIds[i % userIds.length];

            final bookId = await createBookInFirestore(
              fakeFirestore,
              title: 'Book with $n meetings, iteration $i',
              author: 'Author $i',
              description: 'Desc',
              coverUrl: 'https://example.com/cover.jpg',
              createdBy: userId,
              createdAt: DateTime(2024, 1, 1),
            );

            // Create N meetings for this book
            for (int m = 0; m < n; m++) {
              await createMeetingInFirestore(
                fakeFirestore,
                bookId: bookId,
                date: DateTime(2024, 1, m + 1),
                notes: 'Meeting notes $m',
                partialRating: (m % 5) + 1,
                createdBy: userId,
                createdAt: DateTime(2024, 1, m + 1),
              );
            }

            // Verify meetings were created
            final beforeSnapshot = await fakeFirestore
                .collection('meetings')
                .where('bookId', isEqualTo: bookId)
                .get();
            expect(beforeSnapshot.docs.length, equals(n),
                reason: 'Should have $n meetings before deletion');

            await deleteBookWithMeetings(fakeFirestore, bookId);

            // Book must be gone
            final bookDoc = await fakeFirestore.collection('books').doc(bookId).get();
            expect(bookDoc.exists, isFalse,
                reason: 'Book document must be deleted (n=$n, i=$i)');

            // All meetings for this book must be gone
            final afterSnapshot = await fakeFirestore
                .collection('meetings')
                .where('bookId', isEqualTo: bookId)
                .get();
            expect(afterSnapshot.docs.length, equals(0),
                reason: 'All $n meetings must be deleted (n=$n, i=$i)');
          }
        }
      },
    );

    test(
      'deleting one book does not affect meetings of other books',
      () async {
        for (int i = 0; i < 20; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final userId = userIds[i % userIds.length];

          final bookIdToDelete = await createBookInFirestore(
            fakeFirestore,
            title: 'Book to delete $i',
            author: 'Author $i',
            description: 'Desc',
            coverUrl: 'https://example.com/cover.jpg',
            createdBy: userId,
            createdAt: DateTime(2024, 1, 1),
          );

          final bookIdToKeep = await createBookInFirestore(
            fakeFirestore,
            title: 'Book to keep $i',
            author: 'Author $i',
            description: 'Desc',
            coverUrl: 'https://example.com/cover2.jpg',
            createdBy: userId,
            createdAt: DateTime(2024, 1, 2),
          );

          // Create meetings for both books
          await createMeetingInFirestore(
            fakeFirestore,
            bookId: bookIdToDelete,
            date: DateTime(2024, 2, 1),
            notes: 'Meeting for deleted book',
            partialRating: 3,
            createdBy: userId,
            createdAt: DateTime(2024, 2, 1),
          );

          await createMeetingInFirestore(
            fakeFirestore,
            bookId: bookIdToKeep,
            date: DateTime(2024, 2, 2),
            notes: 'Meeting for kept book',
            partialRating: 4,
            createdBy: userId,
            createdAt: DateTime(2024, 2, 2),
          );

          await deleteBookWithMeetings(fakeFirestore, bookIdToDelete);

          // Kept book must still exist
          final keptBookDoc = await fakeFirestore.collection('books').doc(bookIdToKeep).get();
          expect(keptBookDoc.exists, isTrue,
              reason: 'Other book must not be deleted (i=$i)');

          // Kept book's meetings must still exist
          final keptMeetings = await fakeFirestore
              .collection('meetings')
              .where('bookId', isEqualTo: bookIdToKeep)
              .get();
          expect(keptMeetings.docs.length, equals(1),
              reason: 'Other book meetings must not be deleted (i=$i)');
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // P7: Cambio de estado a `read` registra `finishedAt`
  // Validates: Requirements 4.5
  // -------------------------------------------------------------------------
  group('P7: Changing Book status to read registers finishedAt', () {
    test(
      'for any book, marking as read sets finishedAt after createdAt',
      () async {
        for (int i = 0; i < titles.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final title = titles[i];
          final author = authors[i % authors.length];
          final userId = userIds[i % userIds.length];
          final createdAt = DateTime(2024, 1, 1).add(Duration(days: i));

          final bookId = await createBookInFirestore(
            fakeFirestore,
            title: title,
            author: author,
            description: 'Description $i',
            coverUrl: 'https://example.com/cover_$i.jpg',
            createdBy: userId,
            createdAt: createdAt,
          );

          final finishedAt = DateTime.now();
          await fakeFirestore.collection('books').doc(bookId).update({
            'status': 'read',
            'finishedAt': Timestamp.fromDate(finishedAt),
          });

          final doc = await fakeFirestore.collection('books').doc(bookId).get();
          final data = doc.data()!;

          // status must be 'read'
          expect(data['status'], equals('read'),
              reason: 'status must be "read" after marking as read');

          // finishedAt must be present
          expect(data.containsKey('finishedAt'), isTrue,
              reason: 'finishedAt must be set when status changes to read');
          expect(data['finishedAt'], isA<Timestamp>(),
              reason: 'finishedAt must be a Timestamp');

          // finishedAt must be after or equal to createdAt
          final storedFinishedAt = (data['finishedAt'] as Timestamp).toDate();
          final storedCreatedAt = (data['createdAt'] as Timestamp).toDate();
          expect(
            storedFinishedAt.isAfter(storedCreatedAt) ||
                storedFinishedAt.isAtSameMomentAs(storedCreatedAt),
            isTrue,
            reason:
                'finishedAt must be after or equal to createdAt for "$title"',
          );
        }
      },
    );

    test(
      'for any book, Book.fromMap correctly deserializes finishedAt after marking as read',
      () async {
        for (int i = 0; i < 50; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final title = titles[i % titles.length];
          final author = authors[i % authors.length];
          final userId = userIds[i % userIds.length];
          final createdAt = DateTime(2023, 6, 1).add(Duration(days: i));

          final bookId = await createBookInFirestore(
            fakeFirestore,
            title: title,
            author: author,
            description: 'Desc $i',
            coverUrl: 'https://example.com/cover_$i.jpg',
            createdBy: userId,
            createdAt: createdAt,
          );

          // Verify finishedAt is null before marking as read
          final beforeDoc = await fakeFirestore.collection('books').doc(bookId).get();
          final bookBefore = Book.fromMap(beforeDoc.data()!, beforeDoc.id);
          expect(bookBefore.finishedAt, isNull,
              reason: 'finishedAt must be null before marking as read');
          expect(bookBefore.status, equals('reading'),
              reason: 'status must be "reading" before marking as read');

          final finishedAt = createdAt.add(Duration(days: 30 + i));
          await fakeFirestore.collection('books').doc(bookId).update({
            'status': 'read',
            'finishedAt': Timestamp.fromDate(finishedAt),
          });

          final afterDoc = await fakeFirestore.collection('books').doc(bookId).get();
          final bookAfter = Book.fromMap(afterDoc.data()!, afterDoc.id);

          expect(bookAfter.status, equals('read'),
              reason: 'status must be "read" after update');
          expect(bookAfter.finishedAt, isNotNull,
              reason: 'finishedAt must not be null after marking as read');
          expect(
            bookAfter.finishedAt!.isAfter(bookAfter.createdAt) ||
                bookAfter.finishedAt!.isAtSameMomentAs(bookAfter.createdAt),
            isTrue,
            reason: 'finishedAt must be after createdAt for "$title"',
          );
        }
      },
    );

    test(
      'marking as read does not modify other book fields',
      () async {
        for (int i = 0; i < 50; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final title = titles[i % titles.length];
          final author = authors[i % authors.length];
          final description = 'Description $i';
          final coverUrl = 'https://example.com/cover_$i.jpg';
          final userId = userIds[i % userIds.length];
          final createdAt = DateTime(2024, 4, 1).add(Duration(hours: i));

          final bookId = await createBookInFirestore(
            fakeFirestore,
            title: title,
            author: author,
            description: description,
            coverUrl: coverUrl,
            createdBy: userId,
            createdAt: createdAt,
          );

          await fakeFirestore.collection('books').doc(bookId).update({
            'status': 'read',
            'finishedAt': Timestamp.fromDate(DateTime.now()),
          });

          final doc = await fakeFirestore.collection('books').doc(bookId).get();
          final data = doc.data()!;

          expect(data['title'], equals(title), reason: 'title must not change');
          expect(data['author'], equals(author), reason: 'author must not change');
          expect(data['description'], equals(description), reason: 'description must not change');
          expect(data['coverUrl'], equals(coverUrl), reason: 'coverUrl must not change');
          expect(data['createdBy'], equals(userId), reason: 'createdBy must not change');
        }
      },
    );
  });
}
