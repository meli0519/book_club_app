// Smoke tests for Firestore security rules — Requirement 11
//
// These tests verify the security rule logic at the service/data layer by
// simulating the permission checks defined in firestore.rules using
// fake_cloud_firestore.
//
// NOTE: Full enforcement at the database level requires the Firebase Emulator.
// Run: `firebase emulators:start` and use @firebase/rules-unit-testing (JS)
// for emulator-based rule validation.
//
// Validates: Requirements 11.1 — read books/meetings only for active members
// Validates: Requirements 11.2 — write books/meetings only for leaders
// Validates: Requirements 11.3 — users read/write own document only
// Validates: Requirements 11.4 — write subcollections only for active members
// Validates: Requirements 11.5 — write memberships: leaders or own user (create)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_club_app/domain/models/app_user.dart';

// ---------------------------------------------------------------------------
// Permission helpers — mirror the functions in firestore.rules
// ---------------------------------------------------------------------------

Future<bool> _isLeader(FakeFirebaseFirestore fs, String uid) async {
  final doc = await fs.collection('users').doc(uid).get();
  if (!doc.exists) return false;
  return doc.data()?['role'] == 'leader';
}

Future<bool> _hasActiveMembership(FakeFirebaseFirestore fs, String uid) async {
  final doc = await fs.collection('memberships').doc(uid).get();
  if (!doc.exists) return false;
  return doc.data()?['status'] == 'active';
}

// ---------------------------------------------------------------------------
// Seeding helpers
// ---------------------------------------------------------------------------

Future<void> _seedUser(
    FakeFirebaseFirestore fs, String uid, UserRole role) async {
  await fs.collection('users').doc(uid).set({
    'uid': uid,
    'email': '$uid@example.com',
    'displayName': 'Test User',
    'photoUrl': '',
    'role': role.toFirestoreString(),
    'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
  });
}

Future<void> _seedMembership(
    FakeFirebaseFirestore fs, String uid, String status) async {
  await fs.collection('memberships').doc(uid).set({
    'userId': uid,
    'status': status,
    'requestedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
  });
}

// ---------------------------------------------------------------------------
// Simulated rule-gated operations
// ---------------------------------------------------------------------------

/// Rule: allow read if hasActiveMembership()
Future<bool> _tryReadBooks(FakeFirebaseFirestore fs, String uid) async {
  if (!await _hasActiveMembership(fs, uid)) return false;
  await fs.collection('books').get();
  return true;
}

/// Rule: allow read if hasActiveMembership()
Future<bool> _tryReadMeetings(FakeFirebaseFirestore fs, String uid) async {
  if (!await _hasActiveMembership(fs, uid)) return false;
  await fs.collection('meetings').get();
  return true;
}

/// Rule: allow write if isLeader()
Future<bool> _tryWriteBook(
    FakeFirebaseFirestore fs, String uid, Map<String, dynamic> data) async {
  if (!await _isLeader(fs, uid)) return false;
  await fs.collection('books').add(data);
  return true;
}

/// Rule: allow write if isLeader()
Future<bool> _tryWriteMeeting(
    FakeFirebaseFirestore fs, String uid, Map<String, dynamic> data) async {
  if (!await _isLeader(fs, uid)) return false;
  await fs.collection('meetings').add(data);
  return true;
}

/// Rule: allow read/write if request.auth.uid == userId
Future<bool> _tryReadOwnUser(
    FakeFirebaseFirestore fs, String requestingUid, String targetUid) async {
  if (requestingUid != targetUid) return false;
  await fs.collection('users').doc(targetUid).get();
  return true;
}

Future<bool> _tryWriteOwnUser(
    FakeFirebaseFirestore fs, String requestingUid, String targetUid) async {
  if (requestingUid != targetUid) return false;
  await fs
      .collection('users')
      .doc(targetUid)
      .update({'displayName': 'Updated'});
  return true;
}

