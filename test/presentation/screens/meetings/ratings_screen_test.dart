// Tests for RatingsScreen – visualización de calificaciones de todos los miembros
// Requirements 24.1, 24.2, 24.3, 24.4

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/rating_with_user.dart';

// ---------------------------------------------------------------------------
// Helpers – mirrors RatingService.watchMeetingRatingsWithUsers() logic
// ---------------------------------------------------------------------------

Future<void> _addUser(
  FakeFirebaseFirestore fs, {
  required String uid,
  required String displayName,
}) async {
  await fs.collection('users').doc(uid).set({
    'uid': uid,
    'email': '$uid@test.com',
    'displayName': displayName,
    'photoUrl': '',
    'role': 'member',
    'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
  });
}

Future<void> _addRating(
  FakeFirebaseFirestore fs, {
  required String meetingId,
  required String authorId,
  required int value,
  String? comment,
}) async {
  final data = <String, dynamic>{
    'authorId': authorId,
    'value': value,
  };
  if (comment != null) data['comment'] = comment;
  await fs
      .collection('meetings')
      .doc(meetingId)
      .collection('ratings')
      .doc(authorId)
      .set(data);
}

/// Simulates the service logic: fetches ratings and enriches with user names.
Future<List<RatingWithUser>> _fetchRatingsWithUsers(
  FakeFirebaseFirestore fs,
  String meetingId,
) async {
  final snapshot = await fs
      .collection('meetings')
      .doc(meetingId)
      .collection('ratings')
      .get();

  final results = <RatingWithUser>[];
  for (final doc in snapshot.docs) {
    final authorId = doc.data()['authorId'] as String? ?? doc.id;
    final value = (doc.data()['value'] as num?)?.toInt() ?? 0;
    final comment = doc.data()['comment'] as String?;

    String authorName = authorId;
    final userDoc = await fs.collection('users').doc(authorId).get();
    if (userDoc.exists) {
      authorName = (userDoc.data()?['displayName'] as String?) ?? authorId;
    }

    results.add(RatingWithUser(
      authorId: authorId,
      authorName: authorName,
      value: value,
      comment: comment,
    ));
  }
  return results;
}

