// Feature: personal-books
// Providers de Riverpod para la feature de libros personales.
//
// Validates: Requirements 1.2, 5.1, 5.2

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/personal_book_service.dart';
import '../../domain/models/personal_book.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Service provider
// ---------------------------------------------------------------------------

/// Provides a singleton [PersonalBookService] instance.
final personalBookServiceProvider = Provider<PersonalBookService>(
  (ref) => PersonalBookService(),
);

// ---------------------------------------------------------------------------
// Stream providers
// ---------------------------------------------------------------------------

/// Watches all personal books for the currently authenticated user,
/// ordered by [updatedAt] descending.
///
/// Returns [Stream.empty()] when no user is signed in.
final personalBooksStreamProvider = StreamProvider<List<PersonalBook>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref
      .watch(personalBookServiceProvider)
      .watchPersonalBooks(user.uid);
});

/// Watches personal books for the currently authenticated user filtered by
/// [status] (one of [PersonalBookStatus] constants).
///
/// Returns [Stream.empty()] when no user is signed in.
final personalBooksByStatusProvider =
    StreamProvider.family<List<PersonalBook>, String>((ref, status) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref
      .watch(personalBookServiceProvider)
      .watchPersonalBooksByStatus(user.uid, status);
});

/// Watches a single personal book document identified by [bookId] for the
/// currently authenticated user.
///
/// Returns [Stream.empty()] when no user is signed in.
final personalBookStreamProvider =
    StreamProvider.family<PersonalBook?, String>((ref, bookId) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref
      .watch(personalBookServiceProvider)
      .watchPersonalBook(user.uid, bookId);
});
