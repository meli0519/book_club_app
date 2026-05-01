import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/membership.dart';
import '../../domain/repositories/membership_repository.dart';

class MembershipService implements MembershipRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _collection = 'memberships';

  /// Get membership document for a given user.
  /// Returns null if no membership exists.
  @override
  Future<Membership?> getMembership(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return null;
      return Membership.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Error getting membership: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting membership: $e');
    }
  }

  /// Create a membership request with status 'pending'.
  /// Requirement 10.1: creates document with userId, status='pending', requestedAt.
  @override
  Future<void> requestMembership(String userId) async {
    try {
      final membership = Membership(
        userId: userId,
        status: 'pending',
        requestedAt: DateTime.now(),
      );
      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(membership.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Error requesting membership: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error requesting membership: $e');
    }
  }

  /// Approve a pending membership.
  /// Requirement 10.2 / 2.2: updates status to 'active', records approvedAt and approvedBy.
  @override
  Future<void> approveMembership(String userId, String approvedBy) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'status': 'active',
        'approvedAt': Timestamp.fromDate(DateTime.now()),
        'approvedBy': approvedBy,
      });
    } on FirebaseException catch (e) {
      throw Exception('Error approving membership: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error approving membership: $e');
    }
  }

  /// Reject or remove a membership.
  /// Requirement 10.3: updates status to 'rejected'.
  @override
  Future<void> rejectMembership(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'status': 'rejected',
      });
    } on FirebaseException catch (e) {
      throw Exception('Error rejecting membership: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error rejecting membership: $e');
    }
  }

  /// Stream of all memberships with status 'pending'.
  @override
  Stream<List<Membership>> watchPendingMemberships() {
    try {
      return _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Membership.fromMap(doc.data(), doc.id))
              .toList());
    } on FirebaseException catch (e) {
      throw Exception('Error watching pending memberships: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching pending memberships: $e');
    }
  }

  /// Stream of all memberships (all statuses).
  /// Used for user management by leaders.
  Stream<List<Membership>> watchAllMemberships() {
    try {
      return _firestore
          .collection(_collection)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Membership.fromMap(doc.data(), doc.id))
              .toList());
    } on FirebaseException catch (e) {
      throw Exception('Error watching all memberships: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching all memberships: $e');
    }
  }

  /// Deactivate a membership by setting status to 'rejected'.
  /// This is the same as rejectMembership but with a clearer name for deactivation.
  Future<void> deactivateMembership(String userId) async {
    await rejectMembership(userId);
  }

  /// Reactivate a membership by setting status back to 'active'.
  Future<void> reactivateMembership(String userId, String approvedBy) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'status': 'active',
        'approvedAt': Timestamp.fromDate(DateTime.now()),
        'approvedBy': approvedBy,
      });
    } on FirebaseException catch (e) {
      throw Exception('Error reactivating membership: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error reactivating membership: $e');
    }
  }
}
