import 'package:cloud_firestore/cloud_firestore.dart';

/// A single personal note/comment entry for a personal book.
class PersonalNote {
  final String text;
  final List<String> stickers;
  final DateTime createdAt;

  const PersonalNote({
    required this.text,
    this.stickers = const [],
    required this.createdAt,
  });

  factory PersonalNote.fromMap(Map<String, dynamic> map) {
    return PersonalNote(
      text: map['text'] as String? ?? '',
      stickers: map['stickers'] != null
          ? List<String>.from(map['stickers'] as List)
          : [],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      if (stickers.isNotEmpty) 'stickers': stickers,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
