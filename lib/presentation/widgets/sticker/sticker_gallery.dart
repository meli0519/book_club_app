import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:book_club_app/domain/models/user_sticker.dart';
import 'package:book_club_app/l10n/app_localizations.dart';
import 'package:book_club_app/presentation/providers/sticker_provider.dart';
import 'package:book_club_app/presentation/utils/image_validator.dart';

/// Maximum number of stickers a user can upload.
const int _kMaxStickers = 50;

/// Widget que muestra la galería de stickers del usuario en un grid de 3 columnas
/// y gestiona el flujo completo de subida de stickers.
///
/// Convierte la selección de imagen, validación, subida a Storage y creación
/// del documento Firestore en un flujo integrado con indicador de carga y
/// mensajes de éxito/error.
class StickerGallery extends ConsumerStatefulWidget {
  /// ID del usuario cuyos stickers se muestran.
  final String userId;

  /// Callback invocado cuando el usuario toca el botón de eliminar de un sticker.
  final void Function(UserSticker sticker)? onDeleteTap;

  const StickerGallery({
    required this.userId,
    this.onDeleteTap,
    super.key,
  });

  @override
  ConsumerState<StickerGallery> createState() => _StickerGalleryState();
}

class _StickerGalleryState extends ConsumerState<StickerGallery> {
  bool _isUploading = false;

  /// Handles the full sticker upload flow:
  /// 1. Open ImagePicker
  /// 2. Validate image (format, size, dimensions)
  /// 3. Check 50-sticker limit
  /// 4. Upload to Firebase Storage
  /// 5. Create Firestore document
  /// 6. Show success/error SnackBar
  Future<void> _handleUploadSticker() async {
    final l10n = AppLocalizations.of(context)!;

    // 1. Open image picker
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return; // User cancelled

    final imageFile = File(picked.path);

    // 2. Validate image
    final validationError = await ImageValidator.validateImage(imageFile);
    if (validationError != null) {
      if (mounted) {
        _showSnackBar(validationError, isError: true);
      }
      return;
    }

    // 3. Check sticker limit
    final count = await ref.read(userStickerCountProvider(widget.userId).future);
    if (count >= _kMaxStickers) {
      if (mounted) {
        _showSnackBar(l10n.stickerLimitReached(_kMaxStickers), isError: true);
      }
      return;
    }

    // 4 & 5. Upload to Storage and create Firestore document
    setState(() => _isUploading = true);
    try {
      final uploadService = ref.read(stickerUploadServiceProvider);
      final stickerService = ref.read(userStickerServiceProvider);

      // Upload image to Firebase Storage
      final downloadUrl = await uploadService.uploadSticker(imageFile, widget.userId);

      // Create UserSticker document in Firestore
      final sticker = UserSticker(
        id: '',
        userId: widget.userId,
        imageUrl: downloadUrl,
        uploadedAt: DateTime.now(),
      );
      await stickerService.createSticker(sticker);

      // 6. Show success
      if (mounted) {
        _showSnackBar(l10n.stickerUploadSuccess, isError: false);
      }
    } catch (e) {
      // Upload failed — do NOT create Firestore document (already handled above)
      if (mounted) {
        _showSnackBar(l10n.stickerUploadError, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Handles the full sticker deletion flow:
  /// 1. Show confirmation dialog
  /// 2. If confirmed, call UserStickerService.deleteSticker()
  /// 3. Show success/error SnackBar
  Future<void> _handleDeleteSticker(UserSticker sticker) async {
    final l10n = AppLocalizations.of(context)!;

    // 1. Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteStickerConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 2. Delete sticker via service
    try {
      await ref
          .read(userStickerServiceProvider)
          .deleteSticker(widget.userId, sticker.id, sticker.imageUrl);

      // 3. Show success SnackBar
      if (mounted) {
        _showSnackBar(l10n.stickerDeleteSuccess, isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(l10n.stickerUploadError, isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stickersAsync = ref.watch(userStickersStreamProvider(widget.userId));

    return Column(
      children: [
        // Upload button at the top
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _handleUploadSticker,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate),
              label: Text(
                _isUploading ? '...' : l10n.uploadStickerButton,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),

        // Grid of stickers or empty state
        Expanded(
          child: stickersAsync.when(
            data: (stickers) {
              if (stickers.isEmpty) {
                return _EmptyState(message: l10n.noStickersMessage);
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: stickers.length,
                itemBuilder: (context, index) {
                  final sticker = stickers[index];
                  return _StickerGridItem(
                    sticker: sticker,
                    onDeleteTap: () => _handleDeleteSticker(sticker),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Estado vacío mostrado cuando el usuario no tiene stickers.
class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_emotions_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Elemento individual del grid: imagen 150×150 con botón de eliminar superpuesto.
class _StickerGridItem extends StatelessWidget {
  final UserSticker sticker;

  /// Callback invocado al tocar el botón de eliminar. Si es null, el botón se deshabilita.
  final VoidCallback? onDeleteTap;

  const _StickerGridItem({
    required this.sticker,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sticker image
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: sticker.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),

          // Delete button (trash icon) in the top-right corner
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                onPressed: onDeleteTap,
                tooltip: 'Delete sticker',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
