import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/models/book.dart';
import '../../domain/repositories/book_repository.dart';

class BookService implements BookRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const _booksCollection = 'books';
  static const _meetingsCollection = 'meetings';

  @override
  Stream<List<Book>> watchBooks() {
    try {
      return _firestore
          .collection(_booksCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) {
                  try {
                    return Book.fromMap(doc.data(), doc.id);
                  } catch (e) {
                    print('Error parsing book ${doc.id}: $e');
                    rethrow;
                  }
                })
                .toList(),
          )
          .handleError((error) {
            print('Error in watchBooks stream: $error');
            throw Exception('Error watching books: $error');
          });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error watching books: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching books: $e');
    }
  }

  @override
  Future<Book?> getBook(String bookId) async {
    try {
      final doc =
          await _firestore.collection(_booksCollection).doc(bookId).get();
      if (!doc.exists) return null;
      return Book.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Error getting book: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting book: $e');
    }
  }

  @override
  Stream<Book?> watchBook(String bookId) {
    try {
      return _firestore
          .collection(_booksCollection)
          .doc(bookId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        return Book.fromMap(doc.data()!, doc.id);
      }).handleError((error) {
        print('Error in watchBook stream: $error');
        throw Exception('Error watching book: $error');
      });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error watching book: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching book: $e');
    }
  }

  @override
  Future<String> createBook(
    Book book,
    Uint8List coverImageBytes,
    String coverFileName,
  ) async {
    try {
      final docRef = _firestore.collection(_booksCollection).doc();
      final bookId = docRef.id;

      // Upload cover image to Storage
      final storageRef = _storage.ref('covers/$bookId/$coverFileName');
      await storageRef.putData(coverImageBytes);
      final coverUrl = await storageRef.getDownloadURL();

      // Save book document with coverUrl and status='reading'
      await docRef.set({
        ...book.toMap(),
        'coverUrl': coverUrl,
        'status': 'reading',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      return bookId;
    } on FirebaseException catch (e) {
      throw Exception('Error creating book: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error creating book: $e');
    }
  }

  @override
  Future<void> updateBook(String bookId, Map<String, dynamic> fields) async {
    try {
      await _firestore.collection(_booksCollection).doc(bookId).update(fields);
    } on FirebaseException catch (e) {
      throw Exception('Error updating book: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating book: $e');
    }
  }

  @override
  Future<void> deleteBook(String bookId) async {
    try {
      // Get book to find cover URL
      final doc =
          await _firestore.collection(_booksCollection).doc(bookId).get();
      if (doc.exists) {
        final coverUrl = doc.data()?['coverUrl'] as String?;
        if (coverUrl != null && coverUrl.isNotEmpty) {
          try {
            final storageRef = _storage.refFromURL(coverUrl);
            await storageRef.delete();
          } on FirebaseException {
            // Continue deletion even if cover removal fails
          }
        }
      }

      // Delete all meetings associated with this book
      final meetingsSnapshot = await _firestore
          .collection(_meetingsCollection)
          .where('bookId', isEqualTo: bookId)
          .get();

      final batch = _firestore.batch();
      for (final meetingDoc in meetingsSnapshot.docs) {
        batch.delete(meetingDoc.reference);
      }
      batch.delete(_firestore.collection(_booksCollection).doc(bookId));
      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception('Error deleting book: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error deleting book: $e');
    }
  }

  @override
  Future<void> markAsRead(String bookId) async {
    try {
      await _firestore.collection(_booksCollection).doc(bookId).update({
        'status': 'read',
        'finishedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw Exception('Error marking book as read: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error marking book as read: $e');
    }
  }

  @override
  Future<String> uploadCover(
    String bookId,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final storageRef = _storage.ref('covers/$bookId/$fileName');
      await storageRef.putData(bytes);
      return storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Error uploading cover: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error uploading cover: $e');
    }
  }
}
