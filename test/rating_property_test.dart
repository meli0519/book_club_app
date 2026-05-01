// Feature: book-club-app, Property 13: Upsert de Rating garantiza exactamente un documento por autor

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/rating.dart';

// ---------------------------------------------------------------------------
// Firestore helpers (mirror RatingService upsert logic)
// ---------------------------------------------------------------------------

Future<void> _upsertBookRating(
  FakeFirebaseFirestore fakeFirestore,
  String bookId,
  String authorId,
  int value,
) async {
  await fakeFirestore
      .collection('books')
      .doc(bookId)
      .collection('ratings')
      .doc(authorId)
      .set({'authorId': authorId, 'value': value});
}

Future<void> _upsertMeetingRating(
  FakeFirebaseFirestore fakeFirestore,
  String meetingId,
  String authorId,
  int value,
) async {
  await fakeFirestore
      .collection('meetings')
      .doc(meetingId)
      .collection('ratings')
      .doc(authorId)
      .set({'authorId': authorId, 'value': value});
}

Future<QuerySnapshot> _getBookRatings(
  FakeFirebaseFirestore fakeFirestore,
  String bookId,
) async {
  return fakeFirestore
      .collection('books')
      .doc(bookId)
      .collection('ratings')
      .get();
}

Future<QuerySnapshot> _getMeetingRatings(
  FakeFirebaseFirestore fakeFirestore,
  String meetingId,
) async {
  return fakeFirestore
      .collection('meetings')
      .doc(meetingId)
      .collection('ratings')
      .get();
}

// ---------------------------------------------------------------------------
// Test data generators
// ---------------------------------------------------------------------------

List<String> _generateBookIds() =>
    List.generate(20, (i) => 'book_$i') + ['book_alpha', 'book_beta'];

List<String> _generateMeetingIds() =>
    List.generate(20, (i) => 'meeting_$i') + ['meeting_alpha', 'meeting_beta'];

List<String> _generateAuthorIds() =>
    List.generate(20, (i) => 'user_$i') + ['leader_1', 'member_abc'];

