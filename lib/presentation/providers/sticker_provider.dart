import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_club_app/data/services/sticker_upload_service.dart';
import 'package:book_club_app/data/services/user_sticker_service.dart';
import 'package:book_club_app/domain/models/user_sticker.dart';

/// Provider para el servicio de subida de stickers.
final stickerUploadServiceProvider = Provider<StickerUploadService>((ref) {
  return StickerUploadService();
});

/// Provider para el servicio de gestión de stickers de usuario.
final userStickerServiceProvider = Provider<UserStickerService>((ref) {
  return UserStickerService();
});

/// Provider que observa los stickers de un usuario en tiempo real.
/// 
/// [userId] - ID del usuario cuyos stickers se quieren observar
final userStickersStreamProvider =
    StreamProvider.family<List<UserSticker>, String>((ref, userId) {
  final service = ref.watch(userStickerServiceProvider);
  return service.watchUserStickers(userId);
});

/// Provider que obtiene la cantidad de stickers de un usuario.
/// 
/// [userId] - ID del usuario
final userStickerCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.read(userStickerServiceProvider);
  return service.getUserStickerCount(userId);
});
