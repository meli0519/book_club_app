// Feature: comment-stickers
// Property 5: Round-trip de serialización de Comment
// Property 6: Campo condicional en Comment.toMap()
// Property 7: Retrocompatibilidad en Comment.fromMap()
//
// Validates: Requirements 6.2, 6.3, 6.5, 10.1

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glados/glados.dart';

import 'package:book_club_app/domain/models/comment.dart';
import 'package:book_club_app/domain/models/sticker_catalog.dart';

// ---------------------------------------------------------------------------
// Custom Arbitrary generator for valid sticker lists
// ---------------------------------------------------------------------------

extension AnyCommentStickers on Any {
  /// Generates a valid stickers list: length 0–5, all IDs from StickerCatalog.ids.
  Generator<List<String>> get validStickerList => (random, size) {
        final maxLen = 5;
        final length = random.nextInt(maxLen + 1); // 0..5
        final ids = StickerCatalog.ids;
        final selected = <String>[];
        // Pick `length` distinct IDs from the catalog
        final available = List<String>.from(ids);
        for (int i = 0; i < length && available.isNotEmpty; i++) {
          final idx = random.nextInt(available.length);
          selected.add(available[idx]);
          available.removeAt(idx);
        }
        return Shrinkable(selected, () => []);
      };

  /// Generates a complete valid Comment with a valid stickers list.
  Generator<Comment> get commentWithStickers => (random, size) {
        final authorIds = [
          'user_1', 'user_2', 'user_abc', 'user_xyz', 'user_100',
        ];
        final authorNames = [
          'Alice', 'Bob', 'Carlos', 'Diana', 'Eduardo',
        ];
        final texts = [
          'Great book!',
          'I loved this chapter.',
          'Very insightful meeting.',
          'Looking forward to the next session.',
          'Excelente lectura, muy recomendada.',
          'La reunión fue muy productiva.',
          'x' * 100,
          'Short',
        ];

        final id = 'comment_${random.nextInt(100000)}';
        final authorId = authorIds[random.nextInt(authorIds.length)];
        final authorName = authorNames[random.nextInt(authorNames.length)];
        final text = texts[random.nextInt(texts.length)];

        // Generate stickers list (0–5 distinct IDs)
        final maxLen = 5;
        final length = random.nextInt(maxLen + 1);
        final available = List<String>.from(StickerCatalog.ids);
        final stickers = <String>[];
        for (int i = 0; i < length && available.isNotEmpty; i++) {
          final idx = random.nextInt(available.length);
          stickers.add(available[idx]);
          available.removeAt(idx);
        }

        // Use day-level precision to avoid Timestamp microsecond issues
        final baseDays = DateTime(2020).millisecondsSinceEpoch ~/ 86400000;
        const rangeDays = 365 * 5;
        final days = baseDays + random.nextInt(rangeDays);
        final createdAt =
            DateTime.fromMillisecondsSinceEpoch(days * 86400000);

        final comment = Comment(
          id: id,
          authorId: authorId,
          authorName: authorName,
          text: text,
          stickers: stickers,
          createdAt: createdAt,
        );

        return Shrinkable(comment, () => []);
      };
}

// ---------------------------------------------------------------------------
// Helper: base map without 'stickers' key (simulates legacy Firestore doc)
// ---------------------------------------------------------------------------

