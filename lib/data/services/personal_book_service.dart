import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/models/personal_book.dart';
import '../../domain/models/personal_note.dart';

/// Service for managing a user's private personal book collection.
///
/// Firestore path: `users/{uid}/personal_books/{bookId}`
/// Storage path:   `personal_books/{uid}/{bookId}/cover`
class PersonalBookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const _usersCollection = 'users';
  static const _personalBooksSubcollection = 'personal_books';

  CollectionReference<Map<String, dynamic>> _personalBooksRef(String uid) =>
      _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(_personalBooksSubcollection);

  // ---------------------------------------------------------------------------
  // Streams (real-time)
  // ---------------------------------------------------------------------------

  /// Watches all personal books for [uid], ordered by [updatedAt] descending.
  Stream<List<PersonalBook>> watchPersonalBooks(String uid) {
    try {
      return _personalBooksRef(uid)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => PersonalBook.fromMap(doc.data(), doc.id, uid))
                .toList(),
          )
          .handleError((error) {
            throw Exception('Error watching personal books: $error');
          });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error watching personal books: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching personal books: $e');
    }
  }

  /// Watches personal books for [uid] filtered by [status].
  Stream<List<PersonalBook>> watchPersonalBooksByStatus(
    String uid,
    String status,
  ) {
    try {
      return _personalBooksRef(uid)
          .where('status', isEqualTo: status)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => PersonalBook.fromMap(doc.data(), doc.id, uid))
                .toList(),
          )
          .handleError((error) {
            throw Exception(
              'Error watching personal books by status: $error',
            );
          });
    } on FirebaseException catch (e) {
      throw Exception(
        'Firebase error watching personal books by status: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Unexpected error watching personal books by status: $e',
      );
    }
  }

  /// Watches a single personal book document for [uid] and [bookId].
  Stream<PersonalBook?> watchPersonalBook(String uid, String bookId) {
    try {
      return _personalBooksRef(uid)
          .doc(bookId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            return PersonalBook.fromMap(doc.data()!, doc.id, uid);
          })
          .handleError((error) {
            throw Exception('Error watching personal book: $error');
          });
    } on FirebaseException catch (e) {
      throw Exception('Firebase error watching personal book: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching personal book: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Single reads
  // ---------------------------------------------------------------------------

  /// Returns a single [PersonalBook] by [bookId], or `null` if not found.
  Future<PersonalBook?> getPersonalBook(String uid, String bookId) async {
    try {
      final doc = await _personalBooksRef(uid).doc(bookId).get();
      if (!doc.exists) return null;
      return PersonalBook.fromMap(doc.data()!, doc.id, uid);
    } on FirebaseException catch (e) {
      throw Exception('Error getting personal book: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting personal book: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Creates a new personal book for [uid].
  ///
  /// If [imageBytes] is provided, the cover is uploaded to Storage first and
  /// the resulting URL is stored in the document's `coverUrl` field.
  ///
  /// Returns the generated [bookId].
  Future<String> createPersonalBook(
    String uid,
    PersonalBook book,
    Uint8List? imageBytes,
    String? imageFileName,
  ) async {
    try {
      final docRef = _personalBooksRef(uid).doc();
      final bookId = docRef.id;

      String? coverUrl;
      if (imageBytes != null && imageFileName != null) {
        coverUrl = await uploadCover(uid, bookId, imageBytes, imageFileName);
      }

      final now = Timestamp.now();
      await docRef.set({
        ...book.toMap(),
        if (coverUrl != null) 'coverUrl': coverUrl,
        'createdAt': now,
        'updatedAt': now,
      });

      return bookId;
    } on FirebaseException catch (e) {
      throw Exception('Error creating personal book: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error creating personal book: $e');
    }
  }

  /// Updates only the fields in [fields] plus `updatedAt` for [bookId].
  ///
  /// Handles status-transition timestamp logic automatically:
  /// - When [fields] contains `status == 'read'`, sets `finishedAt` to now.
  /// - When [fields] contains `status == 'reading'` and the document does not
  ///   already have a `startedAt` value, sets `startedAt` to now.
  Future<void> updatePersonalBook(
    String uid,
    String bookId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final extraFields = <String, dynamic>{};

      final newStatus = fields['status'] as String?;
      if (newStatus == PersonalBookStatus.read) {
        // Always record finishedAt when transitioning to 'read'.
        extraFields['finishedAt'] = Timestamp.now();
      } else if (newStatus == PersonalBookStatus.reading) {
        // Only set startedAt if it does not already exist in the document.
        final doc = await _personalBooksRef(uid).doc(bookId).get();
        final existingStartedAt = doc.data()?['startedAt'];
        if (existingStartedAt == null) {
          extraFields['startedAt'] = Timestamp.now();
        }
      }

      await _personalBooksRef(uid).doc(bookId).update({
        ...fields,
        ...extraFields,
        'updatedAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Error updating personal book: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating personal book: $e');
    }
  }

  /// Adds a new [PersonalNote] to the notes list of [bookId] for [uid].
  Future<void> addNote(String uid, String bookId, PersonalNote note) async {
    try {
      await _personalBooksRef(uid).doc(bookId).update({
        'notes': FieldValue.arrayUnion([note.toMap()]),
        'updatedAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Error adding note: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error adding note: $e');
    }
  }

  /// Removes a [PersonalNote] from the notes list of [bookId] for [uid].
  Future<void> removeNote(String uid, String bookId, PersonalNote note) async {
    try {
      await _personalBooksRef(uid).doc(bookId).update({
        'notes': FieldValue.arrayRemove([note.toMap()]),
        'updatedAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Error removing note: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error removing note: $e');
    }
  }

  /// Replaces [oldNote] with [newNote] in the notes list of [bookId] for [uid].
  ///
  /// Uses a Firestore transaction to ensure atomicity: reads the current notes
  /// array, swaps the matching entry, and writes it back.
  Future<void> updateNote(
    String uid,
    String bookId,
    PersonalNote oldNote,
    PersonalNote newNote,
  ) async {
    try {
      final docRef = _personalBooksRef(uid).doc(bookId);
      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists) return;

        final rawNotes = snapshot.data()?['notes'] as List<dynamic>? ?? [];
        final oldMap = oldNote.toMap();

        // Find the index of the note to replace by matching all fields.
        final index = rawNotes.indexWhere((n) {
          final m = Map<String, dynamic>.from(n as Map);
          return m['text'] == oldMap['text'] &&
              m['createdAt'] == oldMap['createdAt'];
        });

        if (index == -1) return; // Note not found — nothing to update.

        final updatedNotes = List<dynamic>.from(rawNotes);
        updatedNotes[index] = newNote.toMap();

        tx.update(docRef, {
          'notes': updatedNotes,
          'updatedAt': Timestamp.now(),
        });
      });
    } on FirebaseException catch (e) {
      throw Exception('Error updating note: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating note: $e');
    }
  }

  /// Deletes the personal book document and its Storage cover (if any).
  Future<void> deletePersonalBook(String uid, String bookId) async {
    try {
      // Fetch the document first to check for a cover URL.
      final doc = await _personalBooksRef(uid).doc(bookId).get();
      if (doc.exists) {
        final coverUrl = doc.data()?['coverUrl'] as String?;
        if (coverUrl != null && coverUrl.isNotEmpty) {
          try {
            final storageRef = _storage.refFromURL(coverUrl);
            await storageRef.delete();
          } on FirebaseException {
            // Log and continue — a missing cover should not block deletion.
          }
        }
      }

      await _personalBooksRef(uid).doc(bookId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Error deleting personal book: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error deleting personal book: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------------

  /// Uploads a cover image to `personal_books/{uid}/{bookId}/cover` and
  /// returns the download URL.
  Future<String> uploadCover(
    String uid,
    String bookId,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final storageRef = _storage.ref(
        '$_personalBooksSubcollection/$uid/$bookId/cover',
      );
      await storageRef.putData(bytes);
      return storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Error uploading cover: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error uploading cover: $e');
    }
  }
}
