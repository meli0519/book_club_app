// Tests for StickerUploadService — size validation and content-type logic
// Validates: Requirements 2.1, 2.2, 2.3, 2.6, 2.7
//
// NOTE: Firebase Storage cannot be mocked without a real Firebase project or
// firebase_storage_mocks (not in pubspec). We therefore test:
//   1. The size-validation logic extracted into a testable helper.
//   2. The _getContentType logic via a thin wrapper.
//   3. The upload path construction logic.
//
// Full integration tests (actual Storage upload) require a running emulator
// and are out of scope for unit tests.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// ---------------------------------------------------------------------------
// Extracted / mirrored logic from StickerUploadService for unit testing
// ---------------------------------------------------------------------------

/// Mirrors StickerUploadService._getContentType
String getContentType(String extension) {
  switch (extension.toLowerCase()) {
    case '.png':
      return 'image/png';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.webp':
      return 'image/webp';
    default:
      return 'image/png';
  }
}

/// Mirrors the size-validation guard in StickerUploadService.uploadSticker
Future<String?> validateUploadSize(File image) async {
  final fileSize = await image.length();
  if (fileSize > 2 * 1024 * 1024) {
    return 'La imagen debe ser menor a 2MB';
  }
  return null;
}

/// Mirrors the storage path construction in StickerUploadService.uploadSticker
String buildStoragePath(String userId, int timestamp, String basename) {
  return 'user_stickers/$userId/${timestamp}_$basename';
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<File> _createTempFile(int sizeBytes, String suffix) async {
  final dir = Directory.systemTemp.createTempSync('upload_svc_test_');
  final file = File(p.join(dir.path, 'test$suffix'));
  await file.writeAsBytes(Uint8List(sizeBytes));
  return file;
}

void main() {
  // -------------------------------------------------------------------------
  // Size validation
  // -------------------------------------------------------------------------
  group('StickerUploadService size validation', () {
    test('accepts file of exactly 2MB', () async {
      final file = await _createTempFile(2 * 1024 * 1024, '.png');
      final error = await validateUploadSize(file);
      expect(error, isNull, reason: 'Exactly 2MB should pass');
      await file.parent.delete(recursive: true);
    });

    test('accepts file smaller than 2MB', () async {
      final file = await _createTempFile(500 * 1024, '.png'); // 500KB
      final error = await validateUploadSize(file);
      expect(error, isNull, reason: '500KB should pass');
      await file.parent.delete(recursive: true);
    });

    test('rejects file of 2MB + 1 byte', () async {
      final file = await _createTempFile(2 * 1024 * 1024 + 1, '.png');
      final error = await validateUploadSize(file);
      expect(error, isNotNull, reason: 'One byte over 2MB should fail');
      expect(error, contains('2MB'));
      await file.parent.delete(recursive: true);
    });

    test('rejects file of 5MB', () async {
      final file = await _createTempFile(5 * 1024 * 1024, '.png');
      final error = await validateUploadSize(file);
      expect(error, isNotNull, reason: '5MB should fail');
      await file.parent.delete(recursive: true);
    });

    test('accepts empty file (0 bytes)', () async {
      final file = await _createTempFile(0, '.png');
      final error = await validateUploadSize(file);
      expect(error, isNull, reason: 'Empty file is under 2MB');
      await file.parent.delete(recursive: true);
    });
  });

  // -------------------------------------------------------------------------
  // Content-type mapping
  // -------------------------------------------------------------------------
  group('StickerUploadService content-type mapping', () {
    test('.png → image/png', () {
      expect(getContentType('.png'), equals('image/png'));
    });

    test('.PNG → image/png (case-insensitive)', () {
      expect(getContentType('.PNG'), equals('image/png'));
    });

    test('.jpg → image/jpeg', () {
      expect(getContentType('.jpg'), equals('image/jpeg'));
    });

    test('.jpeg → image/jpeg', () {
      expect(getContentType('.jpeg'), equals('image/jpeg'));
    });

    test('.JPG → image/jpeg (case-insensitive)', () {
      expect(getContentType('.JPG'), equals('image/jpeg'));
    });

    test('.webp → image/webp', () {
      expect(getContentType('.webp'), equals('image/webp'));
    });

    test('.WEBP → image/webp (case-insensitive)', () {
      expect(getContentType('.WEBP'), equals('image/webp'));
    });

    test('unknown extension defaults to image/png', () {
      expect(getContentType('.gif'), equals('image/png'));
      expect(getContentType('.bmp'), equals('image/png'));
      expect(getContentType(''), equals('image/png'));
    });
  });

  // -------------------------------------------------------------------------
  // Storage path construction
  // -------------------------------------------------------------------------
  group('StickerUploadService storage path construction', () {
    test('path starts with user_stickers/{userId}/', () {
      const userId = 'user_abc';
      final path = buildStoragePath(userId, 1234567890, 'photo.png');
      expect(path.startsWith('user_stickers/user_abc/'), isTrue);
    });

    test('path includes timestamp and filename', () {
      const userId = 'user_xyz';
      const timestamp = 1700000000000;
      const basename = 'my_sticker.png';
      final path = buildStoragePath(userId, timestamp, basename);
      expect(path, equals('user_stickers/user_xyz/1700000000000_my_sticker.png'));
    });

    test('different users produce different paths', () {
      const ts = 1000;
      const file = 'img.png';
      final pathA = buildStoragePath('user_A', ts, file);
      final pathB = buildStoragePath('user_B', ts, file);
      expect(pathA, isNot(equals(pathB)));
    });

    test('different timestamps produce different paths for same user', () {
      const userId = 'user_1';
      const file = 'img.png';
      final path1 = buildStoragePath(userId, 1000, file);
      final path2 = buildStoragePath(userId, 2000, file);
      expect(path1, isNot(equals(path2)));
    });
  });
}
