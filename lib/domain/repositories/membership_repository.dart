import '../models/membership.dart';

abstract class MembershipRepository {
  Future<Membership?> getMembership(String userId);
  Future<void> requestMembership(String userId);
  Future<void> approveMembership(String userId, String approvedBy);
  Future<void> rejectMembership(String userId);
  Stream<List<Membership>> watchPendingMemberships();
}
