import 'package:cloud_firestore/cloud_firestore.dart';

class Membership {
  final String userId;
  final String status; // 'pending' | 'active' | 'rejected'
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final String? approvedBy;

  const Membership({
    required this.userId,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.approvedBy,
  });

  factory Membership.fromMap(Map<String, dynamic> map, String id) {
    return Membership(
      userId: map['userId'] as String,
      status: map['status'] as String,
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      approvedBy: map['approvedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (approvedBy != null) 'approvedBy': approvedBy,
    };
  }
}
