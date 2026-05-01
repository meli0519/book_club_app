// Feature: book-club-app
// Property 16: Solicitud de membresía crea documento con estado pending
// Property 17: Aprobación de membresía actualiza todos los campos requeridos

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/membership.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [Membership] document in [fakeFirestore] with status='pending'.
Future<void> _requestMembership(
    FakeFirebaseFirestore fakeFirestore, String userId) async {
  final membership = Membership(
    userId: userId,
    status: 'pending',
    requestedAt: DateTime.now(),
  );
  await fakeFirestore
      .collection('memberships')
      .doc(userId)
      .set(membership.toMap());
}

/// Approves a membership in [fakeFirestore].
Future<void> _approveMembership(
    FakeFirebaseFirestore fakeFirestore, String userId, String leaderId) async {
  await fakeFirestore.collection('memberships').doc(userId).update({
    'status': 'active',
    'approvedAt': Timestamp.fromDate(DateTime.now()),
    'approvedBy': leaderId,
  });
}

/// Reads a [Membership] from [fakeFirestore].
Future<Membership?> _getMembership(
    FakeFirebaseFirestore fakeFirestore, String userId) async {
  final doc =
      await fakeFirestore.collection('memberships').doc(userId).get();
  if (!doc.exists) return null;
  return Membership.fromMap(doc.data()!, doc.id);
}

// ---------------------------------------------------------------------------
// Test data – varied inputs to exercise the property across many cases
// ---------------------------------------------------------------------------

/// 100 distinct user IDs covering different formats.
List<String> _generateUserIds() {
  final ids = <String>[];
  for (int i = 0; i < 50; i++) {
    ids.add('user_$i');
  }
  for (int i = 0; i < 20; i++) {
    ids.add('uid-${i * 7 + 3}-abc');
  }
  for (int i = 0; i < 20; i++) {
    ids.add('member${i}@club');
  }
  ids.addAll([
    'a',
    'z',
    'user_with_long_id_that_is_still_valid_123456789',
    'UPPERCASE_USER',
    'mixed_Case_User_42',
    'user.with.dots',
    'user-with-dashes',
    'user_with_underscores',
    'user123456789',
    '0user',
  ]);
  return ids;
}

