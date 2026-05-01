import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/book_service.dart';
import '../../domain/models/book.dart';
import '../../domain/repositories/book_repository.dart';
import 'auth_provider.dart';

final bookServiceProvider = Provider<BookRepository>((ref) => BookService());

final booksStreamProvider = StreamProvider<List<Book>>((ref) {
  // Only open the Firestore stream once membership is confirmed active.
  // This prevents a permission-denied error during the brief window between
  // the router redirect and the membership check completing.
  final membershipAsync = ref.watch(membershipStatusProvider);
  final membershipState = membershipAsync.valueOrNull;

  if (membershipState == null || membershipState.status != MembershipStatus.active) {
    return const Stream.empty();
  }

  final repository = ref.watch(bookServiceProvider);
  return repository.watchBooks();
});

final bookProvider = FutureProvider.family<Book?, String>((ref, bookId) async {
  final repository = ref.watch(bookServiceProvider);
  return repository.getBook(bookId);
});

/// Real-time stream of a single book — used by [BookDetailScreen] so edits
/// are reflected immediately without needing to invalidate a FutureProvider.
final bookStreamProvider =
    StreamProvider.family<Book?, String>((ref, bookId) {
  final membershipAsync = ref.watch(membershipStatusProvider);
  final membershipState = membershipAsync.valueOrNull;

  if (membershipState == null ||
      membershipState.status != MembershipStatus.active) {
    return const Stream.empty();
  }

  final repository = ref.watch(bookServiceProvider);
  return repository.watchBook(bookId);
});
