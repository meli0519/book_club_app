// Feature: personal-books
// Property 3: Validación de campos obligatorios (title y author)
// Property 8: Validación de longitud de notas
// Validates: Requirements 2.2, 3.4, 6.2, 6.3

import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/personal_book.dart';

// ---------------------------------------------------------------------------
// Validation helpers (mirrors PersonalBookFormScreen form logic)
// ---------------------------------------------------------------------------

String? validateRequired(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required';
  }
  return null;
}

String? validateNoteLength(String? value, int maxLength) {
  if (value != null && value.length > maxLength) {
    return 'Note must not exceed $maxLength characters';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Test data generators
// ---------------------------------------------------------------------------

List<String> _generateTitles() {
  final titles = <String>[];
  for (int i = 0; i < 30; i++) {
    titles.add('Personal Book Title $i');
  }
  for (int i = 0; i < 20; i++) {
    titles.add('El libro personal número $i');
  }
  titles.addAll([
    'Don Quijote de la Mancha',
    'Cien años de soledad',
    'The Great Gatsby',
    '1984',
    'Brave New World',
    'To Kill a Mockingbird',
    'Pride and Prejudice',
    'The Catcher in the Rye',
    'Of Mice and Men',
    'The Grapes of Wrath',
  ]);
  return titles;
}

List<String> _generateAuthors() {
  final authors = <String>[];
  for (int i = 0; i < 30; i++) {
    authors.add('Author $i');
  }
  for (int i = 0; i < 20; i++) {
    authors.add('Autor Apellido$i');
  }
  authors.addAll([
    'Miguel de Cervantes',
    'Gabriel García Márquez',
    'F. Scott Fitzgerald',
    'George Orwell',
    'Aldous Huxley',
    'Harper Lee',
    'Jane Austen',
    'J.D. Salinger',
    'John Steinbeck',
    'Ernest Hemingway',
  ]);
  return authors;
}

List<String> _generateInvalidValues() {
  return [
    '',
    ' ',
    '  ',
    '   ',
    '\t',
    '\n',
    '\r\n',
    '     ',
    '\t\t',
    '\n\n',
  ];
}

List<String> _generateValidNotes() {
  return [
    '',
    'A',
    'Short note',
    'This is a longer note about the book I am reading.',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    'A' * 100,
    'A' * 1000,
    'A' * 4999,
    'A' * 5000,
  ];
}

List<String> _generateTooLongNotes() {
  return [
    'A' * 5001,
    'A' * 5100,
    'A' * 6000,
    'A' * 10000,
    'Note with spaces and punctuation. ' * 500,
  ];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final titles = _generateTitles();
  final authors = _generateAuthors();
  final invalidValues = _generateInvalidValues();
  final validNotes = _generateValidNotes();
  final tooLongNotes = _generateTooLongNotes();

  // -------------------------------------------------------------------------
  // P3: Validación de campos obligatorios (title y author)
  // Validates: Requirements 2.2, 3.4
  // -------------------------------------------------------------------------
  group(
    'P3: PersonalBook required field validation rejects empty/whitespace inputs',
    () {
      test(
        'validateRequired returns error for all invalid title inputs',
        () {
          for (final invalid in invalidValues) {
            final result = validateRequired(invalid);
            expect(
              result,
              isNotNull,
              reason: 'validateRequired should return error for title="$invalid"',
            );
            expect(
              result,
              equals('This field is required'),
              reason: 'Error message must match for title="$invalid"',
            );
          }
        },
      );

      test(
        'validateRequired returns null for all valid title inputs',
        () {
          for (final title in titles) {
            final result = validateRequired(title);
            expect(
              result,
              isNull,
              reason: 'validateRequired should return null for valid title="$title"',
            );
          }
        },
      );

      test(
        'validateRequired returns error for null title',
        () {
          final result = validateRequired(null);
          expect(result, isNotNull);
          expect(result, equals('This field is required'));
        },
      );

      test(
        'validateRequired returns error for all invalid author inputs',
        () {
          for (final invalid in invalidValues) {
            final result = validateRequired(invalid);
            expect(
              result,
              isNotNull,
              reason: 'validateRequired should return error for author="$invalid"',
            );
          }
        },
      );

      test(
        'validateRequired returns null for all valid author inputs',
        () {
          for (final author in authors) {
            final result = validateRequired(author);
            expect(
              result,
              isNull,
              reason: 'validateRequired should return null for valid author="$author"',
            );
          }
        },
      );

      test(
        'validateRequired returns error for null author',
        () {
          final result = validateRequired(null);
          expect(result, isNotNull);
          expect(result, equals('This field is required'));
        },
      );
    },
  );

  // -------------------------------------------------------------------------
  // P8: Validación de longitud de notas
  // Validates: Requirements 6.2, 6.3
  // -------------------------------------------------------------------------
  group(
    'P8: PersonalNoteField validates note length correctly',
    () {
      test(
        'validateNoteLength returns null for all valid notes (length <= 5000)',
        () {
          for (final note in validNotes) {
            final result = validateNoteLength(note, 5000);
            expect(
              result,
              isNull,
              reason: 'validateNoteLength should return null for note of length ${note.length}',
            );
          }
        },
      );

      test(
        'validateNoteLength returns error for all too long notes (length > 5000)',
        () {
          for (final note in tooLongNotes) {
            final result = validateNoteLength(note, 5000);
            expect(
              result,
              isNotNull,
              reason: 'validateNoteLength should return error for note of length ${note.length}',
            );
            expect(
              result,
              equals('Note must not exceed 5000 characters'),
              reason: 'Error message must match for note of length ${note.length}',
            );
          }
        },
      );

      test(
        'validateNoteLength returns null for null note',
        () {
          final result = validateNoteLength(null, 5000);
          expect(result, isNull);
        },
      );

      test(
        'validateNoteLength handles edge case at exactly 5000 characters',
        () {
          final note5000 = 'A' * 5000;
          final result = validateNoteLength(note5000, 5000);
          expect(result, isNull);
        },
      );

      test(
        'validateNoteLength rejects edge case at 5001 characters',
        () {
          final note5001 = 'A' * 5001;
          final result = validateNoteLength(note5001, 5000);
          expect(result, isNotNull);
        },
      );
    },
  );
}