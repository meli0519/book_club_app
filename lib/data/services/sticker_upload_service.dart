import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Servicio para subir imágenes de stickers a Firebase Storage.
class StickerUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube una imagen de sticker a Firebase Storage.
  /// 
  /// Retorna la URL de descarga del sticker subido.
  /// Lanza excepción si la subida falla.
  /// 
  /// [image] - Archivo de imagen a subir
  /// [userId] - ID del usuario que sube el sticker
  Future<String> uploadSticker(File image, String userId) async {
    try {
      // Validar tamaño del archivo (≤ 2MB)
      final fileSize = await image.length();
      if (fileSize > 2 * 1024 * 1024) {
        throw Exception('La imagen debe ser menor a 2MB');
      }

      // Generar nombre único para el archivo usando el nombre original
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final basename = path.basename(image.path);
      final extension = path.extension(image.path);
      final fileName = '${timestamp}_$basename';

      // Ruta en Storage: user_stickers/{userId}/{fileName}
      final storageRef = _storage.ref().child('user_stickers/$userId/$fileName');

      // Subir archivo
      final uploadTask = storageRef.putFile(
        image,
        SettableMetadata(
          contentType: _getContentType(extension),
        ),
      );

      // Esperar a que termine la subida
      final snapshot = await uploadTask;

      // Obtener URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Error al subir sticker a Storage: ${e.message}');
      throw Exception('Error al subir sticker: ${e.message}');
    } catch (e) {
      print('Error inesperado al subir sticker: $e');
      throw Exception('Error al subir sticker');
    }
  }

  /// Elimina una imagen de sticker de Firebase Storage.
  /// 
  /// [imageUrl] - URL completa del sticker a eliminar
  Future<void> deleteSticker(String imageUrl) async {
    try {
      // Obtener referencia desde la URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      print('Error al eliminar sticker de Storage: ${e.message}');
      // No lanzar excepción - el documento de Firestore se eliminará de todos modos
    } catch (e) {
      print('Error inesperado al eliminar sticker: $e');
    }
  }

  /// Determina el content type basado en la extensión del archivo.
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }
}