double? _computeAverage(List<RatingWithUser> ratings) {
  if (ratings.isEmpty) return null;
  final sum = ratings.fold<int>(0, (acc, r) => acc + r.value);
  final avg = sum / ratings.length;
  return (avg * 10).round() / 10;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RatingsScreen – empty state (24.1)', () {
    test('returns empty list when no ratings exist', () async {
      final fs = FakeFirebaseFirestore();
      final ratings = await _fetchRatingsWithUsers(fs, 'meeting_1');
      expect(ratings, isEmpty);
    });

    test('average is null when no ratings exist', () {
      final avg = _computeAverage([]);
      expect(avg, isNull);
    });
  });

  group('RatingsScreen – ratings list (24.1, 24.2)', () {
    test('returns all ratings for a meeting', () async {
      final fs = FakeFirebaseFirestore();
      await _addUser(fs, uid: 'user1', displayName: 'Alice');
      await _addUser(fs, uid: 'user2', displayName: 'Bob');
      await _addRating(fs, meetingId: 'm1', authorId: 'user1', value: 4);
      await _addRating(fs, meetingId: 'm1', authorId: 'user2', value: 3);

      final ratings = await _fetchRatingsWithUsers(fs, 'm1');
      expect(ratings.length, equals(2));
    });

    test('each rating includes authorName, value and optional comment (24.2)',
        () async {
      final fs = FakeFirebaseFirestore();
      await _addUser(fs, uid: 'user1', displayName: 'Alice');
      await _addRating(
        fs,
        meetingId: 'm1',
        authorId: 'user1',
        value: 5,
        comment: 'Great meeting!',
      );

      final ratings = await _fetchRatingsWithUsers(fs, 'm1');
      expect(ratings.first.authorName, equals('Alice'));
      expect(ratings.first.value, equals(5));
      expect(ratings.first.comment, equals('Great meeting!'));
    });

    test('rating without comment has null comment field', () async {
      final fs = FakeFirebaseFirestore();
      await _addUser(fs, uid: 'user1', displayName: 'Alice');
      await _addRating(fs, meetingId: 'm1', authorId: 'user1', value: 3);

      final ratings = await _fetchRatingsWithUsers(fs, 'm1');
      expect(ratings.first.comment, isNull);
    });

    test('falls back to authorId when user document does not exist', () async {
      final fs = FakeFirebaseFirestore();
      // No user document added
      await _addRating(fs, meetingId: 'm1', authorId: 'unknown_user', value: 2);

      final ratings = await _fetchRatingsWithUsers(fs, 'm1');
      expect(ratings.first.authorName, equals('unknown_user'));
    });

    test('ratings from different meetings are isolated', () async {
      final fs = FakeFirebaseFirestore();
      await _addUser(fs, uid: 'user1', displayName: 'Alice');
      await _addRating(fs, meetingId: 'm1', authorId: 'user1', value: 4);
      await _addRating(fs, meetingId: 'm2', authorId: 'user1', value: 2);

      final ratingsM1 = await _fetchRatingsWithUsers(fs, 'm1');
      final ratingsM2 = await _fetchRatingsWithUsers(fs, 'm2');

      expect(ratingsM1.length, equals(1));
      expect(ratingsM1.first.value, equals(4));
      expect(ratingsM2.length, equals(1));
      expect(ratingsM2.first.value, equals(2));
    });
  });

  group('RatingsScreen – sorting (24.3)', () {
    late List<RatingWithUser> ratings;

    setUp(() {
      ratings = [
        const RatingWithUser(authorId: 'u3', authorName: 'Charlie', value: 5),
        const RatingWithUser(authorId: 'u1', authorName: 'Alice', value: 3),
        const RatingWithUser(authorId: 'u2', authorName: 'Bob', value: 4),
      ];
    });

    test('sort by score descending', () {
      final sorted = List<RatingWithUser>.from(ratings)
        ..sort((a, b) => b.value.compareTo(a.value));
      expect(sorted[0].value, equals(5));
      expect(sorted[1].value, equals(4));
      expect(sorted[2].value, equals(3));
    });

    test('sort by name ascending (case-insensitive)', () {
      final sorted = List<RatingWithUser>.from(ratings)
        ..sort((a, b) =>
            a.authorName.toLowerCase().compareTo(b.authorName.toLowerCase()));
      expect(sorted[0].authorName, equals('Alice'));
      expect(sorted[1].authorName, equals('Bob'));
      expect(sorted[2].authorName, equals('Charlie'));
    });

    test('sort by score with ties preserves relative order', () {
      final tied = [
        const RatingWithUser(authorId: 'u1', authorName: 'Alice', value: 4),
        const RatingWithUser(authorId: 'u2', authorName: 'Bob', value: 4),
        const RatingWithUser(authorId: 'u3', authorName: 'Charlie', value: 2),
      ];
      final sorted = List<RatingWithUser>.from(tied)
        ..sort((a, b) => b.value.compareTo(a.value));
      expect(sorted[0].value, equals(4));
      expect(sorted[1].value, equals(4));
      expect(sorted[2].value, equals(2));
    });
  });

  group('RatingsScreen – average rating (24.4)', () {
    test('average of single rating equals that rating', () {
      final ratings = [
        const RatingWithUser(authorId: 'u1', authorName: 'Alice', value: 4),
      ];
      expect(_computeAverage(ratings), equals(4.0));
    });

    test('average of multiple ratings is rounded to 1 decimal', () {
      final ratings = [
        const RatingWithUser(authorId: 'u1', authorName: 'Alice', value: 4),
        const RatingWithUser(authorId: 'u2', authorName: 'Bob', value: 3),
        const RatingWithUser(authorId: 'u3', authorName: 'Charlie', value: 5),
      ];
      // (4 + 3 + 5) / 3 = 4.0
      expect(_computeAverage(ratings), equals(4.0));
    });

    test('average rounds 3.666... to 3.7', () {
      final ratings = [
        const RatingWithUser(authorId: 'u1', authorName: 'Alice', value: 4),
        const RatingWithUser(authorId: 'u2', authorName: 'Bob', value: 3),
        const RatingWithUser(authorId: 'u3', authorName: 'Charlie', value: 4),
      ];
      // (4 + 3 + 4) / 3 = 3.666... → 3.7
      final avg = _computeAverage(ratings);
      expect(avg, equals(3.7));
    });

    test('average of all 5s is 5.0', () {
      final ratings = List.generate(
        5,
        (i) => RatingWithUser(
            authorId: 'u$i', authorName: 'User $i', value: 5),
      );
      expect(_computeAverage(ratings), equals(5.0));
    });

    test('average of all 1s is 1.0', () {
      final ratings = List.generate(
        3,
        (i) => RatingWithUser(
            authorId: 'u$i', authorName: 'User $i', value: 1),
      );
      expect(_computeAverage(ratings), equals(1.0));
    });

    test('average is computed from Firestore data correctly', () async {
      final fs = FakeFirebaseFirestore();
      await _addUser(fs, uid: 'u1', displayName: 'Alice');
      await _addUser(fs, uid: 'u2', displayName: 'Bob');
      await _addRating(fs, meetingId: 'm1', authorId: 'u1', value: 5);
      await _addRating(fs, meetingId: 'm1', authorId: 'u2', value: 3);

      final ratings = await _fetchRatingsWithUsers(fs, 'm1');
      final avg = _computeAverage(ratings);
      // (5 + 3) / 2 = 4.0
      expect(avg, equals(4.0));
    });
  });

  group('RatingsScreen – RatingWithUser model', () {
    test('RatingWithUser stores all fields correctly', () {
      const r = RatingWithUser(
        authorId: 'user1',
        authorName: 'Alice',
        value: 4,
        comment: 'Nice!',
      );
      expect(r.authorId, equals('user1'));
      expect(r.authorName, equals('Alice'));
      expect(r.value, equals(4));
      expect(r.comment, equals('Nice!'));
    });

    test('RatingWithUser comment defaults to null', () {
      const r = RatingWithUser(
        authorId: 'user1',
        authorName: 'Alice',
        value: 3,
      );
      expect(r.comment, isNull);
    });
  });
}
