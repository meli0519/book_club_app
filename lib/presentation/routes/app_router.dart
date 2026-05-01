import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../domain/models/app_user.dart' show UserRole;
import '../screens/auth/auth_screen.dart';
import '../screens/auth/pending_access_screen.dart';
import '../screens/auth/waiting_screen.dart';
import '../screens/auth/password_recovery_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/books/book_list_screen.dart';
import '../screens/books/book_detail_screen.dart';
import '../screens/books/create_edit_book_screen.dart';
import '../screens/admin/member_management_screen.dart';
import '../screens/admin/review_questions_management_screen.dart';
import '../screens/meetings/meeting_screen.dart';
import '../screens/meetings/create_edit_meeting_screen.dart';
import '../screens/meetings/ratings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/personal_books/personal_book_form_screen.dart';
import '../screens/personal_books/personal_books_screen.dart';
import '../screens/personal_books/personal_book_detail_screen.dart';
import '../../domain/models/book.dart';
import '../../domain/models/meeting.dart';

// ---------------------------------------------------------------------------
// Route paths
// ---------------------------------------------------------------------------

class AppRoutes {
  static const auth = '/';
  static const passwordRecovery = '/password-recovery';
  static const register = '/register';
  static const pendingAccess = '/pending';
  static const waiting = '/waiting';
  static const home = '/home';
  static const books = '/books';
  static const createBook = '/books/create';
  static const editBook = '/books/:id/edit';
  static const bookDetailPath = '/books/:id';
  static const memberManagement = '/admin/members';
  static const reviewQuestionsManagement = '/admin/review-questions';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const library = '/library';
  static const personalBooks = '/personal-books';
  static const createPersonalBook = '/personal-books/create';
  static const personalBookDetailPath = '/personal-books/:id';
  static const editPersonalBookPath = '/personal-books/:id/edit';

  /// Returns the path for a specific book's meetings screen.
  static String bookMeetings(String bookId) => '/books/$bookId/meetings';

  /// Returns the path for creating a meeting for a book.
  static String createMeeting(String bookId) =>
      '/books/$bookId/meetings/create';

  /// Returns the path for editing a meeting.
  static String editMeetingPath(String bookId, String meetingId) =>
      '/books/$bookId/meetings/$meetingId/edit';

  /// Returns the path for the ratings screen of a meeting.
  static String meetingRatings(String bookId, String meetingId) =>
      '/books/$bookId/meetings/$meetingId/ratings';

  /// Returns the path for a specific book's detail screen.
  static String bookDetail(String bookId) => '/books/$bookId';

  /// Returns the path for editing a specific book.
  static String editBookPath(String bookId) => '/books/$bookId/edit';

  /// Returns the path for a specific personal book's detail screen.
  static String personalBookDetail(String bookId) => '/personal-books/$bookId';

