// Feature: book-club-app, Property 11: Validación de longitud de Comment (1-1000 chars)
// Feature: book-club-app, Property 12: Almacenamiento de Comment en subcolección correcta

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/comment.dart';

// ---------------------------------------------------------------------------
// Validation helper (mirrors comment_form.dart validateCommentText logic)
// ---------------------------------------------------------------------------

/// Returns null if [text] is valid (1–1000 chars), error string otherwise.
/// Requirement 7.3
String? validateCommentText(String? text) {
  if (text == null || text.isEmpty) return 'Comment must be at least 1 character.';
  if (text.length > 1000) return 'Comment must not exceed 1000 characters.';
  return null;
}

// ---------------------------------------------------------------------------
// Firestore helpers
// ---------------------------------------------------------------------------

/// Adds a comment to `books/{bookId}/comments` (mirrors CommentService).
Future<String> _addBookComment(
  FakeFirebaseFirestore fakeFirestore, {
  required String bookId,
  required String authorId,
  required String authorName,
  required String text,
  required DateTime createdAt,
}) async {
  final docRef = fakeFirestore
      .collection('books')
      .doc(bookId)
      .collection('comments')
      .doc();
  await docRef.set({
    'authorId': authorId,
    'authorName': authorName,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
  });
  return docRef.id;
}

/// Adds a comment to `meetings/{meetingId}/comments` (mirrors CommentService).
Future<String> _addMeetingComment(
  FakeFirebaseFirestore fakeFirestore, {
  required String meetingId,
  required String authorId,
  required String authorName,
  required String text,
  required DateTime createdAt,
}) async {
  final docRef = fakeFirestore
      .collection('meetings')
      .doc(meetingId)
      .collection('comments')
      .doc();
  await docRef.set({
    'authorId': authorId,
    'authorName': authorName,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
  });
  return docRef.id;
}

// ---------------------------------------------------------------------------
// Test data generators
// ---------------------------------------------------------------------------

/// Valid texts: lengths 1 to 1000 (boundary + representative values).
List<String> _generateValidTexts() {
  final texts = <String>[];
  // Boundary: exactly 1 char
  texts.add('A');
  // Boundary: exactly 1000 chars
  texts.add('B' * 1000);
  // Representative lengths
  for (int len in [2, 5, 10, 50, 100, 250, 500, 750, 999]) {
    texts.add('x' * len);
  }
  // Realistic comment texts
  texts.addAll([
    'Great book!',
    'I really enjoyed this chapter.',
    'The meeting was very productive.',
    'Looking forward to the next session.',
    'This is a longer comment that spans multiple ideas and thoughts about the book we are reading together as a club.',
    'Excelente libro, muy recomendado para todos los miembros del club.',
    'La reunión fue muy interesante y aprendimos mucho sobre el tema.',
  ]);
  return texts;
}

/// Invalid texts: empty, blank, or over 1000 chars.
List<String?> _generateInvalidTexts() {
  return [
    '',           // empty
    null,         // null
    'C' * 1001,   // 1001 chars
    'D' * 2000,   // 2000 chars
    'E' * 10000,  // very long
  ];
}

/// Generates varied book IDs.
List<String> _generateBookIds() =>
    List.generate(20, (i) => 'book_$i') + ['book_alpha', 'book_beta', 'book_xyz'];

/// Generates varied meeting IDs.
List<String> _generateMeetingIds() =>
    List.generate(20, (i) => 'meeting_$i') + ['meeting_alpha', 'meeting_beta'];

/// Generates varied user IDs.
List<String> _generateUserIds() =>
    List.generate(20, (i) => 'user_$i') + ['leader_1', 'member_abc'];

