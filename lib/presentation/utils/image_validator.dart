import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

/// Utilidad para validar imágenes antes de subirlas como stickers.
class ImageValidator {
  /// Tamaño máximo permitido: 2MB
  static const int maxSizeBytes = 2 * 1024 * 1024;

  /// Dimensión mínima permitida: 100×100 píxeles
  static const int minDimension = 100;

  /// Dimensión máxima permitida: 1024×1024 píxeles
  static const int maxDimension = 1024;

  /// Formatos permitidos
  static const List<String> allowedExtensions = ['.png', '.jpg', '.jpeg', '.webp'];

  /// Valida el tamaño del archivo.
  ///
  /// Retorna null si es válido, o un mensaje de error si excede el límite.
  static Future<String?> validateImageSize(File image) async {
    try {
      final fileSize = await image.length();
      if (fileSize > maxSizeBytes) {
        return 'La imagen debe ser menor a 2MB';
      }
      return null;
    } catch (e) {
      return 'Error al validar tamaño de imagen';
    }
  }

  /// Valida las dimensiones de la imagen.
  ///
  /// Retorna null si es válido, o un mensaje de error si las dimensiones no son apropiadas.
  static Future<String?> validateImageDimensions(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        return 'No se pudo leer la imagen';
      }

      final width = decodedImage.width;
      final height = decodedImage.height;

      if (width < minDimension ||
          height < minDimension ||
          width > maxDimension ||
          height > maxDimension) {
        return 'Las dimensiones deben estar entre 100×100 y 1024×1024';
      }

      return null;
    } catch (e) {
      return 'Error al validar dimensiones de imagen';
    }
  }

  /// Valida el formato de la imagen basándose en la extensión del archivo.
  ///
  /// Retorna null si es válido, o un mensaje de error si el formato no es permitido.
  static String? validateImageFormat(File image) {
    final extension = path.extension(image.path).toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      return 'Formato no válido. Usa PNG, JPG o WebP';
    }

    return null;
  }

  /// Valida todos los aspectos de la imagen (formato, tamaño y dimensiones).
  ///
  /// Retorna null si todo es válido, o el primer mensaje de error encontrado.
  static Future<String?> validateImage(File image) async {
    final formatError = validateImageFormat(image);
    if (formatError != null) return formatError;

    final sizeError = await validateImageSize(image);
    if (sizeError != null) return sizeError;

    final dimensionsError = await validateImageDimensions(image);
    if (dimensionsError != null) return dimensionsError;

    return null;
  }
}