  /// Returns the path for editing a specific personal book.
  static String editPersonalBook(String bookId) => '/personal-books/$bookId/edit';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final appRouterProvider = Provider<GoRouter>((ref) {
  // Notifier that triggers router re-evaluation when auth or membership changes.
  final refreshNotifier = _RouterRefreshNotifier();

  // Listen to auth state changes.
  ref.listen(authStateProvider, (_, __) => refreshNotifier.notify());

  // Listen to membership status changes.
  ref.listen(membershipStatusProvider, (_, __) => refreshNotifier.notify());

  return GoRouter(
    initialLocation: AppRoutes.auth,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);

      // While auth state is loading, stay put.
      if (authAsync.isLoading) return null;

      final user = authAsync.valueOrNull;

      // Not signed in → always go to auth screen.
      if (user == null) {
        final publicRoutes = [AppRoutes.auth, AppRoutes.passwordRecovery, AppRoutes.register];
        return publicRoutes.contains(state.matchedLocation) ? null : AppRoutes.auth;
      }

      // Signed in → check membership status.
      final membershipAsync = ref.read(membershipStatusProvider);

      // While membership is loading, stay put.
      if (membershipAsync.isLoading) return null;

      final membershipState =
          membershipAsync.valueOrNull ?? MembershipState.loading;

      switch (membershipState.status) {
        case MembershipStatus.loading:
          return null;

        case MembershipStatus.active:
          // Has active membership → check leader-only routes.
          final leaderOnlyRoutes = [
            AppRoutes.memberManagement,
            AppRoutes.reviewQuestionsManagement,
            AppRoutes.createBook,
          ];
          final isLeaderOnlyRoute = leaderOnlyRoutes.any(
                (r) => state.matchedLocation == r,
              ) ||
              (state.matchedLocation.endsWith('/edit') &&
                  !state.matchedLocation.startsWith('/profile') &&
                  !state.matchedLocation.startsWith('/personal-books')) ||
              (state.matchedLocation.endsWith('/create') &&
                  !state.matchedLocation.startsWith('/personal-books'));

          if (isLeaderOnlyRoute) {
            final userRole = ref.read(currentUserRoleProvider);
            if (userRole != UserRole.leader) return AppRoutes.books;
          }

          // Active member → go to home (unless already in books/home/admin/personal-books section).
          if (state.matchedLocation == AppRoutes.home) return null;
          if (state.matchedLocation.startsWith(AppRoutes.books)) return null;
          if (state.matchedLocation.startsWith('/admin')) return null;
          if (state.matchedLocation.startsWith(AppRoutes.profile)) return null;
          if (state.matchedLocation == AppRoutes.library) return null;
          if (state.matchedLocation.startsWith(AppRoutes.personalBooks)) return null;
          return AppRoutes.home;

        case MembershipStatus.pending:
          // Membership pending → allow personal books or waiting screen.
          final isPersonalBooksRoute = 
              state.matchedLocation.startsWith(AppRoutes.personalBooks) ||
              state.matchedLocation.startsWith('/personal-books');
          
          if (isPersonalBooksRoute) return null;
          if (state.matchedLocation == AppRoutes.waiting) return null;
          return AppRoutes.waiting;

        case MembershipStatus.none:
        case MembershipStatus.rejected:
          // No membership (just created) or rejected → allow access to personal books
          // All authenticated users can access personal books regardless of membership
          final isPersonalBooksRoute = 
              state.matchedLocation.startsWith(AppRoutes.personalBooks) ||
              state.matchedLocation.startsWith('/personal-books');
          
          // Allow access to personal books for all authenticated users
          if (isPersonalBooksRoute) return null;
          
          // Non-members without personal books access go to pending access
          if (state.matchedLocation == AppRoutes.pendingAccess) return null;
          return AppRoutes.pendingAccess;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordRecovery,
        builder: (context, state) => const PasswordRecoveryScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingAccess,
        builder: (context, state) => const PendingAccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.waiting,
        builder: (context, state) => const WaitingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.books,
        builder: (context, state) => const BookListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createBook,
        builder: (context, state) => const CreateEditBookScreen(),
      ),
      GoRoute(
        path: AppRoutes.editBook,
        builder: (context, state) {
          final book = state.extra as Book?;
          return CreateEditBookScreen(book: book);
        },
      ),
      GoRoute(
        path: AppRoutes.bookDetailPath,
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return BookDetailScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: AppRoutes.memberManagement,
        builder: (context, state) => const MemberManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.reviewQuestionsManagement,
        builder: (context, state) =>
            const ReviewQuestionsManagementScreen(),
      ),
      GoRoute(
        path: '/books/:bookId/meetings',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return MeetingScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/books/:bookId/meetings/create',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return CreateEditMeetingScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/books/:bookId/meetings/:meetingId/edit',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final meeting = state.extra as Meeting?;
          return CreateEditMeetingScreen(bookId: bookId, meeting: meeting);
        },
      ),
      GoRoute(
        path: '/books/:bookId/meetings/:meetingId/ratings',
        builder: (context, state) {
          final meetingId = state.pathParameters['meetingId']!;
          return RatingsScreen(meetingId: meetingId);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.library,
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalBooks,
        builder: (context, state) => const PersonalBooksScreen(),
      ),
      GoRoute(
        path: AppRoutes.createPersonalBook,
        builder: (context, state) => const PersonalBookFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.editPersonalBookPath,
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return PersonalBookFormScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: AppRoutes.personalBookDetailPath,
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return PersonalBookDetailScreen(bookId: bookId);
        },
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Refresh notifier – triggers router re-evaluation on auth/membership changes
// ---------------------------------------------------------------------------

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
