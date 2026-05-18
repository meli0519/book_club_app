// Feature: comment-stickers
// Property 8: Round-trip de serialización de PersonalNote
// Property 9: Campo condicional en PersonalNote.toMap()
// Property 10: Retrocompatibilidad en PersonalNote.fromMap()
//
// Validates: Requirements 7.2, 7.3, 7.5, 10.2

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glados/glados.dart';

import 'package:book_club_app/domain/models/personal_note.dart';
import 'package:book_club_app/domain/models/sticker_catalog.dart';

// ---------------------------------------------------------------------------
// Custom Arbitrary generator for valid PersonalNote objects
// ---------------------------------------------------------------------------

extension AnyPersonalNoteStickers on Any {
  /// Generates a valid stickers list: length 0–5, all IDs from StickerCatalog.ids.
  Generator<List<String>> get validStickerList => (random, size) {
        const maxLen = 5;
        final length = random.nextInt(maxLen + 1); // 0..5
        final available = List<String>.from(StickerCatalog.ids);
        final selected = <String>[];
        for (int i = 0; i < length && available.isNotEmpty; i++) {
          final idx = random.nextInt(available.length);
          selected.add(available[idx]);
          available.removeAt(idx);
        }
        return Shrinkable(selected, () => []);
      };

  /// Generates a complete valid PersonalNote with a valid stickers list.
  Generator<PersonalNote> get personalNoteWithStickers => (random, size) {
        final texts = [
          'Great chapter!',
          'I loved this part.',
          'Very insightful.',
          'Looking forward to the next section.',
          'Excelente lectura, muy recomendada.',
          'La nota fue muy productiva.',
          'x' * 100,
          'Short',
        ];

        final text = texts[random.nextInt(texts.length)];

        // Generate stickers list (0–5 distinct IDs)
        const maxLen = 5;
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

        final note = PersonalNote(
          text: text,
          stickers: stickers,
          createdAt: createdAt,
        );

        return Shrinkable(note, () => []);
      };
}

// ---------------------------------------------------------------------------
// Helper: base map without 'stickers' key (simulates legacy Firestore doc)
// ---------------------------------------------------------------------------

