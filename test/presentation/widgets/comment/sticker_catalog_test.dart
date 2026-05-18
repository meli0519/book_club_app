import 'package:flutter_test/flutter_test.dart';
import 'package:book_club_app/domain/models/sticker_catalog.dart';

/// Tests de propiedades para [StickerCatalog].
///
/// Dado que [StickerCatalog] es un catálogo estático (no generado aleatoriamente),
/// las propiedades se verifican iterando sobre todas las entradas del catálogo.
///
/// **Validates: Requirements 1.1, 1.2, 1.3, 1.4**
void main() {
  group('StickerCatalog', () {
    // -------------------------------------------------------------------------
    // Property 1: Consistencia del catálogo
    //
    // Para todo ID en StickerCatalog.ids, ese ID debe ser también una clave en
    // StickerCatalog.all, y viceversa — las dos colecciones están siempre en sync.
    //
    // Validates: Requirements 1.2, 1.3
    // -------------------------------------------------------------------------
    group('Property 1: Consistencia del catálogo', () {
      test(
        'every ID in StickerCatalog.ids is also a key in StickerCatalog.all',
        () {
          for (final id in StickerCatalog.ids) {
            expect(
              StickerCatalog.all.containsKey(id),
              isTrue,
              reason: 'ID "$id" está en ids pero no es clave en all',
            );
          }
        },
      );

      test(
        'every key in StickerCatalog.all is also present in StickerCatalog.ids',
        () {
          for (final key in StickerCatalog.all.keys) {
            expect(
              StickerCatalog.ids.contains(key),
              isTrue,
              reason: 'Clave "$key" está en all pero no está en ids',
            );
          }
        },
      );

      test(
        'StickerCatalog.ids and StickerCatalog.all.keys have the same length',
        () {
          expect(
            StickerCatalog.ids.length,
            equals(StickerCatalog.all.length),
            reason:
                'ids tiene ${StickerCatalog.ids.length} elementos pero all tiene '
                '${StickerCatalog.all.length} claves',
          );
        },
      );

      test('StickerCatalog contains exactly 20 stickers', () {
        expect(
          StickerCatalog.ids.length,
          equals(20),
          reason: 'El catálogo debe tener exactamente 20 stickers (Req 1.1)',
        );
        expect(
          StickerCatalog.all.length,
          equals(20),
          reason: 'El mapa all debe tener exactamente 20 entradas (Req 1.1)',
        );
      });

      test('StickerCatalog.ids contains no duplicate IDs', () {
        final uniqueIds = StickerCatalog.ids.toSet();
        expect(
          uniqueIds.length,
          equals(StickerCatalog.ids.length),
          reason: 'ids contiene IDs duplicados',
        );
      });
    });

    // -------------------------------------------------------------------------
    // Property 2: Rutas de asset válidas
    //
    // Para toda entrada en StickerCatalog.all, el valor (ruta de asset) debe
    // coincidir con el patrón assets/stickers/<sticker_id>.png.
    //
    // Validates: Requirement 1.4
    // -------------------------------------------------------------------------
    group('Property 2: Rutas de asset válidas', () {
      test(
        'every asset path in StickerCatalog.all matches assets/stickers/<id>.png',
        () {
          for (final entry in StickerCatalog.all.entries) {
            final id = entry.key;
            final path = entry.value;
            final expectedPath = 'assets/stickers/$id.png';

            expect(
              path,
              equals(expectedPath),
              reason:
                  'La ruta del sticker "$id" es "$path" pero se esperaba '
                  '"$expectedPath"',
            );
          }
        },
      );

      test(
        'every asset path starts with "assets/stickers/" and ends with ".png"',
        () {
          for (final entry in StickerCatalog.all.entries) {
            final path = entry.value;

            expect(
              path.startsWith('assets/stickers/'),
              isTrue,
              reason: 'La ruta "$path" no comienza con "assets/stickers/"',
            );

            expect(
              path.endsWith('.png'),
              isTrue,
              reason: 'La ruta "$path" no termina con ".png"',
            );
          }
        },
      );

      test(
        'asset path filename matches the sticker ID (no path traversal or '
        'unexpected characters)',
        () {
          // Patrón: assets/stickers/<id>.png donde <id> es snake_case
          final validPathPattern = RegExp(r'^assets/stickers/[a-z][a-z0-9_]*\.png$');

          for (final entry in StickerCatalog.all.entries) {
            final path = entry.value;

            expect(
              validPathPattern.hasMatch(path),
              isTrue,
              reason:
                  'La ruta "$path" no coincide con el patrón '
                  'assets/stickers/<snake_case_id>.png',
            );
          }
        },
      );
    });
  });
}
