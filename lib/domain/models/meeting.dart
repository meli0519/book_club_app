import 'package:cloud_firestore/cloud_firestore.dart';

class Meeting {
  final String id;
  final String bookId;
  final DateTime date;
  final String notes;
  final String createdBy;
  final DateTime createdAt;

  const Meeting({
    required this.id,
    required this.bookId,
    required this.date,
    required this.notes,
    required this.createdBy,
    required this.createdAt,
  });

  factory Meeting.fromMap(Map<String, dynamic> map, String id) {
    return Meeting(
      id: id,
      bookId: map['bookId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