/// Rule: allow write in subcollections if hasActiveMembership()
Future<bool> _tryWriteBookComment(
    FakeFirebaseFirestore fs, String uid, String bookId) async {
  if (!await _hasActiveMembership(fs, uid)) return false;
  await fs.collection('books').doc(bookId).collection('comments').add({
    'authorId': uid,
    'authorName': 'Test',
    'text': 'A comment',
    'createdAt': Timestamp.now(),
  });
  return true;
}

Future<bool> _tryWriteBookRating(
    FakeFirebaseFirestore fs, String uid, String bookId) async {
  if (!await _hasActiveMembership(fs, uid)) return false;
  await fs
      .collection('books')
      .doc(bookId)
      .collection('ratings')
      .doc(uid)
      .set({'authorId': uid, 'value': 4});
  return true;
}

Future<bool> _tryWriteBookReview(
    FakeFirebaseFirestore fs, String uid, String bookId) async {
  if (!await _hasActiveMembership(fs, uid)) return false;
  await fs
      .collection('books')
      .doc(bookId)
      .collection('reviews')
      .doc(uid)
      .set({
    'authorId': uid,
    'favoritePhrases': [],
    'answers': <String, String>{},
    'updatedAt': Timestamp.now(),
  });
  return true;
}

Future<bool> _tryWriteMeetingComment(
    FakeFirebaseFirestore fs, String uid, String meetingId) async {
  if (!await _hasActiveMembership(fs, uid)) return false;
  await fs
      .collection('meetings')
      .doc(meetingId)
      .collection('comments')
      .add({
    'authorId': uid,
    'authorName': 'Test',
    'text': 'A comment',
    'createdAt': Timestamp.now(),
  });
  return true;
}

Future<bool> _tryWriteMeetingRating(
    FakeFirebaseFirestore fs, String uid, String meetingId) async {
  if (!await _hasActiveMembership(fs, uid)) return false;
  await fs
      .collection('meetings')
      .doc(meetingId)
      .collection('ratings')
      .doc(uid)
      .set({'authorId': uid, 'value': 3});
  return true;
}

/// Rule: create = own user; update/delete = isLeader()
Future<bool> _tryCreateMembership(
    FakeFirebaseFirestore fs, String requestingUid, String targetUid) async {
  // Own user can create their initial request
  if (requestingUid == targetUid) {
    await fs.collection('memberships').doc(targetUid).set({
      'userId': targetUid,
      'status': 'pending',
      'requestedAt': Timestamp.now(),
    });
    return true;
  }
  // Leaders can also create
  if (await _isLeader(fs, requestingUid)) {
    await fs.collection('memberships').doc(targetUid).set({
      'userId': targetUid,
      'status': 'pending',
      'requestedAt': Timestamp.now(),
    });
    return true;
  }
  return false;
}

Future<bool> _tryUpdateMembership(
    FakeFirebaseFirestore fs, String requestingUid, String targetUid) async {
  if (!await _isLeader(fs, requestingUid)) return false;
  await fs.collection('memberships').doc(targetUid).update({
    'status': 'active',
    'approvedAt': Timestamp.now(),
    'approvedBy': requestingUid,
  });
  return true;
}

// ---------------------------------------------------------------------------
// Test constants
// ---------------------------------------------------------------------------

const _memberUid = 'member-001';
const _leaderUid = 'leader-001';
const _otherUid = 'other-001';
const _bookId = 'book-001';
const _meetingId = 'meeting-001';

final _sampleBook = {
  'title': 'Test Book',
  'author': 'Author',
  'description': 'Desc',
  'coverUrl': '',
  'status': 'reading',
  'createdBy': _leaderUid,
  'createdAt': Timestamp.fromDate(DateTime(2024, 6, 1)),
};

