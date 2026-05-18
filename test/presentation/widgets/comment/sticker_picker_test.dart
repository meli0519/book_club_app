// Feature: comment-stickers
// Property 3: Idempotencia del toggle (doble toggle)
// Property 4: El toggle respeta el límite máximo
// Property 12: Solo IDs en onConfirm (no rutas de asset)
//
// Validates: Requirements 2.3, 2.4, 6.1, 8.1, 8.2

import 'package:glados/glados.dart';
import 'package:book_club_app/domain/models/sticker_catalog.dart';
import 'package:book_club_app/presentation/widgets/comment/sticker_picker.dart';

// ---------------------------------------------------------------------------
// Custom generators
// ---------------------------------------------------------------------------

extension AnyStickerPicker on Any {
  /// Generates a list of 0–5 distinct valid sticker IDs from the catalog.
  Generator<List<String>> get validStickerList => (random, size) {
        final maxLen = 5;
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

  /// Generates a valid sticker ID from the catalog.
  Generator<String> get validStickerId => (random, size) {
        final ids = StickerCatalog.ids;
        final id = ids[random.nextInt(ids.length)];
        return Shrinkable(id, () => []);
      };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Property 3: Idempotencia del toggle (doble toggle)
  //
  // Applying toggleSticker twice with the same ID returns a list equivalent
  // to the original.
  //
  // **Validates: Requirements 2.3, 2.4**
  // -------------------------------------------------------------------------
  group('Property 3: Idempotencia del toggle (doble toggle)', () {
    // Exhaustive check over all catalog IDs with representative list sizes.
    for (final id in StickerCatalog.ids) {
      test('double-toggle of "$id" on empty list returns empty list', () {
        const max = 5;
        final after1 = toggleSticker([], id, max);
        final after2 = toggleSticker(after1, id, max);
        expect(after2, equals([]));
      });

      test('double-toggle of "$id" on list containing it returns same list',
          () {
        const max = 5;
        final initial = [id];
        final after1 = toggleSticker(initial, id, max);
        final after2 = toggleSticker(after1, id, max);
        expect(after2, equals(initial));
      });
    }

    // Glados property: for any valid list and any valid ID, double-toggle
    // returns a list with the same elements as the original (set equality).
    //
    // Note: list order may differ when the ID is removed then re-added
    // (it moves to the end), so we compare as sets.
    Glados2(any.validStickerList, any.validStickerId,
            ExploreConfig(numRuns: 200))
        .test(
      'double-toggle always returns a list with the same elements as the original',
      (current, id) {
        const max = 5;
        // Ensure the list has room or already contains the id so the first
        // toggle is not a no-op due to the limit.
        final base = current.contains(id)
            ? current
            : (current.length < max ? current : <String>[]);
        final after1 = toggleSticker(base, id, max);
        final after2 = toggleSticker(after1, id, max);
        // Same elements (set equality) and same length.
        expect(after2.length, equals(base.length));
        expect(after2.toSet(), equals(base.toSet()));
      },
    );
  });

  // -------------------------------------------------------------------------
  // Property 4: El toggle respeta el límite máximo
  //
  // When _selected.length == maxStickers, calling toggleSticker with an ID
  // not already in the list leaves the list unchanged.
  //
  // **Validates: Requirements 2.3, 2.4**
  // -------------------------------------------------------------------------
  group('Property 4: El toggle respeta el límite máximo', () {
    test('toggle with an ID not in list when at max returns list unchanged', () {
      // Build a full list of exactly maxStickers known IDs.
      const max = 5;
      final full = StickerCatalog.ids.take(max).toList();
      // Pick an ID not in the full list.
      final outsideId =
          StickerCatalog.ids.firstWhere((id) => !full.contains(id));

      final result = toggleSticker(full, outsideId, max);
      expect(result, equals(full));
    });

    test('toggle with any ID not in list when at max=1 returns list unchanged',
        () {
      const max = 1;
      final full = [StickerCatalog.ids.first];
      final otherId = StickerCatalog.ids[1];

      final result = toggleSticker(full, otherId, max);
      expect(result, equals(full));
    });

    // Glados property: for any valid ID, toggling it when the list is full
    // (max=5) and does not contain it returns the same list.
    Glados(any.validStickerId, ExploreConfig(numRuns: 200)).test(
      'toggle of an ID not in a full list (max=5) returns list unchanged',
      (id) {
        const max = 5;
        // Build a full list that does NOT contain `id`.
        final others =
            StickerCatalog.ids.where((s) => s != id).take(max).toList();
        if (others.length < max) return; // skip if catalog too small

        final result = toggleSticker(others, id, max);
        expect(result, equals(others));
      },
    );

    // Glados property: result length never exceeds max for any input.
    Glados2(any.validStickerList, any.validStickerId,
            ExploreConfig(numRuns: 200))
        .test(
      'result length never exceeds maxStickers',
      (current, id) {
        const max = 5;
        final result = toggleSticker(current, id, max);
        expect(result.length, lessThanOrEqualTo(max));
      },
    );
  });

  // -------------------------------------------------------------------------
  // Property 12: Solo IDs en onConfirm (no rutas de asset)
  //
  // toggleSticker only ever produces IDs (snake_case strings) and never
  // asset paths (strings starting with 'assets/').
  //
  // **Validates: Requirements 6.1, 8.1, 8.2**
  // -------------------------------------------------------------------------
  group('Property 12: Solo IDs en onConfirm (no rutas de asset)', () {
    test('adding a sticker produces an ID, not an asset path', () {
      const max = 5;
      for (final id in StickerCatalog.ids) {
        final result = toggleSticker([], id, max);
        expect(result, hasLength(1));
        expect(
          result.first.startsWith('assets/'),
          isFalse,
          reason:
              'toggleSticker returned an asset path "${result.first}" instead '
              'of a sticker ID',
        );
        expect(
          result.first,
          equals(id),
          reason: 'Expected ID "$id" but got "${result.first}"',
        );
      }
    });

    // Glados property: for any valid list and any valid ID, the result of
    // toggleSticker never contains strings starting with 'assets/'.
    Glados2(any.validStickerList, any.validStickerId,
            ExploreConfig(numRuns: 200))
        .test(
      'result of toggleSticker never contains asset paths',
      (current, id) {
        const max = 5;
        final result = toggleSticker(current, id, max);
        for (final entry in result) {
          expect(
            entry.startsWith('assets/'),
            isFalse,
            reason:
                'toggleSticker produced an asset path "$entry" instead of a '
                'sticker ID',
          );
        }
      },
    );

    test('result entries are always the same strings that were passed in', () {
      const max = 5;
      for (final id in StickerCatalog.ids) {
        final result = toggleSticker([], id, max);
        for (final entry in result) {
          expect(
            entry,
            equals(id),
            reason: 'toggleSticker returned "$entry" but expected "$id"',
          );
        }
      }
    });
  });

  // -------------------------------------------------------------------------
  // Additional unit tests for toggleSticker correctness
  // -------------------------------------------------------------------------
  group('toggleSticker — unit tests', () {
    test('adds ID to empty list', () {
      final result = toggleSticker([], 'sticker_heart', 5);
      expect(result, equals(['sticker_heart']));
    });

    test('removes ID when already present', () {
      final result = toggleSticker(['sticker_heart'], 'sticker_heart', 5);
      expect(result, equals([]));
    });

    test('does not mutate the original list when adding', () {
      final original = ['sticker_heart'];
      final result = toggleSticker(original, 'sticker_fire', 5);
      expect(original, equals(['sticker_heart']));
      expect(result, equals(['sticker_heart', 'sticker_fire']));
    });

    test('does not mutate the original list when removing', () {
      final original = ['sticker_heart', 'sticker_fire'];
      final result = toggleSticker(original, 'sticker_heart', 5);
      expect(original, equals(['sticker_heart', 'sticker_fire']));
      expect(result, equals(['sticker_fire']));
    });

    test('returns current unchanged when limit reached and ID not in list', () {
      final full = StickerCatalog.ids.take(5).toList();
      final outsideId =
          StickerCatalog.ids.firstWhere((id) => !full.contains(id));
      final result = toggleSticker(full, outsideId, 5);
      expect(result, equals(full));
    });

    test('result length never exceeds max across all catalog IDs', () {
      const max = 3;
      var current = <String>[];
      for (final id in StickerCatalog.ids) {
        current = toggleSticker(current, id, max);
        expect(current.length, lessThanOrEqualTo(max));
      }
    });
  });
}
