// Tests for UserSticker domain model
// Validates: Requirements 1.1, 1.2, 1.3, 1.4

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/user_sticker.dart';

void main() {
  group('UserSticker model', () {
    final testDate = DateTime(2024, 6, 15, 10, 30);

    final sticker = UserSticker(
      id: 'sticker_abc',
      userId: 'user_123',
      imageUrl: 'https://storage.googleapis.com/bucket/user_stickers/user_123/img.png',
      uploadedAt: testDate,
    );

    // -----------------------------------------------------------------------
    // Construction
    // -----------------------------------------------------------------------
    test('stores all fields correctly', () {
      expect(sticker.id, equals('sticker_abc'));
      expect(sticker.userId, equals('user_123'));
      expect(sticker.imageUrl,
          equals('https://storage.googleapis.com/bucket/user_stickers/user_123/img.png'));
      expect(sticker.uploadedAt, equals(testDate));
    });

    // -----------------------------------------------------------------------
    // toMap / fromMap round-trip
    // -----------------------------------------------------------------------
    test('toMap produces correct keys and types', () {
      final map = sticker.toMap();

      expect(map.containsKey('userId'), isTrue);
      expect(map.containsKey('imageUrl'), isTrue);
      expect(map.containsKey('uploadedAt'), isTrue);
      // id is NOT stored in the map (it's the document ID)
      expect(map.containsKey('id'), isFalse);

      expect(map['userId'], equals('user_123'));
      expect(map['imageUrl'],
          equals('https://storage.googleapis.com/bucket/user_stickers/user_123/img.png'));
      expect(map['uploadedAt'], isA<Timestamp>());
    });

    test('fromMap round-trips correctly', () {
      final map = sticker.toMap();
      final restored = UserSticker.fromMap(map, 'sticker_abc');

      expect(restored.id, equals(sticker.id));
      expect(restored.userId, equals(sticker.userId));
      expect(restored.imageUrl, equals(sticker.imageUrl));
      // Timestamps lose sub-second precision — compare to the second
      expect(
        restored.uploadedAt.difference(sticker.uploadedAt).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('fromMap with different document IDs produces different stickers', () {
      final map = sticker.toMap();
      final a = UserSticker.fromMap(map, 'id_A');
      final b = UserSticker.fromMap(map, 'id_B');

      expect(a.id, equals('id_A'));
      expect(b.id, equals('id_B'));
      expect(a, isNot(equals(b)));
    });

    // -----------------------------------------------------------------------
    // Equality
    // -----------------------------------------------------------------------
    test('two stickers with same id/userId/imageUrl are equal', () {
      final copy = UserSticker(
        id: sticker.id,
        userId: sticker.userId,
        imageUrl: sticker.imageUrl,
        uploadedAt: DateTime(2025, 1, 1), // different date — not part of ==
      );
      expect(sticker, equals(copy));
    });

    test('stickers with different ids are not equal', () {
      final other = UserSticker(
        id: 'other_id',
        userId: sticker.userId,
        imageUrl: sticker.imageUrl,
        uploadedAt: sticker.uploadedAt,
      );
      expect(sticker, isNot(equals(other)));
    });

    // -----------------------------------------------------------------------
    // imageUrl contains Firebase Storage URL
    // -----------------------------------------------------------------------
    test('imageUrl starts with https (Firebase Storage download URL)', () {
      expect(sticker.imageUrl.startsWith('https'), isTrue);
    });

    // -----------------------------------------------------------------------
    // Multiple stickers for same user
    // -----------------------------------------------------------------------
    test('multiple stickers for same user have different ids', () {
      final stickers = List.generate(
        5,
        (i) => UserSticker(
          id: 'sticker_$i',
          userId: 'user_123',
          imageUrl: 'https://example.com/sticker_$i.png',
          uploadedAt: DateTime(2024, 1, i + 1),
        ),
      );

      final ids = stickers.map((s) => s.id).toSet();
      expect(ids.length, equals(5), reason: 'All sticker IDs must be unique');
    });
  });
}
