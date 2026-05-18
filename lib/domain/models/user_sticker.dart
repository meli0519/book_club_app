import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa un sticker subido por un usuario.
/// Los stickers se almacenan en Firebase Storage y sus metadatos en Firestore.
class UserSticker {
  final String id;
  final String userId;
  final String imageUrl; // Firebase Storage download URL
  final DateTime uploadedAt;

  const UserSticker({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.uploadedAt,
  });

  factory UserSticker.fromMap(Map<String, dynamic> map, String id) {
    return UserSticker(
      id: id,
      userId: map['userId'] as String,
      imageUrl: map['imageUrl'] as String,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSticker &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ imageUrl.hashCode;
}
