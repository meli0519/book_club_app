import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_user.dart';
import 'auth_provider.dart';

/// Real-time stream of the current user's [AppUser] document from Firestore.
/// Automatically updates when the Firestore document changes (e.g. after
/// editing the profile), satisfying subtask 19.5.
///
/// Uses [fb_auth.FirebaseAuth.instance.currentUser] as an immediate fallback
/// so the stream starts even before [authStateProvider] emits its first value.
final currentUserStreamProvider = StreamProvider<AppUser?>((ref) {
  // Try the synchronous current user first (available immediately on hot
  // restart / navigation) to avoid a blank screen while the auth stream warms up.
  final firebaseUser = ref.watch(authStateProvider).valueOrNull
      ?? fb_auth.FirebaseAuth.instance.currentUser;

  if (firebaseUser == null) return const Stream.empty();

  final userService = ref.read(userServiceProvider);
  return userService.watchUser(firebaseUser.uid);
});

/// Fetches a single [AppUser] by [uid] — used anywhere user info (name, photo,
/// email) needs to be resolved from an ID stored in Firestore documents.
final userByIdProvider =
    FutureProvider.family<AppUser?, String>((ref, uid) async {
  if (uid.isEmpty) return null;
  try {
    return await ref.read(userServiceProvider).getUser(uid);
  } catch (_) {
    return null;
  }
});
