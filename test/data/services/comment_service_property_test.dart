// Feature: comment-stickers
// Task 5.2: Property tests for CommentService sticker validation
//
// Property 13: Validación del límite en CommentService
//   For any Comment with stickers.length > 5, both addBookComment and
//   addMeetingComment must throw without writing to Firestore.
//   Validates: Requirement 8.3
//
// Property 14: Validación del catálogo en CommentService
//   For any Comment containing an unknown sticker ID, both methods must throw
//   without writing to Firestore.
//   Validates: Requirement 8.4

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:glados/glados.dart';

import 'package:book_club_app/data/services/comment_service.dart';
import 'package:book_club_app/domain/models/comment.dart';
import 'package:book_club_app/domain/models/sticker_catalog.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal valid [Comment] with the given [stickers] list.
Comment _makeComment({required List<String> stickers}) {
  return Comment(
    id: 'prop_test_comment',
    authorId: 'user_prop',
    authorName: 'Property Tester',
    text: 'Property test comment.',
    stickers: stickers,
    createdAt: DateTime(2024, 6, 1),
  );
}

// ---------------------------------------------------------------------------
// Custom Arbitrary generators
// ---------------------------------------------------------------------------

extension AnyCommentServiceStickers on Any {
  /// Generates a stickers list with length 6–20, all IDs from StickerCatalog.ids.
  ///
  /// Since StickerCatalog has exactly 20 IDs, we allow repetition to reach
  /// lengths beyond 20 if needed, but cap at 20 to stay within catalog size.
  Generator<List<String>> get tooManyStickers => (random, size) {
        // Length between 6 and 20 (inclusive)
        final length = 6 + random.nextInt(15); // 6..20
        final ids = StickerCatalog.ids;
        final result = <String>[];
        for (int i = 0; i < length; i++) {
          result.add(ids[random.nextInt(ids.length)]);
        }
        // Shrink toward the minimal failing case: 6 stickers
        final shrunk = ids.take(6).toList();
        return Shrinkable(result, () => [Shrinkable(shrunk, () => [])]);
      };

  /// Generates a stickers list (length 1–5) that contains at least one unknown
  /// sticker ID mixed with valid catalog IDs.
  Generator<List<String>> get stickersWithUnknownId => (random, size) {
        // Pool of unknown IDs that are guaranteed not in the catalog
        const unknownIds = [
          'sticker_unknown_xyz',
          'invalid_id',
          'sticker_does_not_exist',
          'not_a_sticker',
          'sticker_fake_001',
          'random_unknown_id',
          'sticker_missing',
          'bad_sticker_id',
        ];

        // Total list length: 1–5
        final length = 1 + random.nextInt(5); // 1..5

        // Position of the unknown ID within the list
        final unknownPos = random.nextInt(length);
        final unknownId = unknownIds[random.nextInt(unknownIds.length)];

        final ids = StickerCatalog.ids;
        final result = <String>[];
        for (int i = 0; i < length; i++) {
          if (i == unknownPos) {
            result.add(unknownId);
          } else {
            result.add(ids[random.nextInt(ids.length)]);
          }
        }

        // Shrink toward the minimal failing case: single unknown ID
        final shrunk = <String>[unknownId];
        return Shrinkable(result, () => [Shrinkable(shrunk, () => [])]);
      };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Property 13: Validación del límite en CommentService
  // Validates: Requirement 8.3
  //
  // For any Comment with stickers.length > 5, both addBookComment and
  // addMeetingComment must throw without writing to Firestore.
  // -------------------------------------------------------------------------
  group(
    'P13: addBookComment throws and does not write when stickers.length > 5',
    () {
      // **Validates: Requirements 8.3**
      Glados(any.tooManyStickers, ExploreConfig(numRuns: 100)).test(
        'for any stickers list with length > 5, addBookComment throws',
        (stickers) async {
          assert(stickers.length > 5,
              'Generator must produce lists with length > 5');

          final fs = FakeFirebaseFirestore();
          final service = CommentService(firestore: fs);
          final comment = _makeComment(stickers: stickers);

          bool threw = false;
          try {
            await service.addBookComment('book_prop', comment);
          } catch (_) {
            threw = true;
          }

          expect(threw, isTrue,
              reason:
                  'addBookComment must throw when stickers.length (${stickers.length}) > 5');

          // Verify no document was written to Firestore
          final snapshot = await fs
              .collection('books')
              .doc('book_prop')
              .collection('comments')
              .get();
          expect(snapshot.docs, isEmpty,
              reason:
                  'No document must be written when stickers.length > 5');
        },
      );
    },
  );

