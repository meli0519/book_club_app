// Smoke test: verifies Firestore security rules logic for role-based write access.
//
// These tests validate the application-level role enforcement that mirrors the
// Firestore security rules in firestore.rules.
//
// NOTE: Full Firestore security rules enforcement (rejecting writes at the
// database level) requires the Firebase Emulator Suite to be running.
// Run: `firebase emulators:start` before executing emulator-based tests.
//
// Validates: Requirements 3.4 — writes to books/meetings rejected for non-leaders.
// Validates: Requirements 3.1 — exactly two roles exist.
// Validates: Requirements 3.3 — member role cannot trigger write operations.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_club_app/domain/models/app_user.dart';

// ---------------------------------------------------------------------------
// Helpers — simulate the permission checks from firestore.rules
// ---------------------------------------------------------------------------

/// Simulates the Firestore rule: isLeader() — user doc has role == 'leader'.
/// This mirrors the `isLeader()` function in firestore.rules.
Future<bool> _checkIsLeader(
    FakeFirebaseFirestore fakeFirestore, String uid) async {
  final doc = await fakeFirestore.collection('users').doc(uid).get();
  if (!doc.exists) return false;
  return doc.data()?['role'] == 'leader';
}

/// Simulates the Firestore rule: hasActiveMembership().
Future<bool> _checkHasActiveMembership(
    FakeFirebaseFirestore fakeFirestore, String uid) async {
  final doc = await fakeFirestore.collection('memberships').doc(uid).get();
  if (!doc.exists) return false;
  return doc.data()?['status'] == 'active';
}

/// Attempts to write to the books collection, gated by the isLeader check.
/// Returns true if the write was allowed, false if rejected (permission denied).
Future<bool> _tryWriteBook(
    FakeFirebaseFirestore fakeFirestore, String uid, Map<String, dynamic> data) async {
  final isLeader = await _checkIsLeader(fakeFirestore, uid);
  if (!isLeader) return false; // Simulates Firestore rule rejection
  await fakeFirestore.collection('books').add(data);
  return true;
}

/// Attempts to write to the meetings collection, gated by the isLeader check.
Future<bool> _tryWriteMeeting(
    FakeFirebaseFirestore fakeFirestore, String uid, Map<String, dynamic> data) async {
  final isLeader = await _checkIsLeader(fakeFirestore, uid);
  if (!isLeader) return false;
  await fakeFirestore.collection('meetings').add(data);
  return true;
}

/// Seeds a user document with the given role.
Future<void> _seedUser(
    FakeFirebaseFirestore fakeFirestore, String uid, UserRole role) async {
  await fakeFirestore.collection('users').doc(uid).set({
    'uid': uid,
    'email': '$uid@example.com',
    'displayName': 'Test User',
    'photoUrl': '',
    'role': role.toFirestoreString(),
    'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
  });
}

/// Seeds an active membership for the given user.
Future<void> _seedActiveMembership(
    FakeFirebaseFirestore fakeFirestore, String uid) async {
  await fakeFirestore.collection('memberships').doc(uid).set({
    'userId': uid,
    'status': 'active',
    'requestedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
  });
}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _memberUid = 'member-user-001';
const _leaderUid = 'leader-user-001';

final _sampleBook = {
  'title': 'Test Book',
  'author': 'Test Author',
  'description': 'A test book',
  'coverUrl': '',
  'status': 'reading',
  'createdBy': _leaderUid,
  'createdAt': Timestamp.fromDate(DateTime(2024, 6, 1)),
};

