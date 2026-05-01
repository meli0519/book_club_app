import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/book.dart';
import '../../domain/models/user_book_entry.dart';

/// Service for managing a user's personal book library.
/// Firestore path: users/{userId}/library/{bookId}
class LibraryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _usersCollection = 'users';
  static const _librarySubcollection = 'library';

  CollectionReference<Map<String, dynamic>> _libraryRef(String userId) =>
      _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_librarySubcollection);

  /// Watches all personal book entries for a user in real time.
  Stream<List<UserBookEntry>> watchUserLibrary(String userId) {
    try {
      return _libraryRef(userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserBookEntry.fromMap(doc.data(), doc.id, userId))
                .toList(),
          )
          .handleError((error) {
            throw Exception('Error watching user library: $error');
          });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error watching library: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching library: $e');
    }
  }

  /// Adds or updates a book's personal category for the user.
  Future<void> setBookCategory(
    String userId,
    String bookId,
    String category,
  ) async {
    try {
      await _libraryRef(userId).doc(bookId).set({
        'category': category,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception('Error setting book category: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error setting book category: $e');
    }
  }

  /// Removes a book from the user's personal library.
  Future<void> removeBookFromLibrary(String userId, String bookId) async {
    try {
      await _libraryRef(userId).doc(bookId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Error removing book from library: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error removing book from library: $e');
    }
  }

  /// Watches library entries for a specific [category] and joins each entry
  /// with its full [Book] document and average rating from Firestore.
  /// Books that no longer exist in the `books` collection are silently skipped.
  Stream<List<UserBookWithDetails>> watchLibraryByCategory(
    String userId,
    String category,
  ) {
    try {
      return _libraryRef(userId)
          .where('category', isEqualTo: category)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final entries = snapshot.docs
            .map((doc) => UserBookEntry.fromMap(doc.data(), doc.id, userId))
            .toList();

        final results = <UserBookWithDetails>[];
        for (final entry in entries) {
          try {
            final bookDoc = await _firestore
                .collection('books')
                .doc(entry.bookId)
                .get();
            if (!bookDoc.exists) continue;

            final book = Book.fromMap(bookDoc.data()!, bookDoc.id);
            final avgRating = await _fetchAverageRating(entry.bookId);

            results.add(
              UserBookWithDetails(
                entry: entry,
                book: book,
                averageRating: avgRating,
              ),
            );
          } catch (_) {
            // Skip entries whose book data cannot be fetched
          }
        }
        return results;
      });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error watching library by category: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching library by category: $e');
    }
  }

  Future<double?> _fetchAverageRating(String bookId) async {
    try {
      final snapshot = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('ratings')
          .get();
      if (snapshot.docs.isEmpty) return null;
      final values = snapshot.docs
          .map((doc) => (doc.data()['value'] as num).toDouble())
          .toList();
      final avg = values.reduce((a, b) => a + b) / values.length;
      return (avg * 10).round() / 10;
    } catch (_) {
      return null;
    }
  }
}
