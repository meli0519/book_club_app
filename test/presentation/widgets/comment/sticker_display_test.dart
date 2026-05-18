import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:book_club_app/presentation/widgets/comment/sticker_display.dart';

/// Property-based widget tests for [StickerDisplay].
///
/// **Property 11: StickerDisplay solo renderiza URLs válidas**
///
/// [StickerDisplay] SHALL render only stickers whose string starts with "http".
/// Legacy IDs (e.g. 'sticker_heart') are silently ignored.
///
/// **Validates: Requirements 6.1, 6.2, 6.3, 10.2, 10.4**
void main() {
  // Helper: wraps StickerDisplay in a minimal MaterialApp.
  Widget buildSubject(List<String> stickers) {
    return MaterialApp(
      home: Scaffold(
        body: StickerDisplay(stickers: stickers),
      ),
    );
  }

  const sampleUrl = 'https://example.com/sticker.png';
  const anotherUrl = 'https://example.com/sticker2.png';

  group('StickerDisplay — solo renderiza URLs', () {
    // -----------------------------------------------------------------------
    // Case 1: Empty list → renders nothing
    // -----------------------------------------------------------------------
    testWidgets(
      'empty stickers list renders no widgets',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildSubject([]));

        expect(tester.takeException(), isNull);
        expect(find.byType(CachedNetworkImage), findsNothing);
      },
    );

    // -----------------------------------------------------------------------
    // Case 2: Legacy IDs only → renders nothing (silently ignored)
    // -----------------------------------------------------------------------
    testWidgets(
      'legacy IDs are silently ignored and render nothing',
      (WidgetTester tester) async {
        const legacyIds = [
          'sticker_heart',
          'sticker_fire',
          'sticker_laugh',
          'sticker_book',
        ];

        await tester.pumpWidget(buildSubject(legacyIds));

        expect(tester.takeException(), isNull);
        expect(find.byType(CachedNetworkImage), findsNothing);
        // Widget collapses to SizedBox.shrink
        expect(find.byType(Wrap), findsNothing);
      },
    );

    // -----------------------------------------------------------------------
    // Case 3: Single URL → renders one CachedNetworkImage
    // -----------------------------------------------------------------------
    testWidgets(
      'single URL renders one CachedNetworkImage',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildSubject([sampleUrl]));

        expect(tester.takeException(), isNull);
        expect(find.byType(CachedNetworkImage), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // Case 4: Multiple URLs → renders all of them
    // -----------------------------------------------------------------------
    testWidgets(
      'multiple URLs render the correct number of CachedNetworkImage widgets',
      (WidgetTester tester) async {
        final urls = [sampleUrl, anotherUrl];

        await tester.pumpWidget(buildSubject(urls));

        expect(tester.takeException(), isNull);
        expect(find.byType(CachedNetworkImage), findsNWidgets(urls.length));
      },
    );

    // -----------------------------------------------------------------------
    // Case 5: Mix of URLs and legacy IDs → renders only URLs
    // -----------------------------------------------------------------------
    testWidgets(
      'mix of URLs and legacy IDs renders only the URLs',
      (WidgetTester tester) async {
        final mixed = [sampleUrl, 'sticker_heart', anotherUrl, 'sticker_fire'];

        await tester.pumpWidget(buildSubject(mixed));

        expect(tester.takeException(), isNull);
        // Only the 2 URLs should produce CachedNetworkImage widgets
        expect(find.byType(CachedNetworkImage), findsNWidgets(2));
      },
    );

    // -----------------------------------------------------------------------
    // Case 6: Unknown non-http strings → renders nothing
    // -----------------------------------------------------------------------
    testWidgets(
      'unknown non-http strings render nothing',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildSubject(['sticker_unknown_1', 'not_a_url', 'random_string']),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(CachedNetworkImage), findsNothing);
      },
    );

    // -----------------------------------------------------------------------
    // Property: URLs are displayed in a Wrap widget
    // -----------------------------------------------------------------------
    testWidgets(
      'URLs are wrapped in a Wrap widget',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildSubject([sampleUrl]));

        expect(tester.takeException(), isNull);
        expect(find.byType(Wrap), findsOneWidget);
      },
    );
  });
}