final _sampleMeeting = {
  'bookId': _bookId,
  'date': Timestamp.fromDate(DateTime(2024, 6, 15)),
  'notes': 'Notes',
  'partialRating': 4,
  'createdBy': _leaderUid,
  'createdAt': Timestamp.fromDate(DateTime(2024, 6, 1)),
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeFirebaseFirestore fs;

  setUp(() async {
    fs = FakeFirebaseFirestore();
    await _seedUser(fs, _memberUid, UserRole.member);
    await _seedUser(fs, _leaderUid, UserRole.leader);
    await _seedUser(fs, _otherUid, UserRole.member);
    await _seedMembership(fs, _memberUid, 'active');
    await _seedMembership(fs, _leaderUid, 'active');
    // Seed a book and meeting document for subcollection tests
    await fs.collection('books').doc(_bookId).set(_sampleBook);
    await fs.collection('meetings').doc(_meetingId).set(_sampleMeeting);
  });

  group('Requirement 11.1 — Read books and meetings: active members only', () {
    test('active member CAN read books', () async {
      expect(await _tryReadBooks(fs, _memberUid), isTrue);
    });

    test('active leader CAN read books', () async {
      expect(await _tryReadBooks(fs, _leaderUid), isTrue);
    });

    test('user with pending membership CANNOT read books', () async {
      await _seedMembership(fs, _otherUid, 'pending');
      expect(await _tryReadBooks(fs, _otherUid), isFalse);
    });

    test('user with no membership CANNOT read books', () async {
      expect(await _tryReadBooks(fs, 'no-membership-uid'), isFalse);
    });

    test('active member CAN read meetings', () async {
      expect(await _tryReadMeetings(fs, _memberUid), isTrue);
    });

    test('user with rejected membership CANNOT read meetings', () async {
      await _seedMembership(fs, _otherUid, 'rejected');
      expect(await _tryReadMeetings(fs, _otherUid), isFalse);
    });

    test('user with no membership CANNOT read meetings', () async {
      expect(await _tryReadMeetings(fs, 'no-membership-uid'), isFalse);
    });
  });

  group('Requirement 11.2 — Write books and meetings: leaders only', () {
    test('leader CAN write to books', () async {
      expect(await _tryWriteBook(fs, _leaderUid, _sampleBook), isTrue);
    });

    test('member CANNOT write to books', () async {
      expect(await _tryWriteBook(fs, _memberUid, _sampleBook), isFalse);
    });

    test('unknown user CANNOT write to books', () async {
      expect(await _tryWriteBook(fs, 'ghost-uid', _sampleBook), isFalse);
    });

    test('leader CAN write to meetings', () async {
      expect(await _tryWriteMeeting(fs, _leaderUid, _sampleMeeting), isTrue);
    });

    test('member CANNOT write to meetings', () async {
      expect(await _tryWriteMeeting(fs, _memberUid, _sampleMeeting), isFalse);
    });

    test('member promoted to leader CAN write to books', () async {
      expect(await _tryWriteBook(fs, _memberUid, _sampleBook), isFalse);
      await fs
          .collection('users')
          .doc(_memberUid)
          .update({'role': 'leader'});
      expect(await _tryWriteBook(fs, _memberUid, _sampleBook), isTrue);
    });
  });

  group('Requirement 11.3 — Users: read/write own document only', () {
    test('user CAN read their own document', () async {
      expect(await _tryReadOwnUser(fs, _memberUid, _memberUid), isTrue);
    });

    test('user CANNOT read another user document', () async {
      expect(await _tryReadOwnUser(fs, _memberUid, _leaderUid), isFalse);
    });

    test('user CAN write their own document', () async {
      expect(await _tryWriteOwnUser(fs, _memberUid, _memberUid), isTrue);
    });

    test('user CANNOT write another user document', () async {
      expect(await _tryWriteOwnUser(fs, _memberUid, _leaderUid), isFalse);
    });

    test('leader CANNOT read another user document via own-doc rule', () async {
      // The rule is uid == userId, not role-based — even leaders are restricted
      expect(await _tryReadOwnUser(fs, _leaderUid, _memberUid), isFalse);
    });
  });

  group('Requirement 11.4 — Subcollections: write for active members only', () {
    // books/comments
    test('active member CAN write book comment', () async {
      expect(await _tryWriteBookComment(fs, _memberUid, _bookId), isTrue);
    });

    test('user without membership CANNOT write book comment', () async {
      expect(
          await _tryWriteBookComment(fs, 'no-membership-uid', _bookId), isFalse);
    });

    test('user with pending membership CANNOT write book comment', () async {
      await _seedMembership(fs, _otherUid, 'pending');
      expect(await _tryWriteBookComment(fs, _otherUid, _bookId), isFalse);
    });

    // books/ratings
    test('active member CAN write book rating', () async {
      expect(await _tryWriteBookRating(fs, _memberUid, _bookId), isTrue);
    });

    test('user without membership CANNOT write book rating', () async {
      expect(
          await _tryWriteBookRating(fs, 'no-membership-uid', _bookId), isFalse);
    });

    // books/reviews
    test('active member CAN write book review', () async {
      expect(await _tryWriteBookReview(fs, _memberUid, _bookId), isTrue);
    });

    test('user without membership CANNOT write book review', () async {
      expect(
          await _tryWriteBookReview(fs, 'no-membership-uid', _bookId), isFalse);
    });

    // meetings/comments
    test('active member CAN write meeting comment', () async {
      expect(
          await _tryWriteMeetingComment(fs, _memberUid, _meetingId), isTrue);
    });

    test('user without membership CANNOT write meeting comment', () async {
      expect(
          await _tryWriteMeetingComment(fs, 'no-membership-uid', _meetingId),
          isFalse);
    });

    // meetings/ratings
    test('active member CAN write meeting rating', () async {
      expect(
          await _tryWriteMeetingRating(fs, _memberUid, _meetingId), isTrue);
    });

    test('user without membership CANNOT write meeting rating', () async {
      expect(
          await _tryWriteMeetingRating(fs, 'no-membership-uid', _meetingId),
          isFalse);
    });

    // leader (also active member) can write subcollections
    test('leader (active member) CAN write book comment', () async {
      expect(await _tryWriteBookComment(fs, _leaderUid, _bookId), isTrue);
    });
  });

  group('Requirement 11.5 — Memberships: leaders or own user (create only)', () {
    test('user CAN create their own membership request', () async {
      const newUid = 'new-user-001';
      expect(await _tryCreateMembership(fs, newUid, newUid), isTrue);
      final doc = await fs.collection('memberships').doc(newUid).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['status'], equals('pending'));
    });

    test('user CANNOT create membership for another user', () async {
      expect(
          await _tryCreateMembership(fs, _memberUid, 'another-user'), isFalse);
    });

    test('leader CAN create membership for any user', () async {
      const targetUid = 'target-user-001';
      expect(await _tryCreateMembership(fs, _leaderUid, targetUid), isTrue);
    });

    test('leader CAN update (approve) a membership', () async {
      // Seed a pending membership to update
      await _seedMembership(fs, _otherUid, 'pending');
      expect(await _tryUpdateMembership(fs, _leaderUid, _otherUid), isTrue);
      final doc = await fs.collection('memberships').doc(_otherUid).get();
      expect(doc.data()?['status'], equals('active'));
      expect(doc.data()?['approvedBy'], equals(_leaderUid));
    });

    test('member CANNOT update (approve) a membership', () async {
      await _seedMembership(fs, _otherUid, 'pending');
      expect(await _tryUpdateMembership(fs, _memberUid, _otherUid), isFalse);
    });

    test('member CANNOT update their own membership status', () async {
      // Members cannot self-approve — only leaders can update
      expect(
          await _tryUpdateMembership(fs, _memberUid, _memberUid), isFalse);
    });
  });
}