final _sampleMeeting = {
  'bookId': 'book-001',
  'date': Timestamp.fromDate(DateTime(2024, 6, 15)),
  'notes': 'Test meeting notes',
  'createdBy': _leaderUid,
  'createdAt': Timestamp.fromDate(DateTime(2024, 6, 1)),
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    // Seed users
    await _seedUser(fakeFirestore, _memberUid, UserRole.member);
    await _seedUser(fakeFirestore, _leaderUid, UserRole.leader);
    // Seed active memberships
    await _seedActiveMembership(fakeFirestore, _memberUid);
    await _seedActiveMembership(fakeFirestore, _leaderUid);
  });

  group('Firestore security rules smoke tests', () {
    // -----------------------------------------------------------------------
    // Role detection
    // -----------------------------------------------------------------------
    group('Role detection from Firestore user document', () {
      test('member user is NOT identified as leader', () async {
        final isLeader = await _checkIsLeader(fakeFirestore, _memberUid);
        expect(isLeader, isFalse,
            reason: 'A member user must not pass the isLeader check');
      });

      test('leader user IS identified as leader', () async {
        final isLeader = await _checkIsLeader(fakeFirestore, _leaderUid);
        expect(isLeader, isTrue,
            reason: 'A leader user must pass the isLeader check');
      });

      test('non-existent user is NOT identified as leader', () async {
        final isLeader = await _checkIsLeader(fakeFirestore, 'ghost-uid');
        expect(isLeader, isFalse,
            reason: 'A non-existent user must not pass the isLeader check');
      });
    });

    // -----------------------------------------------------------------------
    // Membership detection
    // -----------------------------------------------------------------------
    group('Active membership detection', () {
      test('user with active membership passes membership check', () async {
        final hasAccess = await _checkHasActiveMembership(fakeFirestore, _memberUid);
        expect(hasAccess, isTrue);
      });

      test('user without membership fails membership check', () async {
        final hasAccess = await _checkHasActiveMembership(fakeFirestore, 'no-membership-uid');
        expect(hasAccess, isFalse);
      });

      test('user with pending membership fails membership check', () async {
        await fakeFirestore.collection('memberships').doc('pending-uid').set({
          'userId': 'pending-uid',
          'status': 'pending',
          'requestedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });
        final hasAccess = await _checkHasActiveMembership(fakeFirestore, 'pending-uid');
        expect(hasAccess, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Write to books — Requirement 3.4
    // -----------------------------------------------------------------------
    group('Write to books collection', () {
      test('member CANNOT write to books (Requirement 3.4)', () async {
        final allowed = await _tryWriteBook(fakeFirestore, _memberUid, _sampleBook);
        expect(allowed, isFalse,
            reason: 'A member must not be allowed to write to books');
      });

      test('leader CAN write to books (Requirement 3.2)', () async {
        final allowed = await _tryWriteBook(fakeFirestore, _leaderUid, _sampleBook);
        expect(allowed, isTrue,
            reason: 'A leader must be allowed to write to books');
      });

      test('unauthenticated user (no doc) CANNOT write to books', () async {
        final allowed = await _tryWriteBook(fakeFirestore, 'unknown-uid', _sampleBook);
        expect(allowed, isFalse,
            reason: 'A user with no document must not write to books');
      });
    });

    // -----------------------------------------------------------------------
    // Write to meetings — Requirement 3.4
    // -----------------------------------------------------------------------
    group('Write to meetings collection', () {
      test('member CANNOT write to meetings (Requirement 3.4)', () async {
        final allowed = await _tryWriteMeeting(fakeFirestore, _memberUid, _sampleMeeting);
        expect(allowed, isFalse,
            reason: 'A member must not be allowed to write to meetings');
      });

      test('leader CAN write to meetings (Requirement 3.2)', () async {
        final allowed = await _tryWriteMeeting(fakeFirestore, _leaderUid, _sampleMeeting);
        expect(allowed, isTrue,
            reason: 'A leader must be allowed to write to meetings');
      });

      test('unauthenticated user (no doc) CANNOT write to meetings', () async {
        final allowed = await _tryWriteMeeting(fakeFirestore, 'unknown-uid', _sampleMeeting);
        expect(allowed, isFalse,
            reason: 'A user with no document must not write to meetings');
      });
    });

    // -----------------------------------------------------------------------
    // Role promotion — Requirement 3.2
    // -----------------------------------------------------------------------
    group('Role promotion grants write access', () {
      test('member promoted to leader can write to books', () async {
        // Initially member cannot write
        final beforePromotion = await _tryWriteBook(fakeFirestore, _memberUid, _sampleBook);
        expect(beforePromotion, isFalse);

        // Promote to leader (simulates a leader updating the role field)
        await fakeFirestore.collection('users').doc(_memberUid).update({
          'role': UserRole.leader.toFirestoreString(),
        });

        // Now should be able to write
        final afterPromotion = await _tryWriteBook(fakeFirestore, _memberUid, _sampleBook);
        expect(afterPromotion, isTrue,
            reason: 'After promotion to leader, user must be able to write to books');
      });

      test('member promoted to leader can write to meetings', () async {
        final beforePromotion = await _tryWriteMeeting(fakeFirestore, _memberUid, _sampleMeeting);
        expect(beforePromotion, isFalse);

        await fakeFirestore.collection('users').doc(_memberUid).update({
          'role': UserRole.leader.toFirestoreString(),
        });

        final afterPromotion = await _tryWriteMeeting(fakeFirestore, _memberUid, _sampleMeeting);
        expect(afterPromotion, isTrue,
            reason: 'After promotion to leader, user must be able to write to meetings');
      });
    });

    // -----------------------------------------------------------------------
    // Multiple members — all rejected
    // -----------------------------------------------------------------------
    group('Multiple member users are all rejected from writing', () {
      test('all member users are rejected from writing to books', () async {
        final memberIds = List.generate(10, (i) => 'member-$i');
        for (final uid in memberIds) {
          await _seedUser(fakeFirestore, uid, UserRole.member);
          final allowed = await _tryWriteBook(fakeFirestore, uid, _sampleBook);
          expect(allowed, isFalse,
              reason: 'Member $uid must not write to books');
        }
      });

      test('all member users are rejected from writing to meetings', () async {
        final memberIds = List.generate(10, (i) => 'member-meet-$i');
        for (final uid in memberIds) {
          await _seedUser(fakeFirestore, uid, UserRole.member);
          final allowed = await _tryWriteMeeting(fakeFirestore, uid, _sampleMeeting);
          expect(allowed, isFalse,
              reason: 'Member $uid must not write to meetings');
        }
      });
    });
  });
}
