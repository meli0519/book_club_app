import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/membership.dart';
import 'membership_provider.dart';

// ---------------------------------------------------------------------------
// Service providers
// ---------------------------------------------------------------------------

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final userServiceProvider = Provider<UserService>((ref) => UserService());

// ---------------------------------------------------------------------------
// Auth state stream
// ---------------------------------------------------------------------------

/// Emits the current Firebase [User] (or null when signed out).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ---------------------------------------------------------------------------
// Membership status after login
// ---------------------------------------------------------------------------

/// Possible outcomes of the post-login membership check.
enum MembershipStatus { loading, none, pending, active, rejected }

/// Holds the result of the membership check together with any error message.
class MembershipState {
  final MembershipStatus status;
  final String? errorMessage;

  const MembershipState({required this.status, this.errorMessage});

  static const loading = MembershipState(status: MembershipStatus.loading);
  static const none = MembershipState(status: MembershipStatus.none);
  static const pending = MembershipState(status: MembershipStatus.pending);
  static const active = MembershipState(status: MembershipStatus.active);
  static const rejected = MembershipState(status: MembershipStatus.rejected);
}

/// Resolves the membership status for the currently authenticated user.
///
/// - If no membership doc exists → calls [requestMembership] and returns [MembershipStatus.none]
///   (router will show PendingAccessScreen after the doc is created).
/// - If status is 'pending'  → returns [MembershipStatus.pending].
/// - If status is 'active'   → returns [MembershipStatus.active].
/// - If status is 'rejected' → returns [MembershipStatus.rejected].
final membershipStatusProvider =
    FutureProvider.autoDispose<MembershipState>((ref) async {
  final authAsync = ref.watch(authStateProvider);

  return authAsync.when(
    loading: () async => MembershipState.loading,
    error: (e, _) async =>
        MembershipState(status: MembershipStatus.none, errorMessage: e.toString()),
    data: (user) async {
      if (user == null) return MembershipState.none;

      final repository = ref.read(membershipRepositoryProvider);
      final Membership? membership = await repository.getMembership(user.uid);

      if (membership == null) {
        // No membership → create pending request (Requirement 10.1)
        await repository.requestMembership(user.uid);
        return MembershipState.none;
      }

      switch (membership.status) {
        case 'active':
          return MembershipState.active;
        case 'pending':
          return MembershipState.pending;
        case 'rejected':
          return MembershipState.rejected;
        default:
          return MembershipState.pending;
      }
    },
  );
});

// ---------------------------------------------------------------------------
// Auth actions notifier
// ---------------------------------------------------------------------------

/// Exposes sign-in / sign-out actions and tracks any auth error message.
class AuthNotifier extends StateNotifier<String?> {
  final AuthService _authService;
  final UserService _userService;

  AuthNotifier(this._authService, this._userService) : super(null);

  /// Registers a new user with email/password, creates Firestore user doc
  /// and a pending membership document.
  /// Returns true on success, false on failure (error stored in state).
  Future<bool> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    state = null;
    try {
      final credential = await _authService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );
      // Create user doc in Firestore with displayName from form (not from Firebase Auth yet)
      final user = credential.user;
      if (user != null) {
        await _userService.createUserWithDisplayName(
          credential,
          displayName,
        );
      }
      return true;
    } on FirebaseAuthException catch (e) {
      state = e.message ?? 'Registration failed. Please try again.';
      return false;
    } catch (e) {
      state = 'An unexpected error occurred. Please try again.';
      return false;
    }
  }

  /// Performs Google Sign-In, creates/updates the user doc in Firestore.
  /// Returns true on success, false on failure (error stored in state).
  Future<bool> signInWithGoogle() async {
    state = null; // clear previous error
    try {
      print('🔵 Starting Google Sign-In...');
      final credential = await _authService.signInWithGoogle();
      print('✅ Google Sign-In successful, handling user authentication...');
      await _userService.handleUserAuthentication(credential);
      print('✅ User authentication handled successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      state = e.message ?? 'Authentication failed. Please try again.';
      return false;
    } catch (e) {
      print('❌ Unexpected error in signInWithGoogle: $e');
      state = 'An unexpected error occurred. Please try again.';
      return false;
    }
  }

  /// Performs email/password sign-in, creates/updates the user doc in Firestore.
  /// Returns true on success, false on failure (error stored in state).
  Future<bool> signInWithEmailPassword(String email, String password) async {
    state = null; // clear previous error
    try {
      print('🔵 Starting email/password sign-in...');
      final credential = await _authService.signInWithEmailPassword(email, password);
      print('✅ Email/password sign-in successful, handling user authentication...');
      await _userService.handleUserAuthentication(credential);
      print('✅ User authentication handled successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      state = e.message ?? 'Authentication failed. Please try again.';
      return false;
    } catch (e) {
      print('❌ Unexpected error in signInWithEmailPassword: $e');
      state = 'An unexpected error occurred. Please try again.';
      return false;
    }
  }

  /// Signs out from Firebase and Google.
  Future<void> signOut() async {
    state = null;
    try {
      await _authService.signOut();
    } catch (_) {
      // Ignore sign-out errors – user is effectively signed out locally.
    }
  }

  /// Clears any stored error message.
  void clearError() => state = null;
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, String?>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(userServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Current AppUser provider
// ---------------------------------------------------------------------------

/// Resolves the [AppUser] document for the currently authenticated Firebase user.
/// Returns null when signed out or when the document doesn't exist yet.
final currentUserProvider = FutureProvider.autoDispose<AppUser?>((ref) async {
  final authAsync = ref.watch(authStateProvider);
  final firebaseUser = authAsync.valueOrNull;
  if (firebaseUser == null) return null;
  final userService = ref.read(userServiceProvider);
  return userService.getUser(firebaseUser.uid);
});

// ---------------------------------------------------------------------------
// Role provider
// ---------------------------------------------------------------------------

/// Exposes the [UserRole] of the currently authenticated user.
/// Returns [UserRole.member] when loading or unauthenticated (safe default).
final currentUserRoleProvider = Provider.autoDispose<UserRole>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.valueOrNull?.role ?? UserRole.member;
});
