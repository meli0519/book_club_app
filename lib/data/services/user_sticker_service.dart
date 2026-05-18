import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:book_club_app/domain/models/user_sticker.dart';
import 'package:book_club_app/data/services/sticker_upload_service.dart';

/// Servicio para gestionar los metadatos de stickers en Firestore.
class UserStickerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StickerUploadService _uploadService = StickerUploadService();

  /// Crea un nuevo sticker en Firestore.
  /// 
  /// [sticker] - Sticker a crear (sin ID, se genera automáticamente)
  Future<String> createSticker(UserSticker sticker) async {
    try {
      final docRef = await _firestore
          .collection('user_stickers')
          .doc(sticker.userId)
          .collection('stickers')
          .add(sticker.toMap());

      return docRef.id;
    } on FirebaseException catch (e) {
      print('Error al crear sticker en Firestore: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al crear sticker: $e');
      rethrow;
    }
  }

  /// Observa los stickers de un usuario en tiempo real.
  /// 
  /// Retorna un Stream que emite la lista de stickers ordenados por fecha (más recientes primero).
  /// 
  /// [userId] - ID del usuario
  Stream<List<UserSticker>> watchUserStickers(String userId) {
    try {
      return _firestore
          .collection('user_stickers')
          .doc(userId)
          .collection('stickers')
          .orderBy('uploadedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => UserSticker.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      print('Error al observar stickers del usuario: $e');
      rethrow;
    }
  }

  /// Obtiene la cantidad de stickers de un usuario.
  /// 
  /// [userId] - ID del usuario
  Future<int> getUserStickerCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_stickers')
          .doc(userId)
          .collection('stickers')
          .count()
          .get();

      return snapshot.count ?? 0;
    } on FirebaseException catch (e) {
      print('Error al obtener cantidad de stickers: ${e.message}');
      return 0;
    } catch (e) {
      print('Error inesperado al obtener cantidad de stickers: $e');
      return 0;
    }
  }

  /// Elimina un sticker (tanto de Firestore como de Storage).
  /// 
  /// [userId] - ID del usuario propietario del sticker
  /// [stickerId] - ID del documento del sticker en Firestore
  /// [imageUrl] - URL de la imagen en Storage
  Future<void> deleteSticker(
    String userId,
    String stickerId,
    String imageUrl,
  ) async {
    try {
      // Eliminar imagen de Storage primero
      await _uploadService.deleteSticker(imageUrl);

      // Eliminar documento de Firestore
      await _firestore
          .collection('user_stickers')
          .doc(userId)
          .collection('stickers')
          .doc(stickerId)
          .delete();
    } on FirebaseException catch (e) {
      print('Error al eliminar sticker: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al eliminar sticker: $e');
      rethrow;
    }
  }

  /// Obtiene todos los stickers de un usuario (una sola vez, no stream).
  /// 
  /// [userId] - ID del usuario
  Future<List<UserSticker>> getUserStickers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_stickers')
          .doc(userId)
          .collection('stickers')
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserSticker.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      print('Error al obtener stickers del usuario: ${e.message}');
      return [];
    } catch (e) {
      print('Error inesperado al obtener stickers: $e');
      return [];
    }
  }
}
