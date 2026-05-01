// Smoke test: verifies that UserRole enum has exactly two valid values.
// Validates: Requirements 3.1
import 'package:flutter_test/flutter_test.dart';
import 'package:book_club_app/domain/models/app_user.dart';

void main() {
  group('UserRole smoke tests', () {
    test('exactly two roles exist: member and leader', () {
      expect(UserRole.values.length, equals(2));
      expect(UserRole.values, containsAll([UserRole.member, UserRole.leader]));
    });

    test('fromString returns member for "member"', () {
      expect(UserRole.fromString('member'), equals(UserRole.member));
    });

    test('fromString returns leader for "leader"', () {
      expect(UserRole.fromString('leader'), equals(UserRole.leader));
    });

    test('fromString defaults to member for unknown values', () {
      expect(UserRole.fromString('admin'), equals(UserRole.member));
      expect(UserRole.fromString(''), equals(UserRole.member));
      expect(UserRole.fromString('superuser'), equals(UserRole.member));
    });

    test('toFirestoreString round-trips correctly for member', () {
      const role = UserRole.member;
      expect(UserRole.fromString(role.toFirestoreString()), equals(role));
    });

    test('toFirestoreString round-trips correctly for leader', () {
      const role = UserRole.leader;
      expect(UserRole.fromString(role.toFirestoreString()), equals(role));
    });

    test('toFirestoreString returns correct string values', () {
      expect(UserRole.member.toFirestoreString(), equals('member'));
      expect(UserRole.leader.toFirestoreString(), equals('leader'));
    });

    test('AppUser.isLeader is true only for leader role', () {
      final leader = _makeUser(UserRole.leader);
      final member = _makeUser(UserRole.member);
      expect(leader.isLeader, isTrue);
      expect(member.isLeader, isFalse);
    });

    test('AppUser.isMember is true only for member role', () {
      final leader = _makeUser(UserRole.leader);
      final member = _makeUser(UserRole.member);
      expect(member.isMember, isTrue);
      expect(leader.isMember, isFalse);
    });
  });
}

AppUser _makeUser(UserRole role) {
  return AppUser(
    uid: 'uid-test',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: '',
    role: role,
    createdAt: DateTime(2024, 1, 1),
  );
}
