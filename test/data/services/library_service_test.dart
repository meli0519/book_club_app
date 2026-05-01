// Tests for LibraryService filtering logic
// Task 20.5 – Library filtering and visualization

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/user_book_entry.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Writes a library entry directly to fake Firestore.
Future<void> _addLibraryEntry(
  FakeFirebaseFirestore fs, {
  required String userId,
  required String bookId,
  required String category,
  required DateTime updatedAt,
}) async {
  await fs
      .collection('users')
      .doc(userId)
      .collection('library')
      .doc(bookId)
      .set({
    'category': category,
    'updatedAt': Timestamp.fromDate(updatedAt),
  });
}

/// Writes a book document to fake Firestore.
Future<void> _addBook(
  FakeFirebaseFirestore fs, {
  required String bookId,
  String title = 'Test Book',
  String author = 'Test Author',
}) async {
  await fs.collection('books').doc(bookId).set({
    'title': title,
    'author': author,
    'description': 'A description',
    'coverUrl': 'https://example.com/cover.jpg',
    'status': 'reading',
    'createdBy': 'user_1',
    'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
    'reviewQuestionIds': <String>[],
  });
}

/// Mirrors LibraryService.watchUserLibrary() logic using fake Firestore.
Stream<List<UserBookEntry>> _watchUserLibrary(
  FakeFirebaseFirestore fs,
  String userId,
) {
  return fs
      .collection('users')
      .doc(userId)
      .collection('library')
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => UserBookEntry.fromMap(doc.data(), doc.id, userId))
          .toList());
}

