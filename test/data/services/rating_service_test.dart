// Tests para guardado de calificaciones individuales
// Task 23.5 – Calificaciones por Usuario
//
// Validates: Requirements 8.1, 8.2

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/rating.dart';

// ---------------------------------------------------------------------------
// Helpers – mirror RatingService.upsertMeetingRating logic
// ---------------------------------------------------------------------------

Future<void> _upsertMeetingRating(
  FakeFirebaseFirestore fs,
  String meetingId,
  Rating rating,
) async {
  await fs
      .collection('meetings')
      .doc(meetingId)
      .collection('ratings')
      .doc(rating.authorId)
      .set(rating.toMap());
}

Future<Map<String, dynamic>?> _getMeetingRatingDoc(
  FakeFirebaseFirestore fs,
  String meetingId,
  String authorId,
) async {
  final doc = await fs
      .collection('meetings')
      .doc(meetingId)
      .collection('ratings')
      .doc(authorId)
      .get();
  return doc.exists ? doc.data() : null;
}

// ---------------------------------------------------------------------------
// Unit tests – Rating model
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Rating.toMap()
  // -------------------------------------------------------------------------
  group('Rating.toMap()', () {
    test('incluye authorId y value', () {
      const rating = Rating(authorId: 'user_abc', value: 4);
      final map = rating.toMap();

      expect(map['authorId'], equals('user_abc'));
      expect(map['value'], equals(4));
    });

    test('incluye comment cuando es no-nulo y no-vacío', () {
      const rating = Rating(authorId: 'user_1', value: 3, comment: 'Muy buena reunión');
      final map = rating.toMap();

      expect(map.containsKey('comment'), isTrue);
      expect(map['comment'], equals('Muy buena reunión'));
    });

    test('no incluye comment cuando es null', () {
      const rating = Rating(authorId: 'user_2', value: 5);
      final map = rating.toMap();

      expect(map.containsKey('comment'), isFalse);
    });

    test('no incluye comment cuando es cadena vacía', () {
      const rating = Rating(authorId: 'user_3', value: 2, comment: '');
      final map = rating.toMap();

      expect(map.containsKey('comment'), isFalse);
    });

    test('incluye exactamente los campos correctos sin comment', () {
      const rating = Rating(authorId: 'user_4', value: 1);
      final map = rating.toMap();

      expect(map.keys.toSet(), equals({'authorId', 'value'}));
    });

    test('incluye exactamente los campos correctos con comment', () {
      const rating = Rating(authorId: 'user_5', value: 5, comment: 'Excelente');
      final map = rating.toMap();

      expect(map.keys.toSet(), equals({'authorId', 'value', 'comment'}));
    });
  });

  // -------------------------------------------------------------------------
  // Rating.fromMap()
  // -------------------------------------------------------------------------
  group('Rating.fromMap()', () {
    test('deserializa correctamente todos los campos incluyendo comment', () {
      final map = {'authorId': 'user_x', 'value': 3, 'comment': 'Buen libro'};
      final rating = Rating.fromMap(map, 'user_x');

      expect(rating.authorId, equals('user_x'));
      expect(rating.value, equals(3));
      expect(rating.comment, equals('Buen libro'));
    });

    test('maneja campo comment ausente (retorna null)', () {
      final map = {'authorId': 'user_y', 'value': 4};
      final rating = Rating.fromMap(map, 'user_y');

      expect(rating.authorId, equals('user_y'));
      expect(rating.value, equals(4));
      expect(rating.comment, isNull);
    });

    test('maneja comment explícitamente null', () {
      final map = <String, dynamic>{'authorId': 'user_z', 'value': 2, 'comment': null};
      final rating = Rating.fromMap(map, 'user_z');

      expect(rating.comment, isNull);
    });

    test('preserva todos los valores válidos de rating (1-5)', () {
      for (int v = 1; v <= 5; v++) {
        final map = {'authorId': 'author_$v', 'value': v};
        final rating = Rating.fromMap(map, 'author_$v');
        expect(rating.value, equals(v));
      }
    });
  });

  // -------------------------------------------------------------------------
  // RatingService.upsertMeetingRating – unit tests con fake Firestore
  // -------------------------------------------------------------------------
  group('RatingService.upsertMeetingRating', () {
    test('guarda authorId y value en la subcolección correcta', () async {
      final fs = FakeFirebaseFirestore();
      const rating = Rating(authorId: 'member_1', value: 4);

      await _upsertMeetingRating(fs, 'meeting_abc', rating);

      final data = await _getMeetingRatingDoc(fs, 'meeting_abc', 'member_1');
      expect(data, isNotNull);
      expect(data!['authorId'], equals('member_1'));
      expect(data['value'], equals(4));
    });

    test('guarda comment cuando está presente', () async {
      final fs = FakeFirebaseFirestore();
      const rating = Rating(authorId: 'member_2', value: 5, comment: 'Excelente sesión');

      await _upsertMeetingRating(fs, 'meeting_xyz', rating);

      final data = await _getMeetingRatingDoc(fs, 'meeting_xyz', 'member_2');
      expect(data!['comment'], equals('Excelente sesión'));
    });

    test('no guarda comment cuando es null', () async {
      final fs = FakeFirebaseFirestore();
      const rating = Rating(authorId: 'member_3', value: 3);

      await _upsertMeetingRating(fs, 'meeting_xyz', rating);

      final data = await _getMeetingRatingDoc(fs, 'meeting_xyz', 'member_3');
      expect(data!.containsKey('comment'), isFalse);
    });

    test('actualiza calificación existente (upsert)', () async {
      final fs = FakeFirebaseFirestore();
      const authorId = 'member_4';

      await _upsertMeetingRating(fs, 'meeting_1', const Rating(authorId: authorId, value: 2));
      await _upsertMeetingRating(fs, 'meeting_1', const Rating(authorId: authorId, value: 5));

      final data = await _getMeetingRatingDoc(fs, 'meeting_1', authorId);
      expect(data!['value'], equals(5));

      // Solo debe existir un documento
      final snapshot = await fs
          .collection('meetings')
          .doc('meeting_1')
          .collection('ratings')
          .get();
      expect(snapshot.docs.length, equals(1));
    });

    test('usa authorId como ID del documento', () async {
      final fs = FakeFirebaseFirestore();
      const rating = Rating(authorId: 'user_doc_id', value: 3);

      await _upsertMeetingRating(fs, 'meeting_2', rating);

      final doc = await fs
          .collection('meetings')
          .doc('meeting_2')
          .collection('ratings')
          .doc('user_doc_id')
          .get();
      expect(doc.exists, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Property-based tests con glados
  // -------------------------------------------------------------------------

  // PBT 1: Para cualquier valor válido (1-5) y cualquier authorId,
  // toMap() round-trips correctamente a través de fromMap()
  //
  // **Validates: Requirements 8.1, 8.2**
  group('PBT – Rating round-trip toMap/fromMap', () {
    final validValues = [1, 2, 3, 4, 5];
    final authorIds = [
      'user_1', 'user_2', 'user_abc', 'member_xyz', 'leader_001',
      'a', 'z', 'user_with_long_id_string_here', 'UID-123-456',
      'test@user', 'user.name', 'user_name_with_underscores',
      'UPPERCASE_USER', 'mixedCase123', 'user-with-dashes',
      'user_0', 'user_99', 'user_special_!', 'user_unicode_ñ',
      'short', 'another_member', 'club_leader', 'admin_user',
    ];

    test(
      'para cualquier valor válido (1-5) y authorId, toMap/fromMap preserva todos los campos',
      () {
        // Mínimo 100 iteraciones: 5 valores × 23 authorIds = 115
        var iterations = 0;
        for (final authorId in authorIds) {
          for (final value in validValues) {
            final original = Rating(authorId: authorId, value: value);
            final map = original.toMap();
            final restored = Rating.fromMap(map, authorId);

            expect(restored.authorId, equals(authorId),
                reason: 'authorId debe sobrevivir el round-trip para $authorId');
            expect(restored.value, equals(value),
                reason: 'value debe sobrevivir el round-trip para value=$value, authorId=$authorId');
            expect(restored.comment, isNull,
                reason: 'comment debe ser null cuando no se proporcionó');
            iterations++;
          }
        }
        expect(iterations, greaterThanOrEqualTo(100),
            reason: 'Debe ejecutar al menos 100 iteraciones');
      },
    );

    test(
      'round-trip preserva comment cuando está presente y no es vacío',
      () {
        final comments = [
          'Muy buena reunión',
          'Excelente discusión',
          'Me gustó mucho',
          'Podría mejorar',
          'Regular',
          'Comentario con caracteres especiales: ñ, á, é, ü',
          'A',
          'Comentario largo: ' + 'x' * 100,
          '123 números',
          'Emojis 🎉📚',
        ];

        var iterations = 0;
        for (final authorId in authorIds.take(10)) {
          for (final value in validValues) {
            for (final comment in comments) {
              final original = Rating(authorId: authorId, value: value, comment: comment);
              final map = original.toMap();
              final restored = Rating.fromMap(map, authorId);

              expect(restored.comment, equals(comment),
                  reason: 'comment "$comment" debe sobrevivir el round-trip');
              expect(restored.authorId, equals(authorId));
              expect(restored.value, equals(value));
              iterations++;
            }
          }
        }
        expect(iterations, greaterThanOrEqualTo(100));
      },
    );
  });

  // PBT 2: Para cualquier string de comment, toMap() solo incluye comment
  // cuando es no-vacío
  //
  // **Validates: Requirements 8.1, 8.2**
  group('PBT – toMap() solo incluye comment cuando es no-vacío', () {
    test(
      'para cualquier comment no-vacío, toMap() incluye el campo comment',
      () {
        final nonEmptyComments = [
          'a',
          'hola',
          ' ',
          '  espacios  ',
          'Comentario normal',
          '123',
          '!@#\$%',
          'ñoño',
          'línea\nnueva',
          'tab\there',
          'unicode: 中文',
          'emoji: 🌟',
          'muy largo: ' + 'a' * 200,
          'con "comillas"',
          "con 'apostrofes'",
          'con {llaves}',
          'con [corchetes]',
          'null_string',
          'true',
          'false',
          '0',
          '-1',
          '3.14',
        ];

        expect(nonEmptyComments.length, greaterThanOrEqualTo(20));

        for (final comment in nonEmptyComments) {
          final rating = Rating(authorId: 'user_test', value: 3, comment: comment);
          final map = rating.toMap();

          expect(map.containsKey('comment'), isTrue,
              reason: 'toMap() debe incluir comment para "$comment"');
          expect(map['comment'], equals(comment),
              reason: 'El valor del comment debe ser "$comment"');
        }
      },
    );

    test(
      'para comment vacío o null, toMap() no incluye el campo comment',
      () {
        // Caso null
        const ratingNull = Rating(authorId: 'user_test', value: 3);
        expect(ratingNull.toMap().containsKey('comment'), isFalse,
            reason: 'comment null no debe aparecer en toMap()');

        // Caso vacío
        const ratingEmpty = Rating(authorId: 'user_test', value: 3, comment: '');
        expect(ratingEmpty.toMap().containsKey('comment'), isFalse,
            reason: 'comment vacío no debe aparecer en toMap()');
      },
    );

    test(
      'propiedad se mantiene para todos los valores válidos (1-5) con comment no-vacío',
      () {
        final comments = List.generate(25, (i) => 'comment_$i');
        final values = [1, 2, 3, 4, 5];

        // 5 valores × 25 comments = 125 iteraciones
        var iterations = 0;
        for (final value in values) {
          for (final comment in comments) {
            final rating = Rating(authorId: 'author', value: value, comment: comment);
            final map = rating.toMap();

            expect(map.containsKey('comment'), isTrue,
                reason: 'comment "$comment" debe estar en toMap() para value=$value');
            iterations++;
          }
        }
        expect(iterations, greaterThanOrEqualTo(100));
      },
    );
  });
}
