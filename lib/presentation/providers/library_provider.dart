import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/library_service.dart';
import '../../domain/models/user_book_entry.dart';
import 'auth_provider.dart';

final libraryServiceProvider = Provider<LibraryService>((ref) {
  return LibraryService();
});

/// Watches the current user's personal library entries in real time.
final userLibraryStreamProvider = StreamProvider<List<UserBookEntry>>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final User? user = authAsync.valueOrNull;
  if (user == null) return const Stream.empty();

  final service = ref.watch(libraryServiceProvider);
  return service.watchUserLibrary(user.uid);
});

/// Filtered stream for a specific category (entry-only, no book details).
final libraryByCategoryProvider =
    Provider.family<AsyncValue<List<UserBookEntry>>, String>((ref, category) {
  final allEntries = ref.watch(userLibraryStreamProvider);
  return allEntries.whenData(
    (entries) =>
        entries.where((e) => e.category == category).toList(),
  );
});

/// Filtered stream for a specific category enriched with full [Book] data
/// and average rating. Use this provider in the UI instead of
/// [libraryByCategoryProvider] when you need cover, title, author, or rating.
final libraryWithDetailsByCategoryProvider =
    StreamProvider.family<List<UserBookWithDetails>, String>(
        (ref, category) {
  final authAsync = ref.watch(authStateProvider);
  final User? user = authAsync.valueOrNull;
  if (user == null) return const Stream.empty();

  final service = ref.watch(libraryServiceProvider);
  return service.watchLibraryByCategory(user.uid, category);
});

/// Exposes a callable to set a book's personal category for the current user.
/// Usage: `ref.read(librarySetCategoryProvider)(bookId, category)`
final librarySetCategoryProvider =
    Provider<Future<void> Function(String bookId, String category)>((ref) {
  final authAsync = ref.read(authStateProvider);
  final User? user = authAsync.valueOrNull;
  final service = ref.read(libraryServiceProvider);

  return (String bookId, String category) async {
    if (user == null) throw Exception('User not authenticated');
    await service.setBookCategory(user.uid, bookId, category);
  };
});

/// Exposes a callable to remove a book from the current user's library.
/// Usage: `ref.read(libraryRemoveFromLibraryProvider)(bookId)`
final libraryRemoveFromLibraryProvider =
    Provider<Future<void> Function(String bookId)>((ref) {
  final authAsync = ref.read(authStateProvider);
  final User? user = authAsync.valueOrNull;
  final service = ref.read(libraryServiceProvider);

  return (String bookId) async {
    if (user == null) throw Exception('User not authenticated');
    await service.removeBookFromLibrary(user.uid, bookId);
  };
});