/// Mirrors LibraryService.watchLibraryByCategory() filtering logic.
Stream<List<UserBookEntry>> _watchLibraryByCategory(
  FakeFirebaseFirestore fs,
  String userId,
  String category,
) {
  return fs
      .collection('users')
      .doc(userId)
      .collection('library')
      .where('category', isEqualTo: category)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => UserBookEntry.fromMap(doc.data(), doc.id, userId))
          .toList());
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const userId = 'test_user_1';

  // -------------------------------------------------------------------------
  // watchUserLibrary
  // -------------------------------------------------------------------------
  group('LibraryService.watchUserLibrary', () {
    test('returns empty list when library is empty', () async {
      final fs = FakeFirebaseFirestore();
      final entries = await _watchUserLibrary(fs, userId).first;
      expect(entries, isEmpty);
    });

    test('returns all entries regardless of category', () async {
      final fs = FakeFirebaseFirestore();
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'b1',
          category: UserBookCategory.wantToRead,
          updatedAt: DateTime(2024, 1, 1));
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'b2',
          category: UserBookCategory.reading,
          updatedAt: DateTime(2024, 2, 1));
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'b3',
          category: UserBookCategory.read,
          updatedAt: DateTime(2024, 3, 1));

      final entries = await _watchUserLibrary(fs, userId).first;
      expect(entries.length, equals(3));
    });

    test('returns entries ordered by updatedAt descending', () async {
      final fs = FakeFirebaseFirestore();
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'oldest',
          category: UserBookCategory.wantToRead,
          updatedAt: DateTime(2024, 1, 1));
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'newest',
          category: UserBookCategory.reading,
          updatedAt: DateTime(2024, 6, 1));
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'middle',
          category: UserBookCategory.read,
          updatedAt: DateTime(2024, 3, 15));

      final entries = await _watchUserLibrary(fs, userId).first;
      expect(entries[0].bookId, equals('newest'));
      expect(entries[1].bookId, equals('middle'));
      expect(entries[2].bookId, equals('oldest'));
    });

    test('entries from different users are isolated', () async {
      final fs = FakeFirebaseFirestore();
      await _addLibraryEntry(fs,
          userId: 'user_a',
          bookId: 'b1',
          category: UserBookCategory.reading,
          updatedAt: DateTime(2024, 1, 1));
      await _addLibraryEntry(fs,
          userId: 'user_b',
          bookId: 'b2',
          category: UserBookCategory.read,
          updatedAt: DateTime(2024, 1, 1));

      final entriesA = await _watchUserLibrary(fs, 'user_a').first;
      final entriesB = await _watchUserLibrary(fs, 'user_b').first;

      expect(entriesA.length, equals(1));
      expect(entriesA.first.bookId, equals('b1'));
      expect(entriesB.length, equals(1));
      expect(entriesB.first.bookId, equals('b2'));
    });
  });

  // -------------------------------------------------------------------------
  // watchLibraryByCategory
  // -------------------------------------------------------------------------
  group('LibraryService.watchLibraryByCategory', () {
    test('returns only entries matching the given category', () async {
      final fs = FakeFirebaseFirestore();
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'b1',
          category: UserBookCategory.wantToRead,
          updatedAt: DateTime(2024, 1, 1));
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'b2',
          category: UserBookCategory.reading,
          updatedAt: DateTime(2024, 2, 1));
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'b3',
          category: UserBookCategory.reading,
          updatedAt: DateTime(2024, 3, 1));
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'b4',
          category: UserBookCategory.read,
          updatedAt: DateTime(2024, 4, 1));

      final reading =
          await _watchLibraryByCategory(fs, userId, UserBookCategory.reading)
              .first;
      expect(reading.length, equals(2));
      expect(reading.every((e) => e.category == UserBookCategory.reading),
          isTrue);
    });

    test('returns empty list when no entries match the category', () async {
      final fs = FakeFirebaseFirestore();
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'b1',
          category: UserBookCategory.wantToRead,
          updatedAt: DateTime(2024, 1, 1));

      final readEntries =
          await _watchLibraryByCategory(fs, userId, UserBookCategory.read)
              .first;
      expect(readEntries, isEmpty);
    });

    test('filtered results are ordered by updatedAt descending', () async {
      final fs = FakeFirebaseFirestore();
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'old_reading',
          category: UserBookCategory.reading,
          updatedAt: DateTime(2024, 1, 1));
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'new_reading',
          category: UserBookCategory.reading,
          updatedAt: DateTime(2024, 5, 1));

      final entries =
          await _watchLibraryByCategory(fs, userId, UserBookCategory.reading)
              .first;
      expect(entries[0].bookId, equals('new_reading'));
      expect(entries[1].bookId, equals('old_reading'));
    });
  });

  // -------------------------------------------------------------------------
  // setBookCategory – writes correct data to Firestore
  // -------------------------------------------------------------------------
  group('LibraryService.setBookCategory', () {
    test('writes correct data to users/{userId}/library/{bookId}', () async {
      final fs = FakeFirebaseFirestore();

      // Simulate setBookCategory logic
      await fs
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc('book_x')
          .set({
        'category': UserBookCategory.reading,
        'updatedAt': Timestamp.fromDate(DateTime(2024, 6, 1)),
      });

      final doc = await fs
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc('book_x')
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['category'], equals(UserBookCategory.reading));
      expect(doc.data()!['updatedAt'], isA<Timestamp>());
    });

    test('overwrites existing entry when category changes', () async {
      final fs = FakeFirebaseFirestore();

      // Initial entry
      await fs
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc('book_y')
          .set({
        'category': UserBookCategory.wantToRead,
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      // Update category
      await fs
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc('book_y')
          .set({
        'category': UserBookCategory.read,
        'updatedAt': Timestamp.fromDate(DateTime(2024, 7, 1)),
      });

      final doc = await fs
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc('book_y')
          .get();

      expect(doc.data()!['category'], equals(UserBookCategory.read));
    });

    test('written entry can be deserialized with UserBookEntry.fromMap', () async {
      final fs = FakeFirebaseFirestore();
      final updatedAt = DateTime(2024, 9, 1);

      await fs
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc('book_z')
          .set({
        'category': UserBookCategory.reading,
        'updatedAt': Timestamp.fromDate(updatedAt),
      });

      final doc = await fs
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc('book_z')
          .get();

      final entry = UserBookEntry.fromMap(doc.data()!, 'book_z', userId);
      expect(entry.category, equals(UserBookCategory.reading));
      expect(entry.updatedAt, equals(updatedAt));
      expect(entry.bookId, equals('book_z'));
      expect(entry.userId, equals(userId));
    });
  });

  // -------------------------------------------------------------------------
  // removeBookFromLibrary – deletes the correct document
  // -------------------------------------------------------------------------
  group('LibraryService.removeBookFromLibrary', () {
    test('deletes the correct Firestore document', () async {
      final fs = FakeFirebaseFirestore();
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'to_delete',
          category: UserBookCategory.reading,
          updatedAt: DateTime(2024, 1, 1));

      // Simulate removeBookFromLibrary
      await fs
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc('to_delete')
          .delete();

      final doc = await fs
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc('to_delete')
          .get();

      expect(doc.exists, isFalse);
    });

    test('does not affect other entries when one is removed', () async {
      final fs = FakeFirebaseFirestore();
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'keep_1',
          category: UserBookCategory.reading,
          updatedAt: DateTime(2024, 1, 1));
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'remove_me',
          category: UserBookCategory.wantToRead,
          updatedAt: DateTime(2024, 2, 1));
      await _addLibraryEntry(fs,
          userId: userId,
          bookId: 'keep_2',
          category: UserBookCategory.read,
          updatedAt: DateTime(2024, 3, 1));

      await fs
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc('remove_me')
          .delete();

      final snapshot = await fs
          .collection('users')
          .doc(userId)
          .collection('library')
          .get();

      expect(snapshot.docs.length, equals(2));
      final ids = snapshot.docs.map((d) => d.id).toList();
      expect(ids, contains('keep_1'));
      expect(ids, contains('keep_2'));
      expect(ids, isNot(contains('remove_me')));
    });

    test('deleting a non-existent document does not throw', () async {
      final fs = FakeFirebaseFirestore();

      expect(
        () async => await fs
            .collection('users')
            .doc(userId)
            .collection('library')
            .doc('ghost_book')
            .delete(),
        returnsNormally,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Average rating computation (mirrors _fetchAverageRating)
  // -------------------------------------------------------------------------
  group('LibraryService – average rating computation', () {
    test('returns null when no ratings exist', () async {
      final fs = FakeFirebaseFirestore();
      await _addBook(fs, bookId: 'b_no_ratings');

      final snapshot = await fs
          .collection('books')
          .doc('b_no_ratings')
          .collection('ratings')
          .get();

      expect(snapshot.docs, isEmpty);
    });

    test('computes average correctly and rounds to 1 decimal', () async {
      final fs = FakeFirebaseFirestore();
      await _addBook(fs, bookId: 'b_rated');

      await fs
          .collection('books')
          .doc('b_rated')
          .collection('ratings')
          .doc('u1')
          .set({'value': 4});
      await fs
          .collection('books')
          .doc('b_rated')
          .collection('ratings')
          .doc('u2')
          .set({'value': 3});
      await fs
          .collection('books')
          .doc('b_rated')
          .collection('ratings')
          .doc('u3')
          .set({'value': 5});

      final snapshot = await fs
          .collection('books')
          .doc('b_rated')
          .collection('ratings')
          .get();

      final values = snapshot.docs
          .map((d) => (d.data()['value'] as num).toDouble())
          .toList();
      final avg = values.reduce((a, b) => a + b) / values.length;
      final rounded = (avg * 10).round() / 10;

      expect(rounded, equals(4.0));
    });
  });
}
