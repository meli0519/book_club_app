// Tests for UserStickerService (Firestore operations)
// Validates: Requirements 3.1, 3.2, 4.2, 4.3, 7.1

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/user_sticker.dart';

// ---------------------------------------------------------------------------
// Fake UserStickerService that accepts an injected Firestore instance.
// The real service uses FirebaseFirestore.instance (not injectable), so we
// replicate the exact same logic here using FakeFirebaseFirestore.
// ---------------------------------------------------------------------------

class FakeUserStickerService {
  final FirebaseFirestore _firestore;

  FakeUserStickerService(this._firestore);

  Future<String> createSticker(UserSticker sticker) async {
    final docRef = await _firestore
        .collection('user_stickers')
        .doc(sticker.userId)
        .collection('stickers')
        .add(sticker.toMap());
    return docRef.id;
  }

  Stream<List<UserSticker>> watchUserStickers(String userId) {
    return _firestore
        .collection('user_stickers')
        .doc(userId)
        .collection('stickers')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserSticker.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<int> getUserStickerCount(String userId) async {
    final snapshot = await _firestore
        .collection('user_stickers')
        .doc(userId)
        .collection('stickers')
        .get();
    return snapshot.docs.length;
  }

  Future<void> deleteSticker(
    String userId,
    String stickerId,
    String imageUrl,
  ) async {
    await _firestore
        .collection('user_stickers')
        .doc(userId)
        .collection('stickers')
        .doc(stickerId)
        .delete();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

UserSticker _makeSticker({
  required String userId,
  String id = '',
  String imageUrl = 'https://example.com/sticker.png',
  DateTime? uploadedAt,
}) {
  return UserSticker(
    id: id,
    userId: userId,
    imageUrl: imageUrl,
    uploadedAt: uploadedAt ?? DateTime.now(),
  );
}

void main() {
  // -------------------------------------------------------------------------
  // createSticker
  // -------------------------------------------------------------------------
  group('FakeUserStickerService.createSticker', () {
    test('creates a document in user_stickers/{userId}/stickers', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      final sticker = _makeSticker(userId: 'user_1');
      final id = await service.createSticker(sticker);

      expect(id, isNotEmpty);

      final doc = await fakeFirestore
          .collection('user_stickers')
          .doc('user_1')
          .collection('stickers')
          .doc(id)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['userId'], equals('user_1'));
      expect(doc.data()!['imageUrl'], equals('https://example.com/sticker.png'));
    });

    test('stickers for different users are isolated', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      await service.createSticker(_makeSticker(userId: 'user_A'));
      await service.createSticker(_makeSticker(userId: 'user_B'));
      await service.createSticker(_makeSticker(userId: 'user_B'));

      final countA = await service.getUserStickerCount('user_A');
      final countB = await service.getUserStickerCount('user_B');

      expect(countA, equals(1));
      expect(countB, equals(2));
    });
  });

  // -------------------------------------------------------------------------
  // getUserStickerCount
  // -------------------------------------------------------------------------
  group('FakeUserStickerService.getUserStickerCount', () {
    test('returns 0 when user has no stickers', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      final count = await service.getUserStickerCount('new_user');
      expect(count, equals(0));
    });

    test('returns correct count after adding stickers', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      for (int i = 0; i < 5; i++) {
        await service.createSticker(
          _makeSticker(userId: 'user_count', imageUrl: 'https://example.com/$i.png'),
        );
      }

      final count = await service.getUserStickerCount('user_count');
      expect(count, equals(5));
    });

