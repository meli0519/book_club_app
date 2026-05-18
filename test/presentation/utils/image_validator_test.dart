// Tests for ImageValidator utility
// Validates: Requirements 2.3, 2.4, 7.2, 7.3, 7.4

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'package:book_club_app/presentation/utils/image_validator.dart';

// ---------------------------------------------------------------------------
// Helpers to create temporary image files for testing
// ---------------------------------------------------------------------------

/// Creates a temporary PNG file with the given [width] × [height] dimensions.
Future<File> _createPngFile({
  required int width,
  required int height,
  String suffix = '.png',
}) async {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 0, 0));
  final bytes = img.encodePng(image);
  final dir = Directory.systemTemp.createTempSync('img_validator_test_');
  final file = File(p.join(dir.path, 'test_image$suffix'));
  await file.writeAsBytes(bytes);
  return file;
}

/// Creates a temporary file with the given [bytes] content and [suffix].
Future<File> _createFileWithBytes(Uint8List bytes, String suffix) async {
  final dir = Directory.systemTemp.createTempSync('img_validator_test_');
  final file = File(p.join(dir.path, 'test_image$suffix'));
  await file.writeAsBytes(bytes);
  return file;
}

void main() {
  // -------------------------------------------------------------------------
  // validateImageFormat
  // -------------------------------------------------------------------------
  group('ImageValidator.validateImageFormat', () {
    test('accepts .png extension', () async {
      final file = await _createPngFile(width: 200, height: 200, suffix: '.png');
      expect(ImageValidator.validateImageFormat(file), isNull);
      await file.parent.delete(recursive: true);
    });

    test('accepts .jpg extension', () async {
      final file = await _createPngFile(width: 200, height: 200, suffix: '.jpg');
      expect(ImageValidator.validateImageFormat(file), isNull);
      await file.parent.delete(recursive: true);
    });

    test('accepts .jpeg extension', () async {
      final file = await _createPngFile(width: 200, height: 200, suffix: '.jpeg');
      expect(ImageValidator.validateImageFormat(file), isNull);
      await file.parent.delete(recursive: true);
    });

    test('accepts .webp extension', () async {
      final file = await _createPngFile(width: 200, height: 200, suffix: '.webp');
      expect(ImageValidator.validateImageFormat(file), isNull);
      await file.parent.delete(recursive: true);
    });

    test('rejects .gif extension', () async {
      final file = await _createPngFile(width: 200, height: 200, suffix: '.gif');
      final result = ImageValidator.validateImageFormat(file);
      expect(result, isNotNull);
      expect(result, contains('PNG'));
      await file.parent.delete(recursive: true);
    });

    test('rejects .bmp extension', () async {
      final file = await _createPngFile(width: 200, height: 200, suffix: '.bmp');
      final result = ImageValidator.validateImageFormat(file);
      expect(result, isNotNull);
      await file.parent.delete(recursive: true);
    });

    test('rejects .svg extension', () async {
      final file = await _createPngFile(width: 200, height: 200, suffix: '.svg');
      final result = ImageValidator.validateImageFormat(file);
      expect(result, isNotNull);
      await file.parent.delete(recursive: true);
    });

    test('rejects .txt extension', () async {
      final file = await _createPngFile(width: 200, height: 200, suffix: '.txt');
      final result = ImageValidator.validateImageFormat(file);
      expect(result, isNotNull);
      await file.parent.delete(recursive: true);
    });

    test('is case-insensitive for extensions', () async {
      // The validator uses .toLowerCase() so .PNG should also be accepted
      final file = await _createPngFile(width: 200, height: 200, suffix: '.PNG');
      expect(ImageValidator.validateImageFormat(file), isNull);
      await file.parent.delete(recursive: true);
    });
  });

  // -------------------------------------------------------------------------
  // validateImageSize
  // -------------------------------------------------------------------------
  group('ImageValidator.validateImageSize', () {
    test('accepts file exactly at 2MB limit', () async {
      // 2 * 1024 * 1024 = 2097152 bytes
      final bytes = Uint8List(2 * 1024 * 1024);
      final file = await _createFileWithBytes(bytes, '.png');
      final result = await ImageValidator.validateImageSize(file);
      expect(result, isNull, reason: 'File at exactly 2MB should be accepted');
      await file.parent.delete(recursive: true);
    });

    test('accepts file smaller than 2MB', () async {
      final bytes = Uint8List(1 * 1024 * 1024); // 1MB
      final file = await _createFileWithBytes(bytes, '.png');
      final result = await ImageValidator.validateImageSize(file);
      expect(result, isNull, reason: '1MB file should be accepted');
      await file.parent.delete(recursive: true);
    });

    test('accepts very small file', () async {
      final bytes = Uint8List(100); // 100 bytes
      final file = await _createFileWithBytes(bytes, '.png');
      final result = await ImageValidator.validateImageSize(file);
      expect(result, isNull, reason: 'Tiny file should be accepted');
      await file.parent.delete(recursive: true);
    });

    test('rejects file larger than 2MB', () async {
      final bytes = Uint8List(2 * 1024 * 1024 + 1); // 1 byte over limit
      final file = await _createFileWithBytes(bytes, '.png');
      final result = await ImageValidator.validateImageSize(file);
      expect(result, isNotNull, reason: 'File over 2MB should be rejected');
      expect(result, contains('2MB'));
      await file.parent.delete(recursive: true);
    });

    test('rejects file of 3MB', () async {
      final bytes = Uint8List(3 * 1024 * 1024);
      final file = await _createFileWithBytes(bytes, '.png');
      final result = await ImageValidator.validateImageSize(file);
      expect(result, isNotNull, reason: '3MB file should be rejected');
      await file.parent.delete(recursive: true);
    });

    test('rejects file of 10MB', () async {
      final bytes = Uint8List(10 * 1024 * 1024);
      final file = await _createFileWithBytes(bytes, '.png');
      final result = await ImageValidator.validateImageSize(file);
      expect(result, isNotNull, reason: '10MB file should be rejected');
      await file.parent.delete(recursive: true);
    });
  });

  // -------------------------------------------------------------------------
  // validateImageDimensions
  // -------------------------------------------------------------------------
  group('ImageValidator.validateImageDimensions', () {
    test('accepts 100×100 (minimum valid dimensions)', () async {
      final file = await _createPngFile(width: 100, height: 100);
      final result = await ImageValidator.validateImageDimensions(file);
      expect(result, isNull, reason: '100×100 should be accepted');
      await file.parent.delete(recursive: true);
    });

    test('accepts 1024×1024 (maximum valid dimensions)', () async {
      final file = await _createPngFile(width: 1024, height: 1024);
      final result = await ImageValidator.validateImageDimensions(file);
      expect(result, isNull, reason: '1024×1024 should be accepted');
      await file.parent.delete(recursive: true);
    });

    test('accepts 512×512 (mid-range dimensions)', () async {
      final file = await _createPngFile(width: 512, height: 512);
      final result = await ImageValidator.validateImageDimensions(file);
      expect(result, isNull, reason: '512×512 should be accepted');
      await file.parent.delete(recursive: true);
    });

    test('accepts non-square 200×300', () async {
      final file = await _createPngFile(width: 200, height: 300);
      final result = await ImageValidator.validateImageDimensions(file);
      expect(result, isNull, reason: '200×300 should be accepted');
      await file.parent.delete(recursive: true);
    });

    test('rejects 99×100 (width below minimum)', () async {
      final file = await _createPngFile(width: 99, height: 100);
      final result = await ImageValidator.validateImageDimensions(file);
      expect(result, isNotNull, reason: '99×100 should be rejected');
      await file.parent.delete(recursive: true);
    });

    test('rejects 100×99 (height below minimum)', () async {
      final file = await _createPngFile(width: 100, height: 99);
      final result = await ImageValidator.validateImageDimensions(file);
      expect(result, isNotNull, reason: '100×99 should be rejected');
      await file.parent.delete(recursive: true);
    });

    test('rejects 50×50 (too small)', () async {
      final file = await _createPngFile(width: 50, height: 50);
      final result = await ImageValidator.validateImageDimensions(file);
      expect(result, isNotNull, reason: '50×50 should be rejected');
      await file.parent.delete(recursive: true);
    });

    test('rejects 1025×1024 (width above maximum)', () async {
      final file = await _createPngFile(width: 1025, height: 1024);
      final result = await ImageValidator.validateImageDimensions(file);
      expect(result, isNotNull, reason: '1025×1024 should be rejected');
      await file.parent.delete(recursive: true);
    });

    test('rejects 1024×1025 (height above maximum)', () async {
      final file = await _createPngFile(width: 1024, height: 1025);
      final result = await ImageValidator.validateImageDimensions(file);
      expect(result, isNotNull, reason: '1024×1025 should be rejected');
      await file.parent.delete(recursive: true);
    });

    test('rejects 2000×2000 (too large)', () async {
      final file = await _createPngFile(width: 2000, height: 2000);
      final result = await ImageValidator.validateImageDimensions(file);
      expect(result, isNotNull, reason: '2000×2000 should be rejected');
      await file.parent.delete(recursive: true);
    });

    test('error message mentions dimension range', () async {
      final file = await _createPngFile(width: 50, height: 50);
      final result = await ImageValidator.validateImageDimensions(file);
      expect(result, isNotNull);
      expect(result, contains('100'));
      expect(result, contains('1024'));
      await file.parent.delete(recursive: true);
    });
  });

  // -------------------------------------------------------------------------
  // validateImage (combined)
  // -------------------------------------------------------------------------
  group('ImageValidator.validateImage (combined)', () {
    test('returns null for a valid 200×200 PNG under 2MB', () async {
      final file = await _createPngFile(width: 200, height: 200, suffix: '.png');
      final result = await ImageValidator.validateImage(file);
      expect(result, isNull);
      await file.parent.delete(recursive: true);
    });

    test('returns format error first when format is invalid', () async {
      final file = await _createPngFile(width: 200, height: 200, suffix: '.gif');
      final result = await ImageValidator.validateImage(file);
      expect(result, isNotNull);
      // Format is checked first
      expect(result, contains('PNG'));
      await file.parent.delete(recursive: true);
    });
  });

  // -------------------------------------------------------------------------
  // Constants
  // -------------------------------------------------------------------------
  group('ImageValidator constants', () {
    test('maxSizeBytes is 2MB', () {
      expect(ImageValidator.maxSizeBytes, equals(2 * 1024 * 1024));
    });

    test('minDimension is 100', () {
      expect(ImageValidator.minDimension, equals(100));
    });

    test('maxDimension is 1024', () {
      expect(ImageValidator.maxDimension, equals(1024));
    });

    test('allowedExtensions contains png, jpg, jpeg, webp', () {
      expect(ImageValidator.allowedExtensions, contains('.png'));
      expect(ImageValidator.allowedExtensions, contains('.jpg'));
      expect(ImageValidator.allowedExtensions, contains('.jpeg'));
      expect(ImageValidator.allowedExtensions, contains('.webp'));
    });
  });
}