  group(
    'P13: addMeetingComment throws and does not write when stickers.length > 5',
    () {
      // **Validates: Requirements 8.3**
      Glados(any.tooManyStickers, ExploreConfig(numRuns: 100)).test(
        'for any stickers list with length > 5, addMeetingComment throws',
        (stickers) async {
          assert(stickers.length > 5,
              'Generator must produce lists with length > 5');

          final fs = FakeFirebaseFirestore();
          final service = CommentService(firestore: fs);
          final comment = _makeComment(stickers: stickers);

          bool threw = false;
          try {
            await service.addMeetingComment('meeting_prop', comment);
          } catch (_) {
            threw = true;
          }

          expect(threw, isTrue,
              reason:
                  'addMeetingComment must throw when stickers.length (${stickers.length}) > 5');

          // Verify no document was written to Firestore
          final snapshot = await fs
              .collection('meetings')
              .doc('meeting_prop')
              .collection('comments')
              .get();
          expect(snapshot.docs, isEmpty,
              reason:
                  'No document must be written when stickers.length > 5');
        },
      );
    },
  );

  // -------------------------------------------------------------------------
  // Property 14: Validación del catálogo en CommentService
  // Validates: Requirement 8.4
  //
  // For any Comment containing an unknown sticker ID, both addBookComment and
  // addMeetingComment must throw without writing to Firestore.
  // -------------------------------------------------------------------------
  group(
    'P14: addBookComment throws and does not write when sticker ID is unknown',
    () {
      // **Validates: Requirements 8.4**
      Glados(any.stickersWithUnknownId, ExploreConfig(numRuns: 100)).test(
        'for any stickers list with an unknown ID, addBookComment throws',
        (stickers) async {
          // Verify the generator produced at least one unknown ID
          final hasUnknown =
              stickers.any((id) => !StickerCatalog.all.containsKey(id));
          assert(hasUnknown,
              'Generator must produce at least one unknown sticker ID');

          final fs = FakeFirebaseFirestore();
          final service = CommentService(firestore: fs);
          final comment = _makeComment(stickers: stickers);

          bool threw = false;
          try {
            await service.addBookComment('book_prop', comment);
          } catch (_) {
            threw = true;
          }

          expect(threw, isTrue,
              reason:
                  'addBookComment must throw when stickers contains unknown ID');

          // Verify no document was written to Firestore
          final snapshot = await fs
              .collection('books')
              .doc('book_prop')
              .collection('comments')
              .get();
          expect(snapshot.docs, isEmpty,
              reason:
                  'No document must be written when sticker ID is unknown');
        },
      );
    },
  );

  group(
    'P14: addMeetingComment throws and does not write when sticker ID is unknown',
    () {
      // **Validates: Requirements 8.4**
      Glados(any.stickersWithUnknownId, ExploreConfig(numRuns: 100)).test(
        'for any stickers list with an unknown ID, addMeetingComment throws',
        (stickers) async {
          // Verify the generator produced at least one unknown ID
          final hasUnknown =
              stickers.any((id) => !StickerCatalog.all.containsKey(id));
          assert(hasUnknown,
              'Generator must produce at least one unknown sticker ID');

          final fs = FakeFirebaseFirestore();
          final service = CommentService(firestore: fs);
          final comment = _makeComment(stickers: stickers);

          bool threw = false;
          try {
            await service.addMeetingComment('meeting_prop', comment);
          } catch (_) {
            threw = true;
          }

          expect(threw, isTrue,
              reason:
                  'addMeetingComment must throw when stickers contains unknown ID');

          // Verify no document was written to Firestore
          final snapshot = await fs
              .collection('meetings')
              .doc('meeting_prop')
              .collection('comments')
              .get();
          expect(snapshot.docs, isEmpty,
              reason:
                  'No document must be written when sticker ID is unknown');
        },
      );
    },
  );
}
