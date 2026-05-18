// Tests for Task 22: Crear Reunión
// Covers: form validation (22.1–22.5), Firestore save (22.6)
// Requirements 6.1, 6.2

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/meeting.dart';

// ---------------------------------------------------------------------------
// Validation helpers (mirror CreateEditMeetingScreen logic)
// ---------------------------------------------------------------------------

/// Returns an error string when [date] is null, null otherwise.
String? validateDate(DateTime? date) {
  if (date == null) return 'This field is required';
  return null;
}

/// Returns an error string when [bookId] is empty/null, null otherwise.
String? validateBookId(String? bookId) {
  if (bookId == null || bookId.trim().isEmpty) return 'This field is required';
  return null;
}

/// Simulates the full form validation before saving.
bool isFormValid({
  required DateTime? date,
  required String? bookId,
}) {
  return validateDate(date) == null && validateBookId(bookId) == null;
}

// ---------------------------------------------------------------------------
// Firestore helpers
// ---------------------------------------------------------------------------

Future<String> _saveMeeting(
  FakeFirebaseFirestore fakeFirestore, {
  required String bookId,
  required DateTime date,
  required String notes,
  required String createdBy,
}) async {
  final docRef = fakeFirestore.collection('meetings').doc();
  await docRef.set({
    'bookId': bookId,
    'date': Timestamp.fromDate(date),
    'notes': notes,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(DateTime.now()),
  });
  return docRef.id;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Form validation – date field (Requirement 6.2)
  // -------------------------------------------------------------------------
  group('Form validation – date field', () {
    test('null date is rejected', () {
      expect(validateDate(null), isNotNull);
    });

    test('valid date is accepted', () {
      expect(validateDate(DateTime(2024, 6, 15)), isNull);
    });

    test('past date is accepted', () {
      expect(validateDate(DateTime(2020, 1, 1)), isNull);
    });

    test('future date is accepted', () {
      expect(validateDate(DateTime(2099, 12, 31)), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Form validation – bookId field
  // -------------------------------------------------------------------------
  group('Form validation – bookId field', () {
    test('null bookId is rejected', () {
      expect(validateBookId(null), isNotNull);
    });

    test('empty bookId is rejected', () {
      expect(validateBookId(''), isNotNull);
    });

    test('whitespace-only bookId is rejected', () {
      expect(validateBookId('   '), isNotNull);
    });

    test('valid bookId is accepted', () {
      expect(validateBookId('book_abc123'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Combined form validation (Requirement 6.2)
  // -------------------------------------------------------------------------
  group('Combined form validation', () {
    test('form is invalid when date is missing', () {
      expect(
        isFormValid(date: null, bookId: 'book_1'),
        isFalse,
      );
    });

    test('form is invalid when bookId is empty', () {
      expect(
        isFormValid(date: DateTime(2024, 1, 1), bookId: ''),
        isFalse,
      );
    });

    test('form is valid when all required fields are present', () {
      expect(
        isFormValid(date: DateTime(2024, 6, 15), bookId: 'book_1'),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Firestore save – all required fields are persisted (Requirement 6.1)
  // -------------------------------------------------------------------------
  group('Firestore save – meeting creation', () {
    test('saved meeting document contains all required fields', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final date = DateTime(2024, 6, 15);

      final meetingId = await _saveMeeting(
        fakeFirestore,
        bookId: 'book_abc',
        date: date,
        notes: 'Great discussion',
        createdBy: 'user_leader',
      );

      final doc =
          await fakeFirestore.collection('meetings').doc(meetingId).get();
      expect(doc.exists, isTrue);

      final data = doc.data()!;
      expect(data.containsKey('bookId'), isTrue);
      expect(data.containsKey('date'), isTrue);
      expect(data.containsKey('notes'), isTrue);
      expect(data.containsKey('createdBy'), isTrue);
      expect(data.containsKey('createdAt'), isTrue);
    });

    test('saved meeting has correct field values', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final date = DateTime(2024, 3, 20);

      final meetingId = await _saveMeeting(
        fakeFirestore,
        bookId: 'book_xyz',
        date: date,
        notes: 'Chapter 5 discussion',
        createdBy: 'leader_001',
      );

      final doc =
          await fakeFirestore.collection('meetings').doc(meetingId).get();
      final data = doc.data()!;

      expect(data['bookId'], equals('book_xyz'));
      expect(data['notes'], equals('Chapter 5 discussion'));
      expect(data['createdBy'], equals('leader_001'));
      expect(data['date'], isA<Timestamp>());
      expect(data['createdAt'], isA<Timestamp>());
    });

    test('date is stored as Firestore Timestamp', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final date = DateTime(2024, 8, 10);

      final meetingId = await _saveMeeting(
        fakeFirestore,
        bookId: 'book_1',
        date: date,
        notes: '',
        createdBy: 'user_1',
      );

      final doc =
          await fakeFirestore.collection('meetings').doc(meetingId).get();
      final storedDate = doc.data()!['date'] as Timestamp;
      final restoredDate = storedDate.toDate();

      expect(restoredDate.year, equals(date.year));
      expect(restoredDate.month, equals(date.month));
      expect(restoredDate.day, equals(date.day));
    });

    test('no document is created when form is invalid (missing date)',
        () async {
      final fakeFirestore = FakeFirebaseFirestore();

      // Simulate: form validation fails → no write
      final valid = isFormValid(
        date: null,
        bookId: 'book_1',
      );

      if (valid) {
        await _saveMeeting(
          fakeFirestore,
          bookId: 'book_1',
          date: DateTime.now(),
          notes: '',
          createdBy: 'user_1',
        );
      }

      final snapshot = await fakeFirestore.collection('meetings').get();
      expect(snapshot.docs.length, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // Meeting model deserialization
  // -------------------------------------------------------------------------
  group('Meeting model – fromMap deserialization', () {
    test('Meeting.fromMap correctly deserializes all fields', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final date = DateTime(2024, 5, 1);

      final meetingId = await _saveMeeting(
        fakeFirestore,
        bookId: 'book_test',
        date: date,
        notes: 'Test notes',
        createdBy: 'user_test',
      );

      final doc =
          await fakeFirestore.collection('meetings').doc(meetingId).get();
      final meeting = Meeting.fromMap(doc.data()!, doc.id);

      expect(meeting.id, equals(meetingId));
      expect(meeting.bookId, equals('book_test'));
      expect(meeting.notes, equals('Test notes'));
      expect(meeting.createdBy, equals('user_test'));
      expect(meeting.date.year, equals(2024));
      expect(meeting.date.month, equals(5));
      expect(meeting.date.day, equals(1));
    });

    test('Meeting.toMap produces correct Firestore map', () {
      final date = DateTime(2024, 7, 4);
      final createdAt = DateTime(2024, 7, 1);

      final meeting = Meeting(
        id: 'meeting_1',
        bookId: 'book_1',
        date: date,
        notes: 'Independence Day meeting',
        createdBy: 'leader_1',
        createdAt: createdAt,
      );

      final map = meeting.toMap();

      expect(map['bookId'], equals('book_1'));
      expect(map['notes'], equals('Independence Day meeting'));
      expect(map['createdBy'], equals('leader_1'));
      expect(map['date'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
    });
  });

  // -------------------------------------------------------------------------
  // Error handling
  // -------------------------------------------------------------------------
  group('Error handling', () {
    test('meeting with empty notes is still valid (notes are optional)', () {
      expect(
        isFormValid(date: DateTime(2024, 1, 1), bookId: 'book_1'),
        isTrue,
        reason: 'notes are optional, empty notes should not block submission',
      );
    });

    test('meeting with very long notes is accepted', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final longNotes = 'A' * 5000;

      final meetingId = await _saveMeeting(
        fakeFirestore,
        bookId: 'book_1',
        date: DateTime(2024, 1, 1),
        notes: longNotes,
        createdBy: 'user_1',
      );

      final doc =
          await fakeFirestore.collection('meetings').doc(meetingId).get();
      expect(doc.data()!['notes'], equals(longNotes));
    });
  });
}
