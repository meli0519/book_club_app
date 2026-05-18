// Feature: comment-stickers
// Task 5.1: Unit tests for CommentService sticker validation
// Validates: Requirements 8.3, 8.4
//
// Requirement 8.3: IF a Comment is submitted with stickers.length > 5,
//   THEN CommentService SHALL throw and SHALL NOT write to Firestore.
// Requirement 8.4: IF a Comment is submitted with a Sticker_ID not present
//   in StickerCatalog.all.keys, THEN CommentService SHALL throw and SHALL NOT
//   write to Firestore.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/data/services/comment_service.dart';
import 'package:book_club_app/domain/models/comment.dart';
import 'package:book_club_app/domain/models/sticker_catalog.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal valid [Comment] with the given [stickers] list.
Comment _makeComment({List<String> stickers = const []}) {
  return Comment(
    id: 'test_comment_id',
    authorId: 'user_123',
    authorName: 'Test User',
    text: 'This is a test comment.',
    stickers: stickers,
    createdAt: DateTime(2024, 1, 1),
  );
}

/// Returns the first 5 known sticker IDs from [StickerCatalog.ids].
List<String> get _fiveKnownIds => StickerCatalog.ids.take(5).toList();

/// Returns a sticker ID that is guaranteed NOT to be in [StickerCatalog.all].
const String _unknownStickerId = 'sticker_does_not_exist';

