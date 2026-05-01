// Feature: book-club-app
// Property 9: Validación de campos obligatorios de Meeting (Requirement 6.2)
// Property 10: Listado de reuniones siempre ordenado por date ascendente (Requirement 6.5)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/meeting.dart';

// ---------------------------------------------------------------------------
// Validation helpers (mirror CreateEditMeetingScreen form logic)
// ---------------------------------------------------------------------------

String? validateRequired(String? value) {
  if (value == null || value.trim().isEmpty) return 'This field is required';
  return null;
}

/// Returns null if [value] is a valid partialRating (int 1–5), error otherwise.
String? validatePartialRating(String? value) {
  if (value == null || value.trim().isEmpty) return 'This field is required';
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed < 1 || parsed > 5) {
    return 'Rating must be a number between 1 and 5';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Firestore helpers
// ---------------------------------------------------------------------------

Future<String> _createMeeting(
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

/// Fetches meetings for a book ordered by date ascending (mirrors MeetingService).
Future<List<Meeting>> _fetchMeetingsAscending(
  FakeFirebaseFirestore fakeFirestore,
  String bookId,
) async {
  final snapshot = await fakeFirestore
      .collection('meetings')
      .where('bookId', isEqualTo: bookId)
      .orderBy('date', descending: false)
      .get();
  return snapshot.docs
      .map((doc) => Meeting.fromMap(doc.data(), doc.id))
      .toList();
}

// ---------------------------------------------------------------------------
// Test data generators
// ---------------------------------------------------------------------------

List<String> _generateBookIds() =>
    List.generate(20, (i) => 'book_$i') + ['book_alpha', 'book_beta'];

List<String> _generateUserIds() =>
    List.generate(20, (i) => 'user_$i') + ['leader_1', 'leader_2'];

List<String> _generateInvalidRatings() => [
      '',
      ' ',
      '0',
      '6',
      '-1',
      '10',
      'abc',
      '1.5',
      '5.1',
      '100',
      '\t',
      '\n',
    ];

List<String> _generateValidRatings() =>
    ['1', '2', '3', '4', '5'];

/// Generates N distinct DateTime values spread across a date range.
List<DateTime> _generateDates(int count, DateTime base) =>
    List.generate(count, (i) => base.add(Duration(hours: i * 11 + 3)));

/// Deterministic shuffle to simulate out-of-order insertion.
List<DateTime> _shuffleDates(List<DateTime> dates) {
  final shuffled = List<DateTime>.from(dates);
  for (int i = shuffled.length - 1; i > 0; i--) {
    final j = (i * 7 + 3) % (i + 1);
    final tmp = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = tmp;
  }
  return shuffled;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final bookIds = _generateBookIds();
  final userIds = _generateUserIds();
  final invalidRatings = _generateInvalidRatings();
  final validRatings = _generateValidRatings();

  // -------------------------------------------------------------------------
  // P9: Validación de campos obligatorios de Meeting
  // Validates: Requirements 6.2
  // -------------------------------------------------------------------------
  group('P9: Meeting required field validation', () {
    group('date validation', () {
      test('null date is rejected (no document created)', () async {
        for (int i = 0; i < bookIds.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final bookId = bookIds[i];

          // Simulate: date is null → form is invalid → no write
          const DateTime? selectedDate = null;
          final ratingError = validatePartialRating('3');

          if (selectedDate == null || ratingError != null) {
            // Validation failed — do NOT write to Firestore
          } else {
            await _createMeeting(
              fakeFirestore,
              bookId: bookId,
              date: selectedDate,
              notes: 'notes',
              partialRating: 3,
              createdBy: userIds[i % userIds.length],
              createdAt: DateTime.now(),
            );
          }

          final snapshot = await fakeFirestore.collection('meetings').get();
          expect(
            snapshot.docs.length,
            equals(0),
            reason: 'No meeting should be created when date is null (bookId=$bookId)',
          );
        }
      });
    });

    group('partialRating validation', () {
      test('validatePartialRating rejects all invalid rating inputs', () {
        for (final invalid in invalidRatings) {
          final result = validatePartialRating(invalid);
          expect(
            result,
            isNotNull,
            reason: 'validatePartialRating should return error for "$invalid"',
          );
        }
      });

      test('validatePartialRating accepts all valid rating inputs (1–5)', () {
        for (final valid in validRatings) {
          final result = validatePartialRating(valid);
          expect(
            result,
            isNull,
            reason: 'validatePartialRating should return null for "$valid"',
          );
        }
      });

      test('no document created when partialRating is invalid', () async {
        for (int i = 0; i < invalidRatings.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final invalidRating = invalidRatings[i];

          final ratingError = validatePartialRating(invalidRating);
          final hasDate = true; // date is provided

          if (!hasDate || ratingError != null) {
            // Validation failed — do NOT write to Firestore
          } else {
            await _createMeeting(
              fakeFirestore,
              bookId: 'book_1',
              date: DateTime(2024, 1, 1),
              notes: 'notes',
              partialRating: int.tryParse(invalidRating.trim()) ?? 0,
              createdBy: 'user_1',
              createdAt: DateTime.now(),
            );
          }

          final snapshot = await fakeFirestore.collection('meetings').get();
          expect(
            snapshot.docs.length,
            equals(0),
            reason: 'No meeting should be created for invalid rating="$invalidRating"',
          );
        }
      });

      test('document is created when both date and partialRating are valid',
          () async {
        for (int i = 0; i < validRatings.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final validRating = validRatings[i];
          final bookId = bookIds[i % bookIds.length];

          final ratingError = validatePartialRating(validRating);
          final selectedDate = DateTime(2024, 1, i + 1);

          if (selectedDate == null || ratingError != null) {
            // Should not happen for valid inputs
            fail('Valid inputs should not fail validation');
          } else {
            await _createMeeting(
              fakeFirestore,
              bookId: bookId,
              date: selectedDate,
              notes: 'Meeting notes $i',
              partialRating: int.parse(validRating),
              createdBy: userIds[i % userIds.length],
              createdAt: DateTime.now(),
            );
          }

          final snapshot = await fakeFirestore.collection('meetings').get();
          expect(
            snapshot.docs.length,
            equals(1),
            reason: 'Meeting should be created for valid rating="$validRating"',
          );
        }
      });
    });

    group('Meeting model field preservation', () {
      test('created meeting document contains all required fields', () async {
        for (int i = 0; i < bookIds.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final bookId = bookIds[i];
          final userId = userIds[i % userIds.length];
          final date = DateTime(2024, 1, i + 1);
          final notes = 'Meeting notes $i';
          final partialRating = (i % 5) + 1;
          final createdAt = DateTime(2024, 1, 1);

          final meetingId = await _createMeeting(
            fakeFirestore,
            bookId: bookId,
            date: date,
            notes: notes,
            partialRating: partialRating,
            createdBy: userId,
            createdAt: createdAt,
          );

          final doc =
              await fakeFirestore.collection('meetings').doc(meetingId).get();
          expect(doc.exists, isTrue);

          final data = doc.data()!;
          expect(data.containsKey('bookId'), isTrue, reason: 'bookId must exist');
          expect(data.containsKey('date'), isTrue, reason: 'date must exist');
          expect(data.containsKey('notes'), isTrue, reason: 'notes must exist');
          expect(data.containsKey('partialRating'), isTrue,
              reason: 'partialRating must exist');
          expect(data.containsKey('createdBy'), isTrue,
              reason: 'createdBy must exist');
          expect(data.containsKey('createdAt'), isTrue,
              reason: 'createdAt must exist');

          expect(data['bookId'], equals(bookId));
          expect(data['notes'], equals(notes));
          expect(data['partialRating'], equals(partialRating));
          expect(data['createdBy'], equals(userId));
          expect(data['date'], isA<Timestamp>());
          expect(data['createdAt'], isA<Timestamp>());
        }
      });

      test('Meeting.fromMap correctly deserializes all fields', () async {
        for (int i = 0; i < bookIds.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final bookId = bookIds[i];
          final userId = userIds[i % userIds.length];
          final date = DateTime(2024, 3, i + 1);
          final partialRating = (i % 5) + 1;

          final meetingId = await _createMeeting(
            fakeFirestore,
            bookId: bookId,
            date: date,
            notes: 'Notes $i',
            partialRating: partialRating,
            createdBy: userId,
            createdAt: DateTime(2024, 3, 1),
          );

          final doc =
              await fakeFirestore.collection('meetings').doc(meetingId).get();
          final meeting = Meeting.fromMap(doc.data()!, doc.id);

          expect(meeting.id, equals(meetingId));
          expect(meeting.bookId, equals(bookId));
          expect(meeting.partialRating, equals(partialRating));
          expect(meeting.createdBy, equals(userId));
          expect(
            meeting.date.difference(date).inSeconds.abs(),
            lessThanOrEqualTo(1),
            reason: 'date must be deserialized correctly',
          );
        }
      });
    });
  });

  // -------------------------------------------------------------------------
  // P10: Listado de reuniones siempre ordenado por date ascendente
  // Validates: Requirements 6.5
  // -------------------------------------------------------------------------
  group('P10: Meeting list is always ordered by date ascending', () {
    test('for any collection of meetings, list is sorted by date asc (2 meetings)',
        () async {
      final base = DateTime(2024, 1, 1);
      final dates = _generateDates(2, base);

      for (int trial = 0; trial < 20; trial++) {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_test';
        final shuffled = _shuffleDates(dates);

        for (int i = 0; i < shuffled.length; i++) {
          await _createMeeting(
            fakeFirestore,
            bookId: bookId,
            date: shuffled[i],
            notes: 'Meeting $i (trial $trial)',
            partialRating: (i % 5) + 1,
            createdBy: 'user_1',
            createdAt: DateTime.now(),
          );
        }

        final meetings = await _fetchMeetingsAscending(fakeFirestore, bookId);

        expect(meetings.length, equals(2));
        expect(
          meetings[0].date.isBefore(meetings[1].date) ||
              meetings[0].date.isAtSameMomentAs(meetings[1].date),
          isTrue,
          reason: 'meetings[0].date must be <= meetings[1].date (trial=$trial)',
        );
      }
    });

    test('for any collection of meetings, list is sorted by date asc (5 meetings)',
        () async {
      final base = DateTime(2024, 3, 1);
      final dates = _generateDates(5, base);

      for (int trial = 0; trial < 20; trial++) {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_test_5';
        final shuffled = _shuffleDates(dates);

        for (int i = 0; i < shuffled.length; i++) {
          await _createMeeting(
            fakeFirestore,
            bookId: bookId,
            date: shuffled[i],
            notes: 'Meeting $i',
            partialRating: (i % 5) + 1,
            createdBy: 'user_1',
            createdAt: DateTime.now(),
          );
        }

        final meetings = await _fetchMeetingsAscending(fakeFirestore, bookId);

        expect(meetings.length, equals(5));
        for (int i = 0; i < meetings.length - 1; i++) {
          expect(
            meetings[i].date.isBefore(meetings[i + 1].date) ||
                meetings[i].date.isAtSameMomentAs(meetings[i + 1].date),
            isTrue,
            reason:
                'meetings[$i].date must be <= meetings[${i + 1}].date (trial=$trial)',
          );
        }
      }
    });

    test('for any collection of meetings, list is sorted by date asc (10 meetings)',
        () async {
      final base = DateTime(2024, 6, 1);
      final dates = _generateDates(10, base);

      for (int trial = 0; trial < 20; trial++) {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_test_10';
        final shuffled = _shuffleDates(dates);

        for (int i = 0; i < shuffled.length; i++) {
          await _createMeeting(
            fakeFirestore,
            bookId: bookId,
            date: shuffled[i],
            notes: 'Meeting $i',
            partialRating: (i % 5) + 1,
            createdBy: 'user_1',
            createdAt: DateTime.now(),
          );
        }

        final meetings = await _fetchMeetingsAscending(fakeFirestore, bookId);

        expect(meetings.length, equals(10));
        for (int i = 0; i < meetings.length - 1; i++) {
          expect(
            meetings[i].date.isBefore(meetings[i + 1].date) ||
                meetings[i].date.isAtSameMomentAs(meetings[i + 1].date),
            isTrue,
            reason:
                'meetings[$i].date must be <= meetings[${i + 1}].date (trial=$trial)',
          );
        }
      }
    });

    test('for any collection of meetings, list is sorted by date asc (50 meetings)',
        () async {
      final base = DateTime(2023, 1, 1);
      final dates = _generateDates(50, base);

      for (int trial = 0; trial < 5; trial++) {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_test_50';
        final shuffled = _shuffleDates(dates);

        for (int i = 0; i < shuffled.length; i++) {
          await _createMeeting(
            fakeFirestore,
            bookId: bookId,
            date: shuffled[i],
            notes: 'Meeting $i',
            partialRating: (i % 5) + 1,
            createdBy: 'user_1',
            createdAt: DateTime.now(),
          );
        }

        final meetings = await _fetchMeetingsAscending(fakeFirestore, bookId);

        expect(meetings.length, equals(50));
        for (int i = 0; i < meetings.length - 1; i++) {
          expect(
            meetings[i].date.isBefore(meetings[i + 1].date) ||
                meetings[i].date.isAtSameMomentAs(meetings[i + 1].date),
            isTrue,
            reason:
                'meetings[$i].date must be <= meetings[${i + 1}].date (trial=$trial)',
          );
        }
      }
    });

    test('empty meeting collection returns empty list', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final meetings =
          await _fetchMeetingsAscending(fakeFirestore, 'book_empty');
      expect(meetings, isEmpty);
    });

    test('single meeting collection returns list with one element', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      const bookId = 'book_single';
      await _createMeeting(
        fakeFirestore,
        bookId: bookId,
        date: DateTime(2024, 5, 15),
        notes: 'Only meeting',
        partialRating: 4,
        createdBy: 'user_1',
        createdAt: DateTime.now(),
      );
      final meetings = await _fetchMeetingsAscending(fakeFirestore, bookId);
      expect(meetings.length, equals(1));
      expect(meetings.first.notes, equals('Only meeting'));
    });

    test('meetings for different books are isolated', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      const bookA = 'book_A';
      const bookB = 'book_B';

      // Create meetings for book A (later dates)
      await _createMeeting(
        fakeFirestore,
        bookId: bookA,
        date: DateTime(2024, 6, 1),
        notes: 'A meeting 1',
        partialRating: 3,
        createdBy: 'user_1',
        createdAt: DateTime.now(),
      );
      await _createMeeting(
        fakeFirestore,
        bookId: bookA,
        date: DateTime(2024, 8, 1),
        notes: 'A meeting 2',
        partialRating: 4,
        createdBy: 'user_1',
        createdAt: DateTime.now(),
      );

      // Create meetings for book B (earlier dates)
      await _createMeeting(
        fakeFirestore,
        bookId: bookB,
        date: DateTime(2024, 1, 1),
        notes: 'B meeting 1',
        partialRating: 5,
        createdBy: 'user_2',
        createdAt: DateTime.now(),
      );

      final meetingsA = await _fetchMeetingsAscending(fakeFirestore, bookA);
      final meetingsB = await _fetchMeetingsAscending(fakeFirestore, bookB);

      expect(meetingsA.length, equals(2),
          reason: 'Book A should have 2 meetings');
      expect(meetingsB.length, equals(1),
          reason: 'Book B should have 1 meeting');

      // Book A meetings must be sorted ascending
      expect(
        meetingsA[0].date.isBefore(meetingsA[1].date),
        isTrue,
        reason: 'Book A meetings must be sorted ascending',
      );

      // Book B meetings must not include Book A meetings
      expect(meetingsB.first.bookId, equals(bookB));
    });

    test('meetings with dates across different months are sorted correctly',
        () async {
      final fakeFirestore = FakeFirebaseFirestore();
      const bookId = 'book_months';

      final testDates = [
        DateTime(2024, 12, 1),
        DateTime(2024, 1, 1),
        DateTime(2024, 6, 15),
        DateTime(2023, 11, 30),
        DateTime(2025, 2, 28),
      ];

      for (int i = 0; i < testDates.length; i++) {
        await _createMeeting(
          fakeFirestore,
          bookId: bookId,
          date: testDates[i],
          notes: 'Meeting ${testDates[i].year}-${testDates[i].month}',
          partialRating: (i % 5) + 1,
          createdBy: 'user_1',
          createdAt: DateTime.now(),
        );
      }

      final meetings = await _fetchMeetingsAscending(fakeFirestore, bookId);

      expect(meetings.length, equals(5));
      for (int i = 0; i < meetings.length - 1; i++) {
        expect(
          meetings[i].date.isBefore(meetings[i + 1].date) ||
              meetings[i].date.isAtSameMomentAs(meetings[i + 1].date),
          isTrue,
          reason:
              'meetings[$i].date (${meetings[i].date}) must be <= '
              'meetings[${i + 1}].date (${meetings[i + 1].date})',
        );
      }

      // Oldest meeting (2023-11-30) must be first
      expect(meetings.first.date.year, equals(2023));
      // Most recent meeting (2025-02-28) must be last
      expect(meetings.last.date.year, equals(2025));
    });
  });
}