Map<String, dynamic> _legacyPersonalNoteMap({
  String text = 'A legacy note',
  DateTime? createdAt,
}) {
  return {
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt ?? DateTime(2023, 1, 1)),
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // P8: Round-trip de serialización de PersonalNote
  // Validates: Requirements 7.5
  //
  // For any valid PersonalNote, PersonalNote.fromMap(note.toMap()).stickers
  // must equal the original stickers list.
  // -------------------------------------------------------------------------
  group('P8: PersonalNote serialization round-trip preserves stickers', () {
    // Property-based test: any valid PersonalNote with 0–5 known sticker IDs
    Glados(any.personalNoteWithStickers, ExploreConfig(numRuns: 100)).test(
      'for any valid PersonalNote, fromMap(toMap()).stickers equals original stickers',
      (note) {
        final map = note.toMap();
        final restored = PersonalNote.fromMap(map);
        expect(
          restored.stickers,
          equals(note.stickers),
          reason: 'stickers must survive round-trip for PersonalNote',
        );
      },
    );

    // Edge case: empty stickers list
    test('round-trip with empty stickers list', () {
      final note = PersonalNote(
        text: 'No stickers here',
        stickers: const [],
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = PersonalNote.fromMap(note.toMap());
      expect(restored.stickers, equals([]),
          reason: 'Empty stickers list must survive round-trip');
    });

    // Edge case: exactly 1 sticker
    test('round-trip with 1 sticker', () {
      final note = PersonalNote(
        text: 'One sticker',
        stickers: const ['sticker_heart'],
        createdAt: DateTime(2024, 2, 1),
      );
      final restored = PersonalNote.fromMap(note.toMap());
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
      final note = PersonalNote(
        text: 'Five stickers',
        stickers: fiveStickers,
        createdAt: DateTime(2024, 3, 1),
      );
      final restored = PersonalNote.fromMap(note.toMap());
      expect(restored.stickers, equals(fiveStickers),
          reason: 'Five stickers must survive round-trip');
    });

    // Edge case: iterate over subsets of all 20 catalog stickers
    for (int start = 0; start < StickerCatalog.ids.length; start += 5) {
      final subset = StickerCatalog.ids.skip(start).take(5).toList();
      test('round-trip with catalog subset starting at index $start: $subset',
          () {
        final note = PersonalNote(
          text: 'Subset stickers test',
          stickers: subset,
          createdAt: DateTime(2024, 4, 1),
        );
        final restored = PersonalNote.fromMap(note.toMap());
        expect(restored.stickers, equals(subset),
            reason: 'Catalog subset $subset must survive round-trip');
      });
    }
  });

  // -------------------------------------------------------------------------
  // P9: Campo condicional en PersonalNote.toMap()
  // Validates: Requirements 7.2
  //
  // note.toMap() must NOT contain the key 'stickers' when stickers is empty.
  // -------------------------------------------------------------------------
  group('P9: PersonalNote.toMap() omits stickers key when stickers is empty',
      () {
    // Property-based test: any PersonalNote with empty stickers must not have the key
    Glados(any.personalNoteWithStickers, ExploreConfig(numRuns: 100)).test(
      'toMap() omits stickers key when stickers is empty',
      (note) {
        if (note.stickers.isEmpty) {
          final map = note.toMap();
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
      final note = PersonalNote(
        text: 'No stickers',
        stickers: const [],
        createdAt: DateTime(2024, 1, 1),
      );
      final map = note.toMap();
      expect(map.containsKey('stickers'), isFalse,
          reason: 'stickers key must be absent when stickers list is empty');
    });

    // Explicit test: non-empty stickers → 'stickers' key IS present
    test('toMap() includes stickers key when stickers is non-empty', () {
      final note = PersonalNote(
        text: 'With stickers',
        stickers: const ['sticker_heart'],
        createdAt: DateTime(2024, 1, 1),
      );
      final map = note.toMap();
      expect(map.containsKey('stickers'), isTrue,
          reason:
              'stickers key must be present when stickers list is non-empty');
      expect(map['stickers'], equals(['sticker_heart']));
    });

    // Explicit test: stickers values are IDs, not asset paths
    test('toMap() stickers values are IDs, not asset paths', () {
      final note = PersonalNote(
        text: 'IDs only',
        stickers: const ['sticker_fire', 'sticker_star'],
        createdAt: DateTime(2024, 1, 1),
      );
      final map = note.toMap();
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
  // P10: Retrocompatibilidad en PersonalNote.fromMap()
  // Validates: Requirements 7.3, 10.2
  //
  // PersonalNote.fromMap(map).stickers equals [] when map has no 'stickers' key.
  // -------------------------------------------------------------------------
  group(
      'P10: PersonalNote.fromMap() backward compatibility — missing stickers key',
      () {
    final legacyMaps = [
      _legacyPersonalNoteMap(text: 'Legacy note 1'),
      _legacyPersonalNoteMap(text: 'Legacy note 2'),
      _legacyPersonalNoteMap(text: 'Legacy note 3'),
      _legacyPersonalNoteMap(
          text: 'x' * 100, createdAt: DateTime(2022, 6, 15)),
      _legacyPersonalNoteMap(text: 'Short', createdAt: DateTime(2021, 12, 31)),
    ];

    test('fromMap() returns empty stickers when map has no stickers key', () {
      for (final map in legacyMaps) {
        expect(
          map.containsKey('stickers'),
          isFalse,
          reason: 'Test setup: legacy map must not have stickers key',
        );
        final note = PersonalNote.fromMap(map);
        expect(
          note.stickers,
          equals([]),
          reason:
              'stickers must be [] when map has no stickers key (backward compat)',
        );
      }
    });

    // Explicit test: map without stickers key → stickers == []
    test('fromMap() with no stickers key produces empty stickers list', () {
      final map = _legacyPersonalNoteMap();
      final note = PersonalNote.fromMap(map);
      expect(note.stickers, equals([]),
          reason: 'Missing stickers key must produce empty list');
      expect(note.stickers.isEmpty, isTrue);
    });

    // Explicit test: map with stickers: null → stickers == []
    test('fromMap() with stickers: null produces empty stickers list', () {
      final map = {
        'text': 'Null stickers',
        'stickers': null,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };
      final note = PersonalNote.fromMap(map);
      expect(note.stickers, equals([]),
          reason: 'stickers: null must produce empty list');
    });

    // Explicit test: map with stickers present → stickers are populated
    test('fromMap() with stickers key populates stickers correctly', () {
      final map = {
        'text': 'New note with stickers',
        'stickers': ['sticker_heart', 'sticker_fire'],
        'createdAt': Timestamp.fromDate(DateTime(2024, 5, 1)),
      };
      final note = PersonalNote.fromMap(map);
      expect(note.stickers, equals(['sticker_heart', 'sticker_fire']),
          reason: 'stickers must be populated from map');
    });

    // Explicit test: fromMap() does not throw for legacy documents
    test('fromMap() does not throw for legacy documents without stickers', () {
      for (final map in legacyMaps) {
        expect(
          () => PersonalNote.fromMap(map),
          returnsNormally,
          reason: 'fromMap() must not throw for legacy documents',
        );
      }
    });
  });
}