Map<String, dynamic> _legacyCommentMap({
  String authorId = 'user_legacy',
  String authorName = 'Legacy User',
  String text = 'A legacy comment',
  DateTime? createdAt,
}) {
  return {
    'authorId': authorId,
    'authorName': authorName,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt ?? DateTime(2023, 1, 1)),
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // P5: Round-trip de serialización de Comment
  // Validates: Requirements 6.5
  //
  // For any valid Comment, Comment.fromMap(comment.toMap(), comment.id).stickers
  // must equal the original stickers list.
  // -------------------------------------------------------------------------
  group('P5: Comment serialization round-trip preserves stickers', () {
    // Property-based test: any valid Comment with 0–5 known sticker IDs
    Glados(any.commentWithStickers, ExploreConfig(numRuns: 100)).test(
      'for any valid Comment, fromMap(toMap()).stickers equals original stickers',
      (comment) {
        final map = comment.toMap();
        final restored = Comment.fromMap(map, comment.id);
        expect(
          restored.stickers,
          equals(comment.stickers),
          reason:
              'stickers must survive round-trip for comment ${comment.id}',
        );
      },
    );

    // Edge case: empty stickers list
    test('round-trip with empty stickers list', () {
      final comment = Comment(
        id: 'c_empty',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'No stickers here',
        stickers: const [],
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = Comment.fromMap(comment.toMap(), comment.id);
      expect(restored.stickers, equals([]),
          reason: 'Empty stickers list must survive round-trip');
    });

    // Edge case: exactly 1 sticker
    test('round-trip with 1 sticker', () {
      final comment = Comment(
        id: 'c_one',
        authorId: 'user_2',
        authorName: 'Bob',
        text: 'One sticker',
        stickers: const ['sticker_heart'],
        createdAt: DateTime(2024, 2, 1),
      );
      final restored = Comment.fromMap(comment.toMap(), comment.id);
      expect(restored.stickers, equals(['sticker_heart']),
          reason: 'Single sticker must survive round-trip');
    });

    // Edge case: exactly 5 stickers (maximum)
    test('round-trip with 5 stickers (maximum)', () {
      const fiveStickers = [
        'sticker_heart',
        'sticker_fire',
        'sticker_laugh',
        'sticker_star',
        'sticker_book',
      ];
      final comment = Comment(
        id: 'c_five',
        authorId: 'user_3',
        authorName: 'Carlos',
        text: 'Five stickers',
        stickers: fiveStickers,
        createdAt: DateTime(2024, 3, 1),
      );
      final restored = Comment.fromMap(comment.toMap(), comment.id);
      expect(restored.stickers, equals(fiveStickers),
          reason: 'Five stickers must survive round-trip');
    });

    // Edge case: iterate over subsets of all 20 catalog stickers
    for (int start = 0; start < StickerCatalog.ids.length; start += 5) {
      final subset = StickerCatalog.ids
          .skip(start)
          .take(5)
          .toList();
      test('round-trip with catalog subset starting at index $start: $subset',
          () {
        final comment = Comment(
          id: 'c_subset_$start',
          authorId: 'user_subset',
          authorName: 'Subset User',
          text: 'Subset stickers test',
          stickers: subset,
          createdAt: DateTime(2024, 4, 1),
        );
        final restored = Comment.fromMap(comment.toMap(), comment.id);
        expect(restored.stickers, equals(subset),
            reason: 'Catalog subset $subset must survive round-trip');
      });
    }
  });

  // -------------------------------------------------------------------------
  // P6: Campo condicional en Comment.toMap()
  // Validates: Requirements 6.2
  //
  // comment.toMap() must NOT contain the key 'stickers' when stickers is empty.
  // -------------------------------------------------------------------------
  group('P6: Comment.toMap() omits stickers key when stickers is empty', () {
    // Property-based test: any Comment with empty stickers must not have the key
    Glados(any.commentWithStickers, ExploreConfig(numRuns: 100)).test(
      'toMap() omits stickers key when stickers is empty',
      (comment) {
        // Only test the property for comments with empty stickers
        if (comment.stickers.isEmpty) {
          final map = comment.toMap();
          expect(
            map.containsKey('stickers'),
            isFalse,
            reason:
                'toMap() must NOT include stickers key when stickers is empty',
          );
        }
      },
    );

    // Explicit test: empty stickers → no 'stickers' key
    test('toMap() does not contain stickers key when stickers is empty', () {
      final comment = Comment(
        id: 'c_no_stickers',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'No stickers',
        stickers: const [],
        createdAt: DateTime(2024, 1, 1),
      );
      final map = comment.toMap();
      expect(map.containsKey('stickers'), isFalse,
          reason: 'stickers key must be absent when stickers list is empty');
    });

    // Explicit test: non-empty stickers → 'stickers' key IS present
    test('toMap() includes stickers key when stickers is non-empty', () {
      final comment = Comment(
        id: 'c_with_stickers',
        authorId: 'user_2',
        authorName: 'Bob',
        text: 'With stickers',
        stickers: const ['sticker_heart'],
        createdAt: DateTime(2024, 1, 1),
      );
      final map = comment.toMap();
      expect(map.containsKey('stickers'), isTrue,
          reason: 'stickers key must be present when stickers list is non-empty');
      expect(map['stickers'], equals(['sticker_heart']));
    });

    // Explicit test: stickers values are IDs, not asset paths
    test('toMap() stickers values are IDs, not asset paths', () {
      final comment = Comment(
        id: 'c_ids_only',
        authorId: 'user_3',
        authorName: 'Carlos',
        text: 'IDs only',
        stickers: const ['sticker_fire', 'sticker_star'],
        createdAt: DateTime(2024, 1, 1),
      );
      final map = comment.toMap();
      final stickers = map['stickers'] as List;
      for (final id in stickers) {
        expect(
          (id as String).startsWith('assets/'),
          isFalse,
          reason: 'sticker value "$id" must be an ID, not an asset path',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // P7: Retrocompatibilidad en Comment.fromMap()
  // Validates: Requirements 6.3, 10.1
  //
  // Comment.fromMap(map, id).stickers equals [] when map has no 'stickers' key.
  // -------------------------------------------------------------------------
  group('P7: Comment.fromMap() backward compatibility — missing stickers key', () {
    // Property-based test: maps without 'stickers' key produce empty stickers
    final legacyMaps = [
      _legacyCommentMap(authorId: 'user_1', authorName: 'Alice', text: 'Legacy 1'),
      _legacyCommentMap(authorId: 'user_2', authorName: 'Bob', text: 'Legacy 2'),
      _legacyCommentMap(authorId: 'user_3', authorName: 'Carlos', text: 'Legacy 3'),
      _legacyCommentMap(
          authorId: 'user_4',
          authorName: 'Diana',
          text: 'x' * 100,
          createdAt: DateTime(2022, 6, 15)),
      _legacyCommentMap(
          authorId: 'user_5',
          authorName: 'Eduardo',
          text: 'Short',
          createdAt: DateTime(2021, 12, 31)),
    ];

    test('fromMap() returns empty stickers when map has no stickers key', () {
      for (final map in legacyMaps) {
        expect(
          map.containsKey('stickers'),
          isFalse,
          reason: 'Test setup: legacy map must not have stickers key',
        );
        final comment = Comment.fromMap(map, 'legacy_id');
        expect(
          comment.stickers,
          equals([]),
          reason:
              'stickers must be [] when map has no stickers key (backward compat)',
        );
      }
    });

    // Explicit test: map without stickers key → stickers == []
    test('fromMap() with no stickers key produces empty stickers list', () {
      final map = _legacyCommentMap();
      final comment = Comment.fromMap(map, 'c_legacy');
      expect(comment.stickers, equals([]),
          reason: 'Missing stickers key must produce empty list');
      expect(comment.stickers.isEmpty, isTrue);
    });

    // Explicit test: map with stickers: null → stickers == []
    test('fromMap() with stickers: null produces empty stickers list', () {
      final map = {
        'authorId': 'user_null',
        'authorName': 'Null User',
        'text': 'Null stickers',
        'stickers': null,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };
      final comment = Comment.fromMap(map, 'c_null_stickers');
      expect(comment.stickers, equals([]),
          reason: 'stickers: null must produce empty list');
    });

    // Explicit test: map with stickers present → stickers are populated
    test('fromMap() with stickers key populates stickers correctly', () {
      final map = {
        'authorId': 'user_new',
        'authorName': 'New User',
        'text': 'New comment with stickers',
        'stickers': ['sticker_heart', 'sticker_fire'],
        'createdAt': Timestamp.fromDate(DateTime(2024, 5, 1)),
      };
      final comment = Comment.fromMap(map, 'c_with_stickers');
      expect(comment.stickers, equals(['sticker_heart', 'sticker_fire']),
          reason: 'stickers must be populated from map');
    });

    // Explicit test: fromMap() does not throw for legacy documents
    test('fromMap() does not throw for legacy documents without stickers', () {
      for (final map in legacyMaps) {
        expect(
          () => Comment.fromMap(map, 'legacy_id'),
          returnsNormally,
          reason: 'fromMap() must not throw for legacy documents',
        );
      }
    });
  });
}