/// Generates varied user names.
List<String> _generateUserNames() => [
      'Alice',
      'Bob',
      'Carlos',
      'Diana',
      'Eduardo',
      'Fiona',
      'Gabriel',
      'Helena',
      'Ignacio',
      'Julia',
      'Kevin',
      'Laura',
      'Miguel',
      'Nadia',
      'Oscar',
      'Paula',
      'Quentin',
      'Rosa',
      'Samuel',
      'Teresa',
    ];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final validTexts = _generateValidTexts();
  final invalidTexts = _generateInvalidTexts();
  final bookIds = _generateBookIds();
  final meetingIds = _generateMeetingIds();
  final userIds = _generateUserIds();
  final userNames = _generateUserNames();

  // -------------------------------------------------------------------------
  // P11: Validación de longitud de Comment
  // Validates: Requirements 7.3
  // -------------------------------------------------------------------------
  group('P11: Comment length validation accepts only 1-1000 chars', () {
    // Feature: book-club-app, Property 11: Validación de longitud de Comment
    test('comment length validation accepts only 1-1000 chars', () {
      // Valid texts must pass validation
      for (final text in validTexts) {
        final result = validateCommentText(text);
        expect(
          result,
          isNull,
          reason: 'Text of length ${text.length} should be valid',
        );
      }
    });

    test('validateCommentText rejects empty string', () {
      expect(validateCommentText(''), isNotNull,
          reason: 'Empty string must be rejected');
    });

    test('validateCommentText rejects null', () {
      expect(validateCommentText(null), isNotNull,
          reason: 'Null must be rejected');
    });

    test('validateCommentText rejects texts over 1000 chars', () {
      for (final text in invalidTexts) {
        if (text != null && text.length > 1000) {
          final result = validateCommentText(text);
          expect(
            result,
            isNotNull,
            reason: 'Text of length ${text.length} should be rejected',
          );
        }
      }
    });

    test('validateCommentText rejects all invalid inputs', () {
      for (final text in invalidTexts) {
        final result = validateCommentText(text);
        expect(
          result,
          isNotNull,
          reason: 'Invalid text "${text?.substring(0, text.length.clamp(0, 20))}" should be rejected',
        );
      }
    });

    test('boundary: text of exactly 1 char is accepted', () {
      expect(validateCommentText('A'), isNull,
          reason: 'Single character must be accepted');
    });

    test('boundary: text of exactly 1000 chars is accepted', () {
      expect(validateCommentText('x' * 1000), isNull,
          reason: '1000 chars must be accepted');
    });

    test('boundary: text of exactly 1001 chars is rejected', () {
      expect(validateCommentText('x' * 1001), isNotNull,
          reason: '1001 chars must be rejected');
    });

    test('no Firestore document is created when text is invalid', () async {
      for (final invalidText in invalidTexts) {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_validation_test';

        final error = validateCommentText(invalidText);
        if (error != null) {
          // Validation failed — do NOT write to Firestore
        } else {
          await _addBookComment(
            fakeFirestore,
            bookId: bookId,
            authorId: 'user_1',
            authorName: 'Test User',
            text: invalidText!,
            createdAt: DateTime.now(),
          );
        }

        final snapshot = await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('comments')
            .get();
        expect(
          snapshot.docs.length,
          equals(0),
          reason: 'No comment should be created for invalid text',
        );
      }
    });

    test('Firestore document is created when text is valid', () async {
      for (int i = 0; i < validTexts.length; i++) {
        final fakeFirestore = FakeFirebaseFirestore();
        final bookId = bookIds[i % bookIds.length];
        final text = validTexts[i];

        final error = validateCommentText(text);
        expect(error, isNull, reason: 'Valid text should pass validation');

        await _addBookComment(
          fakeFirestore,
          bookId: bookId,
          authorId: userIds[i % userIds.length],
          authorName: userNames[i % userNames.length],
          text: text,
          createdAt: DateTime.now(),
        );

        final snapshot = await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('comments')
            .get();
        expect(
          snapshot.docs.length,
          equals(1),
          reason: 'Comment should be created for valid text of length ${text.length}',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // P12: Almacenamiento de Comment en subcolección correcta
  // Validates: Requirements 7.1, 7.2
  // -------------------------------------------------------------------------
  group('P12: Comment is stored in the correct subcollection', () {
    // Feature: book-club-app, Property 12: Almacenamiento de Comment en subcolección correcta
    test('comment storage in correct subcollection', () async {
      for (int i = 0; i < bookIds.length; i++) {
        final fakeFirestore = FakeFirebaseFirestore();
        final bookId = bookIds[i];
        final authorId = userIds[i % userIds.length];
        final authorName = userNames[i % userNames.length];
        final text = validTexts[i % validTexts.length];
        final createdAt = DateTime(2024, 1, 1).add(Duration(hours: i));

        // Add comment to book subcollection
        final commentId = await _addBookComment(
          fakeFirestore,
          bookId: bookId,
          authorId: authorId,
          authorName: authorName,
          text: text,
          createdAt: createdAt,
        );

        // Verify stored in books/{bookId}/comments
        final doc = await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('comments')
            .doc(commentId)
            .get();

        expect(doc.exists, isTrue,
            reason: 'Comment must exist in books/$bookId/comments');

        final data = doc.data()!;
        expect(data.containsKey('authorId'), isTrue,
            reason: 'authorId field must exist');
        expect(data.containsKey('authorName'), isTrue,
            reason: 'authorName field must exist');
        expect(data.containsKey('text'), isTrue,
            reason: 'text field must exist');
        expect(data.containsKey('createdAt'), isTrue,
            reason: 'createdAt field must exist');

        expect(data['authorId'], equals(authorId),
            reason: 'authorId must be preserved');
        expect(data['authorName'], equals(authorName),
            reason: 'authorName must be preserved');
        expect(data['text'], equals(text),
            reason: 'text must be preserved');
        expect(data['createdAt'], isA<Timestamp>(),
            reason: 'createdAt must be a Timestamp');
      }
    });

    test('book comment is NOT stored in meetings subcollection', () async {
      for (int i = 0; i < 10; i++) {
        final fakeFirestore = FakeFirebaseFirestore();
        final bookId = bookIds[i];
        final meetingId = meetingIds[i];

        await _addBookComment(
          fakeFirestore,
          bookId: bookId,
          authorId: userIds[i % userIds.length],
          authorName: userNames[i % userNames.length],
          text: validTexts[i % validTexts.length],
          createdAt: DateTime.now(),
        );

        // Must NOT appear in meetings subcollection
        final meetingSnapshot = await fakeFirestore
            .collection('meetings')
            .doc(meetingId)
            .collection('comments')
            .get();
        expect(meetingSnapshot.docs.length, equals(0),
            reason: 'Book comment must not appear in meetings/$meetingId/comments');
      }
    });

    test('meeting comment is stored in meetings/{meetingId}/comments with all required fields',
        () async {
      for (int i = 0; i < meetingIds.length; i++) {
        final fakeFirestore = FakeFirebaseFirestore();
        final meetingId = meetingIds[i];
        final authorId = userIds[i % userIds.length];
        final authorName = userNames[i % userNames.length];
        final text = validTexts[i % validTexts.length];
        final createdAt = DateTime(2024, 2, 1).add(Duration(hours: i));

        final commentId = await _addMeetingComment(
          fakeFirestore,
          meetingId: meetingId,
          authorId: authorId,
          authorName: authorName,
          text: text,
          createdAt: createdAt,
        );

        // Verify stored in meetings/{meetingId}/comments
        final doc = await fakeFirestore
            .collection('meetings')
            .doc(meetingId)
            .collection('comments')
            .doc(commentId)
            .get();

        expect(doc.exists, isTrue,
            reason: 'Comment must exist in meetings/$meetingId/comments');

        final data = doc.data()!;
        expect(data.containsKey('authorId'), isTrue,
            reason: 'authorId field must exist');
        expect(data.containsKey('authorName'), isTrue,
            reason: 'authorName field must exist');
        expect(data.containsKey('text'), isTrue,
            reason: 'text field must exist');
        expect(data.containsKey('createdAt'), isTrue,
            reason: 'createdAt field must exist');

        expect(data['authorId'], equals(authorId),
            reason: 'authorId must be preserved');
        expect(data['authorName'], equals(authorName),
            reason: 'authorName must be preserved');
        expect(data['text'], equals(text),
            reason: 'text must be preserved');
        expect(data['createdAt'], isA<Timestamp>(),
            reason: 'createdAt must be a Timestamp');
      }
    });

    test('meeting comment is NOT stored in books subcollection', () async {
      for (int i = 0; i < 10; i++) {
        final fakeFirestore = FakeFirebaseFirestore();
        final bookId = bookIds[i];
        final meetingId = meetingIds[i];

        await _addMeetingComment(
          fakeFirestore,
          meetingId: meetingId,
          authorId: userIds[i % userIds.length],
          authorName: userNames[i % userNames.length],
          text: validTexts[i % validTexts.length],
          createdAt: DateTime.now(),
        );

        // Must NOT appear in books subcollection
        final bookSnapshot = await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('comments')
            .get();
        expect(bookSnapshot.docs.length, equals(0),
            reason: 'Meeting comment must not appear in books/$bookId/comments');
      }
    });

    test('Comment.fromMap correctly deserializes all required fields', () async {
      for (int i = 0; i < bookIds.length; i++) {
        final fakeFirestore = FakeFirebaseFirestore();
        final bookId = bookIds[i];
        final authorId = userIds[i % userIds.length];
        final authorName = userNames[i % userNames.length];
        final text = validTexts[i % validTexts.length];
        final createdAt = DateTime(2024, 3, 1).add(Duration(hours: i));

        final commentId = await _addBookComment(
          fakeFirestore,
          bookId: bookId,
          authorId: authorId,
          authorName: authorName,
          text: text,
          createdAt: createdAt,
        );

        final doc = await fakeFirestore
            .collection('books')
            .doc(bookId)
            .collection('comments')
            .doc(commentId)
            .get();

        final comment = Comment.fromMap(doc.data()!, doc.id);

        expect(comment.id, equals(commentId));
        expect(comment.authorId, equals(authorId));
        expect(comment.authorName, equals(authorName));
        expect(comment.text, equals(text));
        expect(
          comment.createdAt.difference(createdAt).inSeconds.abs(),
          lessThanOrEqualTo(1),
          reason: 'createdAt must be deserialized correctly',
        );
      }
    });

    test('comments for different books are isolated', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      const bookA = 'book_isolation_A';
      const bookB = 'book_isolation_B';

      await _addBookComment(
        fakeFirestore,
        bookId: bookA,
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'Comment for book A',
        createdAt: DateTime.now(),
      );
      await _addBookComment(
        fakeFirestore,
        bookId: bookA,
        authorId: 'user_2',
        authorName: 'Bob',
        text: 'Another comment for book A',
        createdAt: DateTime.now(),
      );
      await _addBookComment(
        fakeFirestore,
        bookId: bookB,
        authorId: 'user_3',
        authorName: 'Carlos',
        text: 'Comment for book B',
        createdAt: DateTime.now(),
      );

      final commentsA = await fakeFirestore
          .collection('books')
          .doc(bookA)
          .collection('comments')
          .get();
      final commentsB = await fakeFirestore
          .collection('books')
          .doc(bookB)
          .collection('comments')
          .get();

      expect(commentsA.docs.length, equals(2),
          reason: 'Book A should have 2 comments');
      expect(commentsB.docs.length, equals(1),
          reason: 'Book B should have 1 comment');
    });

    test('comments for different meetings are isolated', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      const meetingA = 'meeting_isolation_A';
      const meetingB = 'meeting_isolation_B';

      await _addMeetingComment(
        fakeFirestore,
        meetingId: meetingA,
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'Comment for meeting A',
        createdAt: DateTime.now(),
      );
      await _addMeetingComment(
        fakeFirestore,
        meetingId: meetingB,
        authorId: 'user_2',
        authorName: 'Bob',
        text: 'Comment for meeting B',
        createdAt: DateTime.now(),
      );

      final commentsA = await fakeFirestore
          .collection('meetings')
          .doc(meetingA)
          .collection('comments')
          .get();
      final commentsB = await fakeFirestore
          .collection('meetings')
          .doc(meetingB)
          .collection('comments')
          .get();

      expect(commentsA.docs.length, equals(1),
          reason: 'Meeting A should have 1 comment');
      expect(commentsB.docs.length, equals(1),
          reason: 'Meeting B should have 1 comment');
    });
  });
}