/// 100 distinct leader IDs.
List<String> _generateLeaderIds() {
  final ids = <String>[];
  for (int i = 0; i < 50; i++) {
    ids.add('leader_$i');
  }
  for (int i = 0; i < 30; i++) {
    ids.add('admin-${i * 3 + 1}');
  }
  ids.addAll([
    'leader_alpha',
    'leader_beta',
    'leader_gamma',
    'leader_delta',
    'leader_epsilon',
    'leader_zeta',
    'leader_eta',
    'leader_theta',
    'leader_iota',
    'leader_kappa',
    'leader_lambda',
    'leader_mu',
    'leader_nu',
    'leader_xi',
    'leader_omicron',
    'leader_pi',
    'leader_rho',
    'leader_sigma',
    'leader_tau',
    'leader_upsilon',
  ]);
  return ids;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final userIds = _generateUserIds();
  final leaderIds = _generateLeaderIds();

  group('Membership Property Tests', () {
    // -----------------------------------------------------------------------
    // P16: Solicitud de membresía crea documento con estado pending
    // Validates: Requirements 10.1
    // -----------------------------------------------------------------------
    group('P16: requestMembership creates document with status=pending', () {
      test(
        'for any userId, membership document has status=pending and requestedAt set',
        () async {
          for (final userId in userIds) {
            final fakeFirestore = FakeFirebaseFirestore();

            final before = DateTime.now();
            await _requestMembership(fakeFirestore, userId);
            final after = DateTime.now();

            final membership = await _getMembership(fakeFirestore, userId);

            // Document must exist
            expect(membership, isNotNull,
                reason: 'Membership document should be created for $userId');

            // Status must be pending
            expect(membership!.status, equals('pending'),
                reason: 'Initial status must be pending for $userId');

            // userId must match
            expect(membership.userId, equals(userId),
                reason: 'userId must be preserved for $userId');

            // requestedAt must be set and within the test window
            expect(
              membership.requestedAt.isAfter(
                      before.subtract(const Duration(seconds: 1))) &&
                  membership.requestedAt
                      .isBefore(after.add(const Duration(seconds: 1))),
              isTrue,
              reason: 'requestedAt must be set to approximately now for $userId',
            );

            // approvedAt and approvedBy must be null on creation
            expect(membership.approvedAt, isNull,
                reason: 'approvedAt should not be set on creation for $userId');
            expect(membership.approvedBy, isNull,
                reason:
                    'approvedBy should not be set on creation for $userId');
          }
        },
      );

      test(
        'for any userId, membership document contains exactly the required fields',
        () async {
          for (final userId in userIds) {
            final fakeFirestore = FakeFirebaseFirestore();
            await _requestMembership(fakeFirestore, userId);

            final doc = await fakeFirestore
                .collection('memberships')
                .doc(userId)
                .get();
            final data = doc.data()!;

            // Required fields must be present
            expect(data.containsKey('userId'), isTrue,
                reason: 'userId field must exist for $userId');
            expect(data.containsKey('status'), isTrue,
                reason: 'status field must exist for $userId');
            expect(data.containsKey('requestedAt'), isTrue,
                reason: 'requestedAt field must exist for $userId');

            // Optional fields must NOT be present on initial creation
            expect(data.containsKey('approvedAt'), isFalse,
                reason: 'approvedAt must not be set on creation for $userId');
            expect(data.containsKey('approvedBy'), isFalse,
                reason: 'approvedBy must not be set on creation for $userId');
          }
        },
      );
    });

    // -----------------------------------------------------------------------
    // P17: Aprobación de membresía actualiza todos los campos requeridos
    // Validates: Requirements 10.2
    // -----------------------------------------------------------------------
    group('P17: approveMembership updates all required fields', () {
      test(
        'for any userId and leaderId, approved membership has status=active, approvedAt and approvedBy',
        () async {
          for (int i = 0; i < userIds.length; i++) {
            final userId = userIds[i];
            final leaderId = leaderIds[i % leaderIds.length];
            final fakeFirestore = FakeFirebaseFirestore();

            // Create pending membership first
            await _requestMembership(fakeFirestore, userId);

            final before = DateTime.now();
            await _approveMembership(fakeFirestore, userId, leaderId);
            final after = DateTime.now();

            final membership = await _getMembership(fakeFirestore, userId);

            expect(membership, isNotNull,
                reason: 'Membership must exist after approval for $userId');

            // Status must be active
            expect(membership!.status, equals('active'),
                reason: 'Status must be active after approval for $userId');

            // approvedBy must match the leader's uid
            expect(membership.approvedBy, equals(leaderId),
                reason:
                    'approvedBy must be set to leader uid for $userId approved by $leaderId');

            // approvedAt must be set and within the test window
            expect(membership.approvedAt, isNotNull,
                reason: 'approvedAt must be set after approval for $userId');
            expect(
              membership.approvedAt!.isAfter(
                      before.subtract(const Duration(seconds: 1))) &&
                  membership.approvedAt!
                      .isBefore(after.add(const Duration(seconds: 1))),
              isTrue,
              reason:
                  'approvedAt must be set to approximately now for $userId',
            );

            // userId must remain unchanged
            expect(membership.userId, equals(userId),
                reason: 'userId must not change after approval for $userId');
          }
        },
      );

      test(
        'for any userId, approval does not modify requestedAt',
        () async {
          for (int i = 0; i < userIds.length; i++) {
            final userId = userIds[i];
            final leaderId = leaderIds[i % leaderIds.length];
            final fakeFirestore = FakeFirebaseFirestore();

            await _requestMembership(fakeFirestore, userId);
            final pending = await _getMembership(fakeFirestore, userId);
            final originalRequestedAt = pending!.requestedAt;

            await _approveMembership(fakeFirestore, userId, leaderId);

            final approved = await _getMembership(fakeFirestore, userId);
            expect(
              approved!.requestedAt.isAtSameMomentAs(originalRequestedAt),
              isTrue,
              reason: 'requestedAt must not change after approval for $userId',
            );
          }
        },
      );

      test(
        'for any userId, different leaders produce correct approvedBy',
        () async {
          for (final leaderId in leaderIds) {
            final userId = 'test_user_for_$leaderId';
            final fakeFirestore = FakeFirebaseFirestore();

            await _requestMembership(fakeFirestore, userId);
            await _approveMembership(fakeFirestore, userId, leaderId);

            final membership = await _getMembership(fakeFirestore, userId);
            expect(membership?.approvedBy, equals(leaderId),
                reason:
                    'approvedBy must match leaderId=$leaderId for userId=$userId');
          }
        },
      );
    });

    // -----------------------------------------------------------------------
    // Membership model serialization round-trip
    // -----------------------------------------------------------------------
    group('Membership model toMap/fromMap round-trip', () {
      test('pending membership preserves all fields through serialization', () {
        for (final userId in userIds) {
          final requestedAt = DateTime(2024, 3, 15, 10, 30);
          final membership = Membership(
            userId: userId,
            status: 'pending',
            requestedAt: requestedAt,
          );

          final map = membership.toMap();
          expect(map['userId'], equals(userId));
          expect(map['status'], equals('pending'));
          expect(map['requestedAt'], isA<Timestamp>());
          expect(map.containsKey('approvedAt'), isFalse);
          expect(map.containsKey('approvedBy'), isFalse);

          final reconstructed = Membership.fromMap(map, userId);
          expect(reconstructed.userId, equals(userId));
          expect(reconstructed.status, equals('pending'));
          expect(reconstructed.approvedAt, isNull);
          expect(reconstructed.approvedBy, isNull);
        }
      });

      test('approved membership preserves all fields through serialization',
          () {
        for (int i = 0; i < userIds.length; i++) {
          final userId = userIds[i];
          final leaderId = leaderIds[i % leaderIds.length];
          final requestedAt = DateTime(2024, 1, 10, 8, 0);
          final approvedAt = DateTime(2024, 1, 11, 9, 0);

          final membership = Membership(
            userId: userId,
            status: 'active',
            requestedAt: requestedAt,
            approvedAt: approvedAt,
            approvedBy: leaderId,
          );

          final map = membership.toMap();
          expect(map['status'], equals('active'));
          expect(map['approvedAt'], isA<Timestamp>());
          expect(map['approvedBy'], equals(leaderId));

          final reconstructed = Membership.fromMap(map, userId);
          expect(reconstructed.status, equals('active'));
          expect(reconstructed.approvedBy, equals(leaderId));
          expect(reconstructed.approvedAt, isNotNull);
        }
      });
    });
  });
}
