import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/membership_service.dart';
import '../../data/services/user_service.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/membership.dart';
import '../../domain/repositories/membership_repository.dart';

/// Provides the MembershipRepository implementation.
final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return MembershipService();
});

/// Stream of all pending memberships (for leader management screen).
final pendingMembershipsProvider = StreamProvider<List<Membership>>((ref) {
  final repository = ref.watch(membershipRepositoryProvider);
  return repository.watchPendingMemberships();
});

/// Fetches the membership for a specific user.
final membershipProvider =
    FutureProvider.family<Membership?, String>((ref, userId) async {
  final repository = ref.watch(membershipRepositoryProvider);
  return repository.getMembership(userId);
});

// ---------------------------------------------------------------------------
// Membership actions notifier (approve / reject)
// ---------------------------------------------------------------------------

/// Tracks the in-progress userId for approve/reject operations.
/// null = idle, non-null = that userId is being processed.
class MembershipActionsNotifier extends StateNotifier<String?> {
  final MembershipRepository _repository;

  MembershipActionsNotifier(this._repository) : super(null);

  /// Approve a pending membership. [leaderId] is the uid of the approving leader.
  /// Requirement 10.2 / 2.2
  Future<void> approve(String userId, String leaderId) async {
    state = userId;
    try {
      await _repository.approveMembership(userId, leaderId);
    } finally {
      state = null;
    }
  }

  /// Reject / remove a membership.
  /// Requirement 10.3
  Future<void> reject(String userId) async {
    state = userId;
    try {
      await _repository.rejectMembership(userId);
    } finally {
      state = null;
    }
  }
}

final membershipActionsProvider =
    StateNotifierProvider<MembershipActionsNotifier, String?>((ref) {
  return MembershipActionsNotifier(ref.watch(membershipRepositoryProvider));
});

/// Fetches the [AppUser] for a given userId — used in the member management
/// screen to show photo, name and email alongside the membership request.
final memberUserProvider =
    FutureProvider.family<AppUser?, String>((ref, userId) async {
  return UserService().getUser(userId);
});