void main() {
  // Sanity check: the unknown ID must not accidentally be in the catalog.
  assert(
    !StickerCatalog.all.containsKey(_unknownStickerId),
    '_unknownStickerId must not be a real catalog entry',
  );

  // -------------------------------------------------------------------------
  // addBookComment – throws when stickers.length > 5
  // Validates: Requirement 8.3
  // -------------------------------------------------------------------------
  group('addBookComment – throws when stickers.length > 5', () {
    test('throws when 6 stickers are provided', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final sixStickers = [
        ...StickerCatalog.ids.take(5),
        StickerCatalog.ids[5],
      ];
      final comment = _makeComment(stickers: sixStickers);

      expect(
        () => service.addBookComment('book_1', comment),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when 10 stickers are provided', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final tenStickers = StickerCatalog.ids.take(10).toList();
      final comment = _makeComment(stickers: tenStickers);

      expect(
        () => service.addBookComment('book_1', comment),
        throwsA(isA<Exception>()),
      );
    });

    test('does NOT write to Firestore when stickers.length > 5', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final sixStickers = StickerCatalog.ids.take(6).toList();
      final comment = _makeComment(stickers: sixStickers);

      try {
        await service.addBookComment('book_1', comment);
      } catch (_) {
        // expected
      }

      final snapshot = await fs
          .collection('books')
          .doc('book_1')
          .collection('comments')
          .get();
      expect(snapshot.docs, isEmpty,
          reason: 'No document should be written when validation fails');
    });
  });

  // -------------------------------------------------------------------------
  // addMeetingComment – throws when stickers.length > 5
  // Validates: Requirement 8.3
  // -------------------------------------------------------------------------
  group('addMeetingComment – throws when stickers.length > 5', () {
    test('throws when 6 stickers are provided', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final sixStickers = StickerCatalog.ids.take(6).toList();
      final comment = _makeComment(stickers: sixStickers);

      expect(
        () => service.addMeetingComment('meeting_1', comment),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when 10 stickers are provided', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final tenStickers = StickerCatalog.ids.take(10).toList();
      final comment = _makeComment(stickers: tenStickers);

      expect(
        () => service.addMeetingComment('meeting_1', comment),
        throwsA(isA<Exception>()),
      );
    });

    test('does NOT write to Firestore when stickers.length > 5', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final sixStickers = StickerCatalog.ids.take(6).toList();
      final comment = _makeComment(stickers: sixStickers);

      try {
        await service.addMeetingComment('meeting_1', comment);
      } catch (_) {
        // expected
      }

      final snapshot = await fs
          .collection('meetings')
          .doc('meeting_1')
          .collection('comments')
          .get();
      expect(snapshot.docs, isEmpty,
          reason: 'No document should be written when validation fails');
    });
  });

  // -------------------------------------------------------------------------
  // addBookComment – throws when a sticker ID is not in StickerCatalog.all.keys
  // Validates: Requirement 8.4
  // -------------------------------------------------------------------------
  group('addBookComment – throws when sticker ID is unknown', () {
    test('throws when the only sticker is an unknown ID', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: [_unknownStickerId]);

      expect(
        () => service.addBookComment('book_1', comment),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when one of several stickers is an unknown ID', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final mixedStickers = [
        StickerCatalog.ids[0],
        StickerCatalog.ids[1],
        _unknownStickerId,
      ];
      final comment = _makeComment(stickers: mixedStickers);

      expect(
        () => service.addBookComment('book_1', comment),
        throwsA(isA<Exception>()),
      );
    });

    test('does NOT write to Firestore when sticker ID is unknown', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: [_unknownStickerId]);

      try {
        await service.addBookComment('book_1', comment);
      } catch (_) {
        // expected
      }

      final snapshot = await fs
          .collection('books')
          .doc('book_1')
          .collection('comments')
          .get();
      expect(snapshot.docs, isEmpty,
          reason: 'No document should be written when validation fails');
    });
  });

  // -------------------------------------------------------------------------
  // addMeetingComment – throws when a sticker ID is not in StickerCatalog.all.keys
  // Validates: Requirement 8.4
  // -------------------------------------------------------------------------
  group('addMeetingComment – throws when sticker ID is unknown', () {
    test('throws when the only sticker is an unknown ID', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: [_unknownStickerId]);

      expect(
        () => service.addMeetingComment('meeting_1', comment),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when one of several stickers is an unknown ID', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final mixedStickers = [
        StickerCatalog.ids[0],
        StickerCatalog.ids[1],
        _unknownStickerId,
      ];
      final comment = _makeComment(stickers: mixedStickers);

      expect(
        () => service.addMeetingComment('meeting_1', comment),
        throwsA(isA<Exception>()),
      );
    });

    test('does NOT write to Firestore when sticker ID is unknown', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: [_unknownStickerId]);

      try {
        await service.addMeetingComment('meeting_1', comment);
      } catch (_) {
        // expected
      }

      final snapshot = await fs
          .collection('meetings')
          .doc('meeting_1')
          .collection('comments')
          .get();
      expect(snapshot.docs, isEmpty,
          reason: 'No document should be written when validation fails');
    });
  });

  // -------------------------------------------------------------------------
  // addBookComment – succeeds for valid stickers lists
  // Validates: Requirements 8.1, 8.3, 8.4
  // -------------------------------------------------------------------------
  group('addBookComment – succeeds for valid stickers', () {
    test('succeeds with 0 stickers (empty list)', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: []);

      await expectLater(
        service.addBookComment('book_1', comment),
        completes,
      );
    });

    test('succeeds with 1 known sticker ID', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: [StickerCatalog.ids[0]]);

      await expectLater(
        service.addBookComment('book_1', comment),
        completes,
      );
    });

    test('succeeds with 3 known sticker IDs', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(
        stickers: StickerCatalog.ids.take(3).toList(),
      );

      await expectLater(
        service.addBookComment('book_1', comment),
        completes,
      );
    });

    test('succeeds with exactly 5 known sticker IDs (boundary)', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: _fiveKnownIds);

      await expectLater(
        service.addBookComment('book_1', comment),
        completes,
      );
    });

    test('writes document to Firestore on success', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: [StickerCatalog.ids[0]]);
      await service.addBookComment('book_1', comment);

      final snapshot = await fs
          .collection('books')
          .doc('book_1')
          .collection('comments')
          .get();
      expect(snapshot.docs.length, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // addMeetingComment – succeeds for valid stickers lists
  // Validates: Requirements 8.2, 8.3, 8.4
  // -------------------------------------------------------------------------
  group('addMeetingComment – succeeds for valid stickers', () {
    test('succeeds with 0 stickers (empty list)', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: []);

      await expectLater(
        service.addMeetingComment('meeting_1', comment),
        completes,
      );
    });

    test('succeeds with 1 known sticker ID', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: [StickerCatalog.ids[0]]);

      await expectLater(
        service.addMeetingComment('meeting_1', comment),
        completes,
      );
    });

    test('succeeds with 3 known sticker IDs', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(
        stickers: StickerCatalog.ids.take(3).toList(),
      );

      await expectLater(
        service.addMeetingComment('meeting_1', comment),
        completes,
      );
    });

    test('succeeds with exactly 5 known sticker IDs (boundary)', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: _fiveKnownIds);

      await expectLater(
        service.addMeetingComment('meeting_1', comment),
        completes,
      );
    });

    test('writes document to Firestore on success', () async {
      final fs = FakeFirebaseFirestore();
      final service = CommentService(firestore: fs);

      final comment = _makeComment(stickers: [StickerCatalog.ids[0]]);
      await service.addMeetingComment('meeting_1', comment);

      final snapshot = await fs
          .collection('meetings')
          .doc('meeting_1')
          .collection('comments')
          .get();
      expect(snapshot.docs.length, equals(1));
    });
  });
}
