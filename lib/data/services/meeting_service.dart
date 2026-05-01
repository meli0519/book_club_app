import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/meeting.dart';
import '../../domain/repositories/meeting_repository.dart';

class MeetingService implements MeetingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _meetingsCollection = 'meetings';

  /// Returns a stream of meetings for a book, ordered by date ascending.
  /// Requirement 6.5
  Stream<List<Meeting>> watchMeetings(String bookId) {
    try {
      return _firestore
          .collection(_meetingsCollection)
          .where('bookId', isEqualTo: bookId)
          .orderBy('date', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Meeting.fromMap(doc.data(), doc.id))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw Exception('Error watching meetings: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching meetings: $e');
    }
  }

  Future<Meeting?> getMeeting(String meetingId) async {
    try {
      final doc = await _firestore
          .collection(_meetingsCollection)
          .doc(meetingId)
          .get();
      if (!doc.exists) return null;
      return Meeting.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Error getting meeting: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting meeting: $e');
    }
  }

  Future<String> createMeeting(Meeting meeting) async {
    try {
      final docRef = _firestore.collection(_meetingsCollection).doc();
      await docRef.set({
        ...meeting.toMap(),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Error creating meeting: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error creating meeting: $e');
    }
  }

  Future<void> updateMeeting(
    String meetingId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _firestore
          .collection(_meetingsCollection)
          .doc(meetingId)
          .update(fields);
    } on FirebaseException catch (e) {
      throw Exception('Error updating meeting: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating meeting: $e');
    }
  }

  Future<void> deleteMeeting(String meetingId) async {
    try {
      await _firestore
          .collection(_meetingsCollection)
          .doc(meetingId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception('Error deleting meeting: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error deleting meeting: $e');
    }
  }
}
