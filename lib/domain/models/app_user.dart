import 'package:cloud_firestore/cloud_firestore.dart';

/// The two supported roles in the Book Club App.
/// Requirement 3.1: exactly two roles — member and leader.
enum UserRole {
  member,
  leader;

  /// Converts a Firestore string value to [UserRole].
  /// Defaults to [UserRole.member] for unknown values.
  static UserRole fromString(String value) {
    switch (value) {
      case 'leader':
        return UserRole.leader;
      case 'member':
      default:
        return UserRole.member;
    }
  }

  /// Returns the Firestore-compatible string representation.
  String toFirestoreString() {
    switch (this) {
      case UserRole.leader:
        return 'leader';
      case UserRole.member:
        return 'member';
    }
  }
}

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final UserRole role;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      uid: id,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String,
      role: UserRole.fromString(map['role'] as String? ?? 'member'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.toFirestoreString(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Returns true if this user has leader privileges.
  bool get isLeader => role == UserRole.leader;

  /// Returns true if this user is a regular member.
  bool get isMember => role == UserRole.member;
}
