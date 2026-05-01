import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/membership_service.dart';
import '../../data/services/user_service.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/membership.dart';

/// Provides the UserService instance.
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

/// Provides the MembershipService instance.
final membershipServiceProvider = Provider<MembershipService>((ref) {
  return MembershipService();
});

/// Stream of all users in the system.
final allUsersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.watchAllUsers();
});

/// Stream of all memberships (all statuses).
final allMembershipsStreamProvider = StreamProvider<List<Membership>>((ref) {
  final membershipService = ref.watch(membershipServiceProvider);
  return membershipService.watchAllMemberships();
});

/// Combined data: user + membership for user management screen.
class UserWithMembership {
  final AppUser user;
  final Membership? membership;

  const UserWithMembership({
    required this.user,
    this.membership,
  });

  bool get isActive => membership?.status == 'active';
  bool get isPending => membership?.status == 'pending';
  bool get isRejected => membership?.status == 'rejected';
}

/// Stream provider that combines users and memberships.
final usersWithMembershipsProvider =
    StreamProvider<List<UserWithMembership>>((ref) {
  final userService = ref.watch(userServiceProvider);
  final membershipService = ref.watch(membershipServiceProvider);

  return userService.watchAllUsers().asyncMap((users) async {
    // Get all memberships as a list
    final memberships = await membershipService.watchAllMemberships().first;
    
    // Combine users with their memberships
    return users.map((user) {
      final membership = memberships.firstWhere(
        (m) => m.userId == user.uid,
        orElse: () => Membership(
          userId: user.uid,
          status: 'pending',
          requestedAt: user.createdAt,
        ),
      );
      return UserWithMembership(user: user, membership: membership);
    }).toList();
  });
});

// ---------------------------------------------------------------------------
// User management actions notifier
// ---------------------------------------------------------------------------

/// Tracks the in-progress userId for user management operations.
class UserManagementActionsNotifier extends StateNotifier<String?> {
  final UserService _userService;
  final MembershipService _membershipService;

  UserManagementActionsNotifier(this._userService, this._membershipService)
      : super(null);

  /// Toggle user role between member and leader.
  Future<void> toggleRole(String userId, UserRole currentRole) async {
    state = userId;
    try {
      final newRole =
          currentRole == UserRole.leader ? UserRole.member : UserRole.leader;
      await _userService.updateUserRole(userId, newRole);
    } finally {
      state = null;
    }
  }

  /// Deactivate a user's membership.
  Future<void> deactivate(String userId) async {
    state = userId;
    try {
      await _membershipService.deactivateMembership(userId);
    } finally {
      state = null;
    }
  }

  /// Reactivate a user's membership.
  Future<void> reactivate(String userId, String approvedBy) async {
    state = userId;
    try {
      await _membershipService.reactivateMembership(userId, approvedBy);
    } finally {
      state = null;
    }
  }
}

final userManagementActionsProvider =
    StateNotifierProvider<UserManagementActionsNotifier, String?>((ref) {
  return UserManagementActionsNotifier(
    ref.watch(userServiceProvider),
    ref.watch(membershipServiceProvider),
  );
});