const List<int> _validValues = [1, 2, 3, 4, 5];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final bookIds = _generateBookIds();
  final meetingIds = _generateMeetingIds();
  final authorIds = _generateAuthorIds();

  // Register P14 tests
  _registerP14Tests();

  // -------------------------------------------------------------------------
  // P13: Upsert de Rating garantiza exactamente un documento por autor
  // Validates: Requirements 8.1, 8.2
  // -------------------------------------------------------------------------
  group('P13 - Upsert Rating guarantees exactly one document per author', () {
    test(
      'for any bookId and authorId, multiple upserts result in exactly one document',
      () async {
        for (int i = 0; i < bookIds.length; i++) {
          for (int j = 0; j < authorIds.length; j++) {
            final fakeFirestore = FakeFirebaseFirestore();
            final bookId = bookIds[i];
            final authorId = authorIds[j];

            // Upsert three times with different values
            await _upsertBookRating(fakeFirestore, bookId, authorId, 3);
            await _upsertBookRating(fakeFirestore, bookId, authorId, 5);
            await _upsertBookRating(fakeFirestore, bookId, authorId, 1);

            final snapshot = await _getBookRatings(fakeFirestore, bookId);

            expect(
              snapshot.docs.length,
              equals(1),
              reason:
                  'books/$bookId/ratings must have exactly 1 doc for author $authorId',
            );

            final data = snapshot.docs.first.data() as Map<String, dynamic>;
            expect(data['authorId'], equals(authorId),
                reason: 'authorId must be preserved');
            expect(data['value'], equals(1),
                reason: 'value must be the last submitted value (1)');
          }
        }
      },
    );

    test(
      'for any meetingId and authorId, multiple upserts result in exactly one document',
      () async {
        for (int i = 0; i < meetingIds.length; i++) {
          for (int j = 0; j < authorIds.length; j++) {
            final fakeFirestore = FakeFirebaseFirestore();
            final meetingId = meetingIds[i];
            final authorId = authorIds[j];

            await _upsertMeetingRating(fakeFirestore, meetingId, authorId, 3);
            await _upsertMeetingRating(fakeFirestore, meetingId, authorId, 5);
            await _upsertMeetingRating(fakeFirestore, meetingId, authorId, 1);

            final snapshot =
                await _getMeetingRatings(fakeFirestore, meetingId);

            expect(
              snapshot.docs.length,
              equals(1),
              reason:
                  'meetings/$meetingId/ratings must have exactly 1 doc for author $authorId',
            );

            final data = snapshot.docs.first.data() as Map<String, dynamic>;
            expect(data['authorId'], equals(authorId),
                reason: 'authorId must be preserved');
            expect(data['value'], equals(1),
                reason: 'value must be the last submitted value (1)');
          }
        }
      },
    );

    test(
      'upsert overwrites previous value, not appends',
      () async {
        for (int i = 0; i < bookIds.length; i++) {
          for (int j = 0; j < authorIds.length; j++) {
            final fakeFirestore = FakeFirebaseFirestore();
            final bookId = bookIds[i];
            final authorId = authorIds[j];

            // Submit all values in sequence
            for (final v in _validValues) {
              await _upsertBookRating(fakeFirestore, bookId, authorId, v);
            }

            final snapshot = await _getBookRatings(fakeFirestore, bookId);

            expect(
              snapshot.docs.length,
              equals(1),
              reason:
                  'Exactly 1 document must exist after submitting all values for $authorId in $bookId',
            );

            final data = snapshot.docs.first.data() as Map<String, dynamic>;
            expect(data['value'], equals(5),
                reason: 'value must be 5 (last submitted) for $authorId');
          }
        }
      },
    );

    test(
      'different authors each get their own document',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_multi_author';
        final fiveAuthors = authorIds.take(5).toList();

        for (int i = 0; i < fiveAuthors.length; i++) {
          await _upsertBookRating(
              fakeFirestore, bookId, fiveAuthors[i], _validValues[i]);
        }

        final snapshot = await _getBookRatings(fakeFirestore, bookId);

        expect(
          snapshot.docs.length,
          equals(5),
          reason: 'Subcollection must have exactly 5 documents (one per author)',
        );

        for (int i = 0; i < fiveAuthors.length; i++) {
          final authorId = fiveAuthors[i];
          final expectedValue = _validValues[i];
          final doc = snapshot.docs.firstWhere(
            (d) => (d.data() as Map<String, dynamic>)['authorId'] == authorId,
            orElse: () => throw TestFailure(
                'No document found for authorId=$authorId'),
          );
          final data = doc.data() as Map<String, dynamic>;
          expect(data['authorId'], equals(authorId),
              reason: 'authorId must match for $authorId');
          expect(data['value'], equals(expectedValue),
              reason: 'value must match for $authorId');
        }
      },
    );

    test(
      'Rating.fromMap/toMap round-trip preserves all fields',
      () {
        for (final authorId in authorIds) {
          for (final value in _validValues) {
            final original = Rating(authorId: authorId, value: value);
            final map = original.toMap();
            final restored = Rating.fromMap(map, authorId);

            expect(restored.authorId, equals(authorId),
                reason: 'authorId must survive round-trip for $authorId');
            expect(restored.value, equals(value),
                reason: 'value must survive round-trip for value=$value');
          }
        }
      },
    );

    test(
      'upsert for books does not affect meetings subcollection and vice versa',
      () async {
        for (int i = 0; i < bookIds.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final bookId = bookIds[i];
          final meetingId = meetingIds[i % meetingIds.length];
          final authorId = authorIds[i % authorIds.length];

          await _upsertBookRating(fakeFirestore, bookId, authorId, 4);
          await _upsertMeetingRating(fakeFirestore, meetingId, authorId, 2);

          final bookSnapshot = await _getBookRatings(fakeFirestore, bookId);
          final meetingSnapshot =
              await _getMeetingRatings(fakeFirestore, meetingId);

          expect(
            bookSnapshot.docs.length,
            equals(1),
            reason: 'books/$bookId/ratings must have exactly 1 doc',
          );
          expect(
            meetingSnapshot.docs.length,
            equals(1),
            reason: 'meetings/$meetingId/ratings must have exactly 1 doc',
          );

          final bookData =
              bookSnapshot.docs.first.data() as Map<String, dynamic>;
          final meetingData =
              meetingSnapshot.docs.first.data() as Map<String, dynamic>;

          expect(bookData['value'], equals(4),
              reason: 'book rating value must be 4');
          expect(meetingData['value'], equals(2),
              reason: 'meeting rating value must be 2');
        }
      },
    );
  });
}

// ---------------------------------------------------------------------------
// P14: Cálculo de promedio de calificaciones redondeado a un decimal
// Validates: Requirement 8.4
// ---------------------------------------------------------------------------

/// Pure Dart average function mirroring rating_service.dart formula.
double? _computeAverage(List<int> values) {
  if (values.isEmpty) return null;
  final sum = values.reduce((a, b) => a + b);
  final avg = sum / values.length;
  return (avg * 10).round() / 10;
}

/// Varied rating sets used across multiple test cases.
final List<List<int>> _ratingCombinations = [
  [1], [2], [3], [4], [5],
  [1, 5], [2, 4], [3, 3], [1, 2], [4, 5],
  [1, 2, 3], [3, 4, 5], [1, 3, 5],
  [1, 1, 1, 1, 1], [5, 5, 5, 5, 5],
  [1, 2, 3, 4, 5],
  [1, 1, 1, 1, 2], [2, 2, 2, 2, 3],
  [1, 5, 1, 5, 1], [3, 3, 3, 3, 4],
  List.generate(10, (i) => (i % 5) + 1),
  List.generate(20, (i) => (i % 3) + 1),
  List.generate(50, (i) => (i % 5) + 1),
  List.generate(100, (i) => (i % 5) + 1),
];

