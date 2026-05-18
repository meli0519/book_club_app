import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String authorId;
  final String authorName;
  final String text; // 1-1000 chars
  final List<String> stickers; // 0-5 IDs de StickerCatalog; default []
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.stickers = const [],
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      authorId: map['authorId'] as String,
      authorName: map['authorName'] as String,
      text: map['text'] as String,
      // IDs desconocidos se incluyen tal cual; StickerDisplay los ignora.
      stickers: map['stickers'] != null
          ? List<String>.from(map['stickers'] as List)
          : [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'text': text,
      if (stickers.isNotEmpty) 'stickers': stickers,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
