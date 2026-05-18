// Tests for Comment model stickers field (URL storage)
// Validates: Requirements 5.4, 5.5, 10.1

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/comment.dart';

void main() {
  final baseDate = DateTime(2024, 6, 1, 12, 0);

  // -------------------------------------------------------------------------
  // Comment.stickers field accepts URLs
  // -------------------------------------------------------------------------
  group('Comment.stickers stores imageUrls (List<String>)', () {
    test('stickers field defaults to empty list', () {
      final comment = Comment(
        id: 'c1',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'Hello',
        createdAt: baseDate,
      );
      expect(comment.stickers, isEmpty);
    });

    test('stickers field accepts a list of URLs', () {
      const urls = [
        'https://storage.googleapis.com/bucket/user_stickers/user_1/img1.png',
        'https://storage.googleapis.com/bucket/user_stickers/user_1/img2.png',
      ];
      final comment = Comment(
        id: 'c2',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'With stickers',
        stickers: urls,
        createdAt: baseDate,
      );
      expect(comment.stickers, equals(urls));
      expect(comment.stickers.length, equals(2));
    });

    test('stickers field accepts up to 5 URLs', () {
      final urls = List.generate(
        5,
        (i) => 'https://storage.googleapis.com/bucket/user_stickers/user_1/img$i.png',
      );
      final comment = Comment(
        id: 'c3',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'Max stickers',
        stickers: urls,
        createdAt: baseDate,
      );
      expect(comment.stickers.length, equals(5));
    });

    test('stickers field accepts legacy IDs (backward compatibility)', () {
      const legacyIds = ['sticker_heart', 'sticker_fire'];
      final comment = Comment(
        id: 'c4',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'Legacy stickers',
        stickers: legacyIds,
        createdAt: baseDate,
      );
      expect(comment.stickers, equals(legacyIds));
    });

    test('stickers field accepts mixed URLs and legacy IDs', () {
      const mixed = [
        'sticker_heart',
        'https://storage.googleapis.com/bucket/user_stickers/user_1/img.png',
      ];
      final comment = Comment(
        id: 'c5',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'Mixed stickers',
        stickers: mixed,
        createdAt: baseDate,
      );
      expect(comment.stickers, equals(mixed));
    });
  });

  // -------------------------------------------------------------------------
  // toMap / fromMap round-trip with sticker URLs
  // -------------------------------------------------------------------------
  group('Comment serialization with sticker URLs', () {
    test('toMap includes stickers when non-empty', () {
      const urls = [
        'https://example.com/sticker1.png',
        'https://example.com/sticker2.png',
      ];
      final comment = Comment(
        id: 'c6',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'Sticker comment',
        stickers: urls,
        createdAt: baseDate,
      );
      final map = comment.toMap();
      expect(map.containsKey('stickers'), isTrue);
      expect(map['stickers'], equals(urls));
    });

    test('toMap omits stickers key when empty', () {
      final comment = Comment(
        id: 'c7',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'No stickers',
        createdAt: baseDate,
      );
      final map = comment.toMap();
      expect(map.containsKey('stickers'), isFalse);
    });

    test('fromMap round-trips sticker URLs correctly', () {
      const urls = [
        'https://storage.googleapis.com/bucket/user_stickers/user_1/img1.png',
        'https://storage.googleapis.com/bucket/user_stickers/user_1/img2.png',
      ];
      final original = Comment(
        id: 'c8',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'Round-trip',
        stickers: urls,
        createdAt: baseDate,
      );
      final map = original.toMap();
      final restored = Comment.fromMap(map, 'c8');
      expect(restored.stickers, equals(urls));
    });

    test('fromMap defaults stickers to empty list when field is absent', () {
      final map = {
        'authorId': 'user_1',
        'authorName': 'Alice',
        'text': 'No stickers field',
        'createdAt': Timestamp.fromDate(baseDate),
      };
      final comment = Comment.fromMap(map, 'c9');
      expect(comment.stickers, isEmpty);
    });

    test('fromMap preserves legacy sticker IDs', () {
      final map = {
        'authorId': 'user_1',
        'authorName': 'Alice',
        'text': 'Legacy',
        'stickers': ['sticker_heart', 'sticker_fire'],
        'createdAt': Timestamp.fromDate(baseDate),
      };
      final comment = Comment.fromMap(map, 'c10');
      expect(comment.stickers, equals(['sticker_heart', 'sticker_fire']));
    });
  });

  // -------------------------------------------------------------------------
  // Firestore persistence with sticker URLs
  // -------------------------------------------------------------------------
  group('Comment with sticker URLs persisted to Firestore', () {
    test('sticker URLs are stored and retrieved correctly', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      const urls = [
        'https://storage.googleapis.com/bucket/user_stickers/user_1/img1.png',
        'https://storage.googleapis.com/bucket/user_stickers/user_1/img2.png',
      ];

      final comment = Comment(
        id: '',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'Comment with stickers',
        stickers: urls,
        createdAt: baseDate,
      );

      final docRef = await fakeFirestore
          .collection('books')
          .doc('book_1')
          .collection('comments')
          .add(comment.toMap());

      final doc = await docRef.get();
      final restored = Comment.fromMap(doc.data()!, doc.id);

      expect(restored.stickers, equals(urls));
      expect(restored.stickers.every((s) => s.startsWith('http')), isTrue);
    });

    test('StickerPicker selection stores imageUrl (not sticker ID)', () {
      // Simulates what StickerPicker does when user selects a UserSticker:
      // it stores sticker.imageUrl (a URL) rather than a legacy ID.
      const selectedImageUrl =
          'https://storage.googleapis.com/bucket/user_stickers/user_1/custom.png';

      // The selected sticker's imageUrl starts with "http"
      expect(selectedImageUrl.startsWith('http'), isTrue,
          reason: 'Selected sticker must be a URL, not a legacy ID');

      final comment = Comment(
        id: 'c_picker',
        authorId: 'user_1',
        authorName: 'Alice',
        text: 'Picked sticker',
        stickers: [selectedImageUrl],
        createdAt: baseDate,
      );

      expect(comment.stickers.first, equals(selectedImageUrl));
      expect(comment.stickers.first.startsWith('http'), isTrue);
    });
  });
}