// Appended to main() via a separate group — we use a top-level function
// so the group can be called from a standalone test runner.
void _registerP14Tests() {
  group('P14 - Average rating calculation rounded to 1 decimal', () {
    // -----------------------------------------------------------------------
    // 1. Arithmetic mean of any set of 1-5 values is rounded to exactly 1 decimal
    // -----------------------------------------------------------------------
    test(
      'arithmetic mean of any set of 1-5 values is rounded to exactly 1 decimal',
      () {
        // Build a large set of combinations (>100) imperatively
        final allCombinations = <List<int>>[..._ratingCombinations];
        // All pairs (a, b) where a,b in 1..5 → 25 entries
        for (int a = 1; a <= 5; a++) {
          for (int b = 1; b <= 5; b++) {
            allCombinations.add([a, b]);
          }
        }
        // All triples (a, b, c) where a,b,c in {1,3,5} → 27 entries
        for (int a = 1; a <= 5; a += 2) {
          for (int b = 1; b <= 5; b += 2) {
            for (int c = 1; c <= 5; c += 2) {
              allCombinations.add([a, b, c]);
            }
          }
        }
        // All 4-element lists with values in {1,2,3,4,5} stepping by 2 → 25 entries
        for (int a = 1; a <= 5; a++) {
          for (int b = 1; b <= 5; b++) {
            allCombinations.add([a, b, a, b]);
          }
        }
        // Extra varied lists
        allCombinations.addAll([
          [1, 2, 3, 4, 5, 1, 2, 3, 4, 5],
          [5, 4, 3, 2, 1],
          [2, 3, 4],
          [1, 4, 2, 5, 3],
          List.generate(30, (i) => (i % 4) + 1),
          List.generate(40, (i) => (i % 2) + 1),
          List.generate(60, (i) => (i % 5) + 1),
          List.generate(80, (i) => (i % 3) + 2),
        ]);

        expect(allCombinations.length, greaterThanOrEqualTo(100),
            reason: 'Must test at least 100 combinations');

        for (final values in allCombinations) {
          final result = _computeAverage(values);
          expect(result, isNotNull,
              reason: 'Non-empty list must return a non-null average');

          // Verify at most 1 decimal place: (result * 10) must be an integer
          final tenTimes = result! * 10;
          expect(tenTimes, closeTo(tenTimes.roundToDouble(), 1e-9),
              reason:
                  'Average $result for $values must have at most 1 decimal place');

          // Verify it equals the expected rounded value
          final sum = values.reduce((a, b) => a + b);
          final expected = (sum / values.length * 10).round() / 10;
          expect(result, equals(expected),
              reason:
                  'Average for $values must equal expected $expected, got $result');
        }
      },
    );

    // -----------------------------------------------------------------------
    // 2. Average via Firestore subcollection matches pure Dart calculation
    // -----------------------------------------------------------------------
    test(
      'average via Firestore subcollection matches pure Dart calculation',
      () async {
        // Use at least 20 different rating sets
        final setsToTest = _ratingCombinations.take(20).toList();
        expect(setsToTest.length, greaterThanOrEqualTo(20));

        for (int i = 0; i < setsToTest.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final bookId = 'book_p14_$i';
          final values = setsToTest[i];

          // Store each rating in books/{bookId}/ratings/{authorId}
          for (int j = 0; j < values.length; j++) {
            final authorId = 'author_$j';
            await fakeFirestore
                .collection('books')
                .doc(bookId)
                .collection('ratings')
                .doc(authorId)
                .set({'authorId': authorId, 'value': values[j]});
          }

          // Fetch all docs and compute average using the same formula as rating_service.dart
          final snapshot = await fakeFirestore
              .collection('books')
              .doc(bookId)
              .collection('ratings')
              .get();

          expect(snapshot.docs.length, equals(values.length),
              reason: 'Must have ${values.length} rating docs for bookId=$bookId');

          final fetchedValues = snapshot.docs
              .map((doc) => (doc.data()['value'] as num).toDouble())
              .toList();
          final avg = fetchedValues.reduce((a, b) => a + b) / fetchedValues.length;
          final firestoreAvg = (avg * 10).round() / 10;

          final expectedAvg = _computeAverage(values);
          expect(firestoreAvg, equals(expectedAvg),
              reason:
                  'Firestore average $firestoreAvg must match pure Dart average $expectedAvg for $values');
        }
      },
    );

    // -----------------------------------------------------------------------
    // 3. Empty subcollection returns null (no ratings yet)
    // -----------------------------------------------------------------------
    test(
      'empty subcollection returns null (no ratings yet)',
      () async {
        final bookIds = List.generate(10, (i) => 'empty_book_$i');
        final meetingIds = List.generate(10, (i) => 'empty_meeting_$i');

        for (final bookId in bookIds) {
          final fakeFirestore = FakeFirebaseFirestore();
          final snapshot = await fakeFirestore
              .collection('books')
              .doc(bookId)
              .collection('ratings')
              .get();

          final result = snapshot.docs.isEmpty
              ? null
              : _computeAverage(snapshot.docs
                  .map((d) => (d.data()['value'] as num).toInt())
                  .toList());

          expect(result, isNull,
              reason: 'Empty subcollection for $bookId must return null');
        }

        for (final meetingId in meetingIds) {
          final fakeFirestore = FakeFirebaseFirestore();
          final snapshot = await fakeFirestore
              .collection('meetings')
              .doc(meetingId)
              .collection('ratings')
              .get();

          final result = snapshot.docs.isEmpty
              ? null
              : _computeAverage(snapshot.docs
                  .map((d) => (d.data()['value'] as num).toInt())
                  .toList());

          expect(result, isNull,
              reason: 'Empty subcollection for $meetingId must return null');
        }
      },
    );

    // -----------------------------------------------------------------------
    // 4. Single rating returns that value as the average
    // -----------------------------------------------------------------------
    test(
      'single rating returns that value as the average',
      () async {
        final singleValues = [1, 2, 3, 4, 5];
        final bookIds = List.generate(10, (i) => 'single_book_$i');

        for (int i = 0; i < singleValues.length; i++) {
          for (final bookId in bookIds) {
            final fakeFirestore = FakeFirebaseFirestore();
            final value = singleValues[i];

            await fakeFirestore
                .collection('books')
                .doc(bookId)
                .collection('ratings')
                .doc('author_single')
                .set({'authorId': 'author_single', 'value': value});

            final snapshot = await fakeFirestore
                .collection('books')
                .doc(bookId)
                .collection('ratings')
                .get();

            final fetchedValues = snapshot.docs
                .map((d) => (d.data()['value'] as num).toInt())
                .toList();
            final avg = _computeAverage(fetchedValues);

            expect(avg, equals(value.toDouble()),
                reason:
                    'Single rating $value must yield average ${value.toDouble()}, got $avg');
          }
        }
      },
    );

    // -----------------------------------------------------------------------
    // 5. Boundary: [1, 5] average is 3.0
    // -----------------------------------------------------------------------
    test(
      'boundary: [1,5] average is 3.0',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_boundary_1_5';

        await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('ratings')
            .doc('author_1')
            .set({'authorId': 'author_1', 'value': 1});
        await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('ratings')
            .doc('author_2')
            .set({'authorId': 'author_2', 'value': 5});

        final snapshot = await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('ratings')
            .get();

        final values =
            snapshot.docs.map((d) => (d.data()['value'] as num).toInt()).toList();
        final avg = _computeAverage(values);

        expect(avg, equals(3.0), reason: '[1,5] average must be 3.0');
      },
    );

    // -----------------------------------------------------------------------
    // 6. Boundary: [1, 2] average is 1.5
    // -----------------------------------------------------------------------
    test(
      'boundary: [1,2] average is 1.5',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_boundary_1_2';

        await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('ratings')
            .doc('author_1')
            .set({'authorId': 'author_1', 'value': 1});
        await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('ratings')
            .doc('author_2')
            .set({'authorId': 'author_2', 'value': 2});

        final snapshot = await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('ratings')
            .get();

        final values =
            snapshot.docs.map((d) => (d.data()['value'] as num).toInt()).toList();
        final avg = _computeAverage(values);

        expect(avg, equals(1.5), reason: '[1,2] average must be 1.5');
      },
    );

    // -----------------------------------------------------------------------
    // 7. Boundary: [1,1,1,1,2] average is 1.2
    // -----------------------------------------------------------------------
    test(
      'boundary: [1,1,1,1,2] average is 1.2',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_boundary_1_1_1_1_2';
        final ratingValues = [1, 1, 1, 1, 2];

        for (int i = 0; i < ratingValues.length; i++) {
          await fakeFirestore
              .collection('books')
              .doc(bookId)
              .collection('ratings')
              .doc('author_$i')
              .set({'authorId': 'author_$i', 'value': ratingValues[i]});
        }

        final snapshot = await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('ratings')
            .get();

        final values =
            snapshot.docs.map((d) => (d.data()['value'] as num).toInt()).toList();
        final avg = _computeAverage(values);

        expect(avg, equals(1.2), reason: '[1,1,1,1,2] average must be 1.2');
      },
    );
  });
}