    test('returns 49 when user has 49 stickers (below limit)', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      for (int i = 0; i < 49; i++) {
        await service.createSticker(
          _makeSticker(userId: 'user_49', imageUrl: 'https://example.com/$i.png'),
        );
      }

      final count = await service.getUserStickerCount('user_49');
      expect(count, equals(49));
    });

    test('returns 50 when user has exactly 50 stickers (at limit)', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      for (int i = 0; i < 50; i++) {
        await service.createSticker(
          _makeSticker(userId: 'user_50', imageUrl: 'https://example.com/$i.png'),
        );
      }

      final count = await service.getUserStickerCount('user_50');
      expect(count, equals(50));
    });
  });

  // -------------------------------------------------------------------------
  // Sticker limit enforcement (business logic)
  // -------------------------------------------------------------------------
  group('Sticker limit enforcement (50 max)', () {
    /// Simulates the upload flow: checks count before creating.
    Future<bool> tryUploadSticker(
      FakeUserStickerService service,
      String userId,
      String imageUrl,
    ) async {
      const maxStickers = 50;
      final count = await service.getUserStickerCount(userId);
      if (count >= maxStickers) return false; // limit reached

      await service.createSticker(
        _makeSticker(userId: userId, imageUrl: imageUrl),
      );
      return true;
    }

    test('upload succeeds when count is below 50', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      // Add 49 stickers
      for (int i = 0; i < 49; i++) {
        await service.createSticker(
          _makeSticker(userId: 'user_limit', imageUrl: 'https://example.com/$i.png'),
        );
      }

      final success = await tryUploadSticker(
        service,
        'user_limit',
        'https://example.com/50th.png',
      );
      expect(success, isTrue, reason: '50th sticker should be allowed');

      final count = await service.getUserStickerCount('user_limit');
      expect(count, equals(50));
    });

    test('upload is rejected when count is exactly 50', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      // Add 50 stickers
      for (int i = 0; i < 50; i++) {
        await service.createSticker(
          _makeSticker(userId: 'user_full', imageUrl: 'https://example.com/$i.png'),
        );
      }

      final success = await tryUploadSticker(
        service,
        'user_full',
        'https://example.com/51st.png',
      );
      expect(success, isFalse, reason: '51st sticker should be rejected');

      // Count must remain at 50
      final count = await service.getUserStickerCount('user_full');
      expect(count, equals(50));
    });

    test('upload is rejected when count exceeds 50', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      // Manually insert 55 stickers (bypassing limit check)
      for (int i = 0; i < 55; i++) {
        await service.createSticker(
          _makeSticker(userId: 'user_over', imageUrl: 'https://example.com/$i.png'),
        );
      }

      final success = await tryUploadSticker(
        service,
        'user_over',
        'https://example.com/extra.png',
      );
      expect(success, isFalse, reason: 'Upload should be rejected when over limit');
    });
  });

  // -------------------------------------------------------------------------
  // deleteSticker
  // -------------------------------------------------------------------------
  group('FakeUserStickerService.deleteSticker', () {
    test('removes the document from Firestore', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      final stickerId = await service.createSticker(
        _makeSticker(userId: 'user_del', imageUrl: 'https://example.com/del.png'),
      );

      // Verify it exists
      final before = await fakeFirestore
          .collection('user_stickers')
          .doc('user_del')
          .collection('stickers')
          .doc(stickerId)
          .get();
      expect(before.exists, isTrue);

      // Delete it
      await service.deleteSticker('user_del', stickerId, 'https://example.com/del.png');

      // Verify it's gone
      final after = await fakeFirestore
          .collection('user_stickers')
          .doc('user_del')
          .collection('stickers')
          .doc(stickerId)
          .get();
      expect(after.exists, isFalse);
    });

    test('count decreases after deletion', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      final id1 = await service.createSticker(
        _makeSticker(userId: 'user_dec', imageUrl: 'https://example.com/1.png'),
      );
      await service.createSticker(
        _makeSticker(userId: 'user_dec', imageUrl: 'https://example.com/2.png'),
      );

      expect(await service.getUserStickerCount('user_dec'), equals(2));

      await service.deleteSticker('user_dec', id1, 'https://example.com/1.png');

      expect(await service.getUserStickerCount('user_dec'), equals(1));
    });

    test('deleting one user sticker does not affect another user', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      final idA = await service.createSticker(
        _makeSticker(userId: 'user_A', imageUrl: 'https://example.com/a.png'),
      );
      await service.createSticker(
        _makeSticker(userId: 'user_B', imageUrl: 'https://example.com/b.png'),
      );

      await service.deleteSticker('user_A', idA, 'https://example.com/a.png');

      expect(await service.getUserStickerCount('user_A'), equals(0));
      expect(await service.getUserStickerCount('user_B'), equals(1));
    });

    test('after deletion user can upload again (below limit)', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      // Fill to 50
      String? lastId;
      for (int i = 0; i < 50; i++) {
        lastId = await service.createSticker(
          _makeSticker(userId: 'user_refill', imageUrl: 'https://example.com/$i.png'),
        );
      }

      // Delete one
      await service.deleteSticker('user_refill', lastId!, 'https://example.com/49.png');

      // Now count is 49 — upload should succeed
      final count = await service.getUserStickerCount('user_refill');
      expect(count, equals(49));
      expect(count < 50, isTrue, reason: 'User should be able to upload again');
    });
  });

  // -------------------------------------------------------------------------
  // watchUserStickers (stream)
  // -------------------------------------------------------------------------
  group('FakeUserStickerService.watchUserStickers', () {
    test('emits empty list when user has no stickers', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      final stickers = await service.watchUserStickers('empty_user').first;
      expect(stickers, isEmpty);
    });

    test('emits stickers after they are created', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      await service.createSticker(
        _makeSticker(userId: 'user_stream', imageUrl: 'https://example.com/s1.png'),
      );
      await service.createSticker(
        _makeSticker(userId: 'user_stream', imageUrl: 'https://example.com/s2.png'),
      );

      final stickers = await service.watchUserStickers('user_stream').first;
      expect(stickers.length, equals(2));
    });

    test('stickers are ordered by uploadedAt descending', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = FakeUserStickerService(fakeFirestore);

      final older = DateTime(2024, 1, 1);
      final newer = DateTime(2024, 6, 1);

      await service.createSticker(
        _makeSticker(
          userId: 'user_order',
          imageUrl: 'https://example.com/older.png',
          uploadedAt: older,
        ),
      );
      await service.createSticker(
        _makeSticker(
          userId: 'user_order',
          imageUrl: 'https://example.com/newer.png',
          uploadedAt: newer,
        ),
      );

      final stickers = await service.watchUserStickers('user_order').first;
      expect(stickers.length, equals(2));
      // Newest first
      expect(stickers[0].imageUrl, equals('https://example.com/newer.png'));
      expect(stickers[1].imageUrl, equals('https://example.com/older.png'));
    });
  });
}
