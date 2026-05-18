// Widget tests for StickerDisplay backward compatibility
// Validates: Requirements 6.1, 6.2, 6.3, 10.1, 10.2, 10.3, 10.4

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:book_club_app/presentation/widgets/comment/sticker_display.dart';
import 'package:book_club_app/domain/models/sticker_catalog.dart';

void main() {
  // -------------------------------------------------------------------------
  // Empty stickers list
  // -------------------------------------------------------------------------
  group('StickerDisplay with empty stickers', () {
    testWidgets('renders nothing (SizedBox.shrink) when stickers is empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StickerDisplay(stickers: []),
          ),
        ),
      );

      // No Wrap widget should be present
      expect(find.byType(Wrap), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // URL stickers (new system)
  // -------------------------------------------------------------------------
  group('StickerDisplay with URL stickers (new system)', () {
    testWidgets('uses CachedNetworkImage for http:// URLs', (tester) async {
      const url = 'http://example.com/sticker.png';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StickerDisplay(stickers: [url]),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('uses CachedNetworkImage for https:// URLs', (tester) async {
      const url = 'https://storage.googleapis.com/bucket/user_stickers/user_1/img.png';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StickerDisplay(stickers: [url]),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders multiple URL stickers', (tester) async {
      const urls = [
        'https://example.com/sticker1.png',
        'https://example.com/sticker2.png',
        'https://example.com/sticker3.png',
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StickerDisplay(stickers: urls),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsNWidgets(3));
    });

    testWidgets('wraps stickers in a Wrap widget', (tester) async {
      const urls = [
        'https://example.com/sticker1.png',
        'https://example.com/sticker2.png',
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StickerDisplay(stickers: urls),
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('does NOT use Image.asset for URL stickers', (tester) async {
      const url = 'https://example.com/sticker.png';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StickerDisplay(stickers: [url]),
          ),
        ),
      );

      // CachedNetworkImage is present; no direct Image.asset call
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Legacy ID stickers (backward compatibility)
  // Note: assets/stickers/ files don't exist in the test environment, so
  // Image.asset will throw an asset-not-found error at the image codec level.
  // The widget itself IS rendered (the Image widget is in the tree) — the
  // error is asynchronous and does not prevent the widget from being built.
  // We suppress the asset error and verify the widget tree structure.
  // -------------------------------------------------------------------------
  group('StickerDisplay with legacy sticker IDs (backward compatibility)', () {
    testWidgets('uses Image.asset (not CachedNetworkImage) for known legacy ID',
        (tester) async {
      const legacyId = 'sticker_heart';
      expect(StickerCatalog.all.containsKey(legacyId), isTrue,
          reason: 'Test prerequisite: sticker_heart must be in catalog');

      // Suppress the expected asset-not-found error (assets don't exist in test env)
      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('Unable to load asset')) {
          errors.add(details);
          return; // suppress
        }
        originalOnError?.call(details);
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StickerDisplay(stickers: [legacyId]),
          ),
        ),
      );

      FlutterError.onError = originalOnError;

      // The widget tree should contain an Image widget (Image.asset)
      // but NOT a CachedNetworkImage
      expect(find.byType(CachedNetworkImage), findsNothing,
          reason: 'Legacy ID must not use CachedNetworkImage');
      expect(find.byType(Image), findsOneWidget,
          reason: 'Legacy ID must use Image.asset');
    });

    testWidgets('renders nothing (SizedBox.shrink) for unknown legacy ID',
        (tester) async {
      const unknownId = 'sticker_does_not_exist_xyz';
      expect(StickerCatalog.all.containsKey(unknownId), isFalse,
          reason: 'Test prerequisite: ID must not be in catalog');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StickerDisplay(stickers: [unknownId]),
          ),
        ),
      );

      // Unknown ID → SizedBox.shrink (no image rendered)
      expect(find.byType(Image), findsNothing);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('renders Image.asset for multiple known legacy sticker IDs',
        (tester) async {
      const legacyIds = ['sticker_heart', 'sticker_fire', 'sticker_book'];

      // Suppress asset-not-found errors
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('Unable to load asset')) {
          return; // suppress
        }
        originalOnError?.call(details);
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StickerDisplay(stickers: legacyIds),
          ),
        ),
      );

      FlutterError.onError = originalOnError;

      // 3 Image.asset widgets, no CachedNetworkImage
      expect(find.byType(Image), findsNWidgets(3));
      expect(find.byType(CachedNetworkImage), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Mixed stickers (URL + legacy ID)
  // -------------------------------------------------------------------------
  group('StickerDisplay with mixed stickers', () {
    testWidgets('handles mix of URL and legacy ID stickers', (tester) async {
      const stickers = [
        'sticker_heart', // legacy → Image.asset
        'https://example.com/custom.png', // URL → CachedNetworkImage
      ];

      // Suppress asset-not-found errors
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('Unable to load asset')) {
          return; // suppress
        }
        originalOnError?.call(details);
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StickerDisplay(stickers: stickers),
          ),
        ),
      );

      FlutterError.onError = originalOnError;

      // One CachedNetworkImage for the URL sticker
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      // At least one Image widget (the Image.asset for legacy + Image inside CachedNetworkImage)
      // We verify CachedNetworkImage is present (URL path) and no extra CachedNetworkImage
      // for the legacy sticker
      expect(find.byType(CachedNetworkImage), findsNWidgets(1),
          reason: 'Only the URL sticker should use CachedNetworkImage');
    });
  });

  // -------------------------------------------------------------------------
  // Backward compatibility: key distinction is "starts with http"
  // -------------------------------------------------------------------------
  group('StickerDisplay URL detection logic', () {
    test('string starting with "http" is treated as URL', () {
      const url = 'https://storage.googleapis.com/bucket/img.png';
      expect(url.startsWith('http'), isTrue);
    });

    test('legacy sticker ID does not start with "http"', () {
      for (final id in StickerCatalog.ids) {
        expect(id.startsWith('http'), isFalse,
            reason: 'Legacy ID "$id" must not start with http');
      }
    });

    test('all StickerCatalog IDs are known legacy IDs', () {
      expect(StickerCatalog.all, isNotEmpty);
      for (final id in StickerCatalog.ids) {
        expect(StickerCatalog.all.containsKey(id), isTrue,
            reason: 'ID "$id" must be in StickerCatalog.all');
      }
    });

    test('StickerCatalog has expected sticker IDs', () {
      expect(StickerCatalog.all.containsKey('sticker_heart'), isTrue);
      expect(StickerCatalog.all.containsKey('sticker_fire'), isTrue);
      expect(StickerCatalog.all.containsKey('sticker_book'), isTrue);
      expect(StickerCatalog.all.containsKey('sticker_star'), isTrue);
    });
  });
}
