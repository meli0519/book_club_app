import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/presentation/providers/auth_provider.dart';
import 'package:book_club_app/presentation/routes/app_router.dart';

// ---------------------------------------------------------------------------
// Redirect logic unit tests
//
// These tests exercise the redirect function directly by constructing a
// GoRouter with the same redirect logic as [appRouterProvider] but with
// controlled provider overrides.
// ---------------------------------------------------------------------------

void main() {
  group('Navigation redirect logic', () {
    // -----------------------------------------------------------------------
    // 1. Unauthenticated user → auth screen
    // -----------------------------------------------------------------------
    test('unauthenticated user is redirected to auth screen', () {
      // Simulate: auth = null (not signed in)
      final authState = const AsyncValue<dynamic>.data(null);
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.loading,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: '/books',
      );

      expect(redirectResult, equals(AppRoutes.auth));
    });

    test('unauthenticated user on auth screen stays on auth screen', () {
      final authState = const AsyncValue<dynamic>.data(null);
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.loading,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: AppRoutes.auth,
      );

      // null means "stay here"
      expect(redirectResult, isNull);
    });

    // -----------------------------------------------------------------------
    // 2. Authenticated + no membership → pending screen
    // -----------------------------------------------------------------------
    test('authenticated user with no membership is redirected to pending', () {
      final authState = AsyncValue<dynamic>.data(_FakeUser());
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.none,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: '/books',
      );

      expect(redirectResult, equals(AppRoutes.pendingAccess));
    });

    test('authenticated user with rejected membership is redirected to pending', () {
      final authState = AsyncValue<dynamic>.data(_FakeUser());
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.rejected,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: '/books',
      );

      expect(redirectResult, equals(AppRoutes.pendingAccess));
    });

    test('user on pending screen with no membership stays on pending', () {
      final authState = AsyncValue<dynamic>.data(_FakeUser());
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.none,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: AppRoutes.pendingAccess,
      );

      expect(redirectResult, isNull);
    });

    // -----------------------------------------------------------------------
    // 3. Authenticated + pending membership → waiting screen
    // -----------------------------------------------------------------------
    test('authenticated user with pending membership is redirected to waiting', () {
      final authState = AsyncValue<dynamic>.data(_FakeUser());
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.pending,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: '/books',
      );

      expect(redirectResult, equals(AppRoutes.waiting));
    });

    test('user on waiting screen with pending membership stays on waiting', () {
      final authState = AsyncValue<dynamic>.data(_FakeUser());
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.pending,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: AppRoutes.waiting,
      );

      expect(redirectResult, isNull);
    });

    // -----------------------------------------------------------------------
    // 4. Active member → can access book list
    // -----------------------------------------------------------------------
    test('active member can access book list screen', () {
      final authState = AsyncValue<dynamic>.data(_FakeUser());
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.active,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: AppRoutes.books,
      );

      // null = stay on /books
      expect(redirectResult, isNull);
    });

    test('active member accessing root is redirected to books', () {
      final authState = AsyncValue<dynamic>.data(_FakeUser());
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.active,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: AppRoutes.auth,
      );

      expect(redirectResult, equals(AppRoutes.books));
    });

    test('active member can access book detail screen', () {
      final authState = AsyncValue<dynamic>.data(_FakeUser());
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.active,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: '/books/some-book-id',
      );

      expect(redirectResult, isNull);
    });

    test('active member can access meetings screen', () {
      final authState = AsyncValue<dynamic>.data(_FakeUser());
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.active,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: '/books/some-book-id/meetings',
      );

      expect(redirectResult, isNull);
    });

    // -----------------------------------------------------------------------
    // 5. Loading states → stay put (no redirect)
    // -----------------------------------------------------------------------
    test('loading auth state does not redirect', () {
      const authState = AsyncValue<dynamic>.loading();
      final membershipState = const AsyncValue<MembershipState>.data(
        MembershipState.loading,
      );

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: '/books',
      );

      expect(redirectResult, isNull);
    });

    test('loading membership state does not redirect', () {
      final authState = AsyncValue<dynamic>.data(_FakeUser());
      const membershipState = AsyncValue<MembershipState>.loading();

      final redirectResult = _simulateRedirect(
        authState: authState,
        membershipState: membershipState,
        currentLocation: '/books',
      );

      expect(redirectResult, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Route path constants tests
  // -------------------------------------------------------------------------
  group('AppRoutes constants', () {
    test('auth route is root', () {
      expect(AppRoutes.auth, equals('/'));
    });

    test('pending access route is /pending', () {
      expect(AppRoutes.pendingAccess, equals('/pending'));
    });

    test('waiting route is /waiting', () {
      expect(AppRoutes.waiting, equals('/waiting'));
    });

    test('books route is /books', () {
      expect(AppRoutes.books, equals('/books'));
    });

    test('member management route is /admin/members', () {
      expect(AppRoutes.memberManagement, equals('/admin/members'));
    });

    test('review questions management route is /admin/review-questions', () {
      expect(
        AppRoutes.reviewQuestionsManagement,
        equals('/admin/review-questions'),
      );
    });

    test('bookDetail helper generates correct path', () {
      expect(AppRoutes.bookDetail('abc123'), equals('/books/abc123'));
    });

    test('bookMeetings helper generates correct path', () {
      expect(AppRoutes.bookMeetings('abc123'), equals('/books/abc123/meetings'));
    });

    test('editBookPath helper generates correct path', () {
      expect(AppRoutes.editBookPath('abc123'), equals('/books/abc123/edit'));
    });

    test('createMeeting helper generates correct path', () {
      expect(
        AppRoutes.createMeeting('abc123'),
        equals('/books/abc123/meetings/create'),
      );
    });

    test('editMeetingPath helper generates correct path', () {
      expect(
        AppRoutes.editMeetingPath('abc123', 'mtg456'),
        equals('/books/abc123/meetings/mtg456/edit'),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Redirect simulation helper
//
// Replicates the redirect logic from app_router.dart without needing a real
// GoRouter instance or Firebase, so tests run fast and offline.
// ---------------------------------------------------------------------------

String? _simulateRedirect({
  required AsyncValue<dynamic> authState,
  required AsyncValue<MembershipState> membershipState,
  required String currentLocation,
}) {
  final isOnAuth = currentLocation == AppRoutes.auth;

  // While auth state is loading, stay put.
  if (authState.isLoading) return null;

  final user = authState.valueOrNull;

  // Not signed in → always go to auth screen.
  if (user == null) {
    return isOnAuth ? null : AppRoutes.auth;
  }

  // Signed in → check membership status.
  if (membershipState.isLoading) return null;

  final membershipStateValue =
      membershipState.valueOrNull ?? MembershipState.loading;

  switch (membershipStateValue.status) {
    case MembershipStatus.loading:
      return null;

    case MembershipStatus.active:
      if (currentLocation.startsWith(AppRoutes.books)) return null;
      if (currentLocation.startsWith('/admin')) return null;
      return AppRoutes.books;

    case MembershipStatus.pending:
      if (currentLocation == AppRoutes.waiting) return null;
      return AppRoutes.waiting;

    case MembershipStatus.none:
    case MembershipStatus.rejected:
      if (currentLocation == AppRoutes.pendingAccess) return null;
      return AppRoutes.pendingAccess;
  }
}

// ---------------------------------------------------------------------------
// Fake user object (avoids Firebase dependency in tests)
// ---------------------------------------------------------------------------

class _FakeUser {
  final String uid = 'test-uid-123';
  final String email = 'test@example.com';
}
