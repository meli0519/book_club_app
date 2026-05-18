# Implementation Plan: User-Uploaded Stickers

## Overview

Transforma el sistema de stickers de un catálogo fijo a uno dinámico donde los usuarios pueden subir, gestionar y usar sus propias imágenes como stickers. Los stickers se almacenan en Firebase Storage y sus metadatos en Firestore.

---

## Tasks

- [x] 1. Create UserSticker domain model
  - Create `lib/domain/models/user_sticker.dart`
  - Define UserSticker class with: id, userId, imageUrl, uploadedAt
  - Implement `fromMap()` and `toMap()` methods for Firestore serialization
  - Add to `lib/domain/models/models.dart` barrel file
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Create StickerUploadService
  - Create `lib/data/services/sticker_upload_service.dart`
  - Implement `uploadSticker(File image, String userId)` method
  - Upload to Firebase Storage at `user_stickers/{userId}/{timestamp}_{filename}`
  - Return the download URL
  - Validate image size (≤ 2MB) before upload
  - Handle upload errors with try-catch
  - _Requirements: 2.1, 2.2, 2.3, 2.6, 2.7_

- [x] 3. Create UserStickerService
  - Create `lib/data/services/user_sticker_service.dart`
  - Implement `createSticker(UserSticker sticker)` - creates Firestore document
  - Implement `watchUserStickers(String userId)` - returns Stream<List<UserSticker>>
  - Implement `deleteSticker(String userId, String stickerId, String imageUrl)` - deletes from Firestore and Storage
  - Implement `getUserStickerCount(String userId)` - returns count for limit validation
  - Order stickers by uploadedAt descending
  - _Requirements: 3.1, 3.2, 4.2, 4.3, 7.1_

- [x] 4. Add image validation utility
  - Create `lib/presentation/utils/image_validator.dart`
  - Implement `validateImageSize(File image)` - checks ≤ 2MB
  - Implement `validateImageDimensions(File image)` - checks 100×100 to 1024×1024
  - Implement `validateImageFormat(File image)` - checks PNG, JPG, WebP
  - Return validation errors as strings
  - _Requirements: 2.3, 2.4, 7.2, 7.3, 7.4_

- [x] 5. Create StickerGallery widget
  - Create `lib/presentation/widgets/sticker/sticker_gallery.dart`
  - Display grid of user's stickers (3 columns, 150×150px each)
  - Show "Upload New Sticker" button at top
  - Show delete button (trash icon) on each sticker
  - Show empty state message when no stickers
  - Use StreamBuilder with `watchUserStickers()`
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 6. Implement sticker upload flow in StickerGallery
  - Add `_handleUploadSticker()` method
  - Open ImagePicker when "Upload" button tapped
  - Validate image (size, dimensions, format)
  - Check user hasn't reached 50 sticker limit
  - Show loading indicator during upload
  - Call StickerUploadService to upload to Storage
  - Call UserStickerService to create Firestore document
  - Show success/error SnackBar
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 7.1, 7.2_

- [x] 7. Implement sticker deletion in StickerGallery
  - Add `_handleDeleteSticker(UserSticker sticker)` method
  - Show confirmation dialog "¿Eliminar este sticker?"
  - If confirmed, call UserStickerService.deleteSticker()
  - Show success/error SnackBar
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 8. Modify StickerPicker to load user stickers
  - Edit `lib/presentation/widgets/comment/sticker_picker.dart`
  - Replace StickerCatalog with StreamBuilder<List<UserSticker>>
  - Load stickers from UserStickerService.watchUserStickers()
  - Display user's uploaded stickers in grid
  - Keep existing selection logic (max 5 stickers)
  - Store imageUrl instead of ID when confirming selection
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 9. Modify StickerDisplay to handle URLs
  - Edit `lib/presentation/widgets/comment/sticker_display.dart`
  - Check if sticker string starts with "http" (URL) or is legacy ID
  - If URL: use `Image.network(url)` with error placeholder
  - If legacy ID: use `Image.asset(StickerCatalog.all[id])` (backward compatibility)
  - Add `cached_network_image` package for better performance
  - Show placeholder icon if image fails to load
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 10.1, 10.2, 10.3, 10.4_

- [x] 10. Update Comment model (already supports List<String>)
  - Verify Comment.stickers field accepts URLs (it does - it's List<String>)
  - No changes needed - backward compatible
  - _Requirements: 5.5, 10.1_

- [x] 11. Create Riverpod providers
  - Create `lib/presentation/providers/sticker_provider.dart`
  - Add `stickerUploadServiceProvider`
  - Add `userStickerServiceProvider`
  - Add `userStickersStreamProvider(userId)` - returns Stream<List<UserSticker>>
  - Add `userStickerCountProvider(userId)` - returns Future<int>

- [x] 12. Add Firebase Storage security rules
  - Edit `storage.rules` (or create if doesn't exist)
  - Add rules for `user_stickers/{userId}/{allPaths=**}`
  - Allow read/write only if request.auth.uid == userId
  - Validate file size ≤ 2MB
  - Validate content type is image/png, image/jpeg, or image/webp
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [x] 13. Add Firestore security rules
  - Edit `firestore.rules`
  - Add rules for `user_stickers/{userId}/stickers/{stickerId}`
  - Allow read/write only if request.auth.uid == userId
  - Validate userId field matches request.auth.uid
  - _Requirements: 9.1, 9.2, 9.3_

- [x] 14. Add i18n strings
  - Edit `lib/l10n/app_es.arb` and `lib/l10n/app_en.arb`
  - Add keys:
    - `stickerGalleryTitle` - "Mis Stickers" / "My Stickers"
    - `uploadStickerButton` - "Subir Sticker" / "Upload Sticker"
    - `noStickersMessage` - "No tienes stickers. ¡Sube tu primer sticker!" / "No stickers yet. Upload your first sticker!"
    - `deleteStickerConfirm` - "¿Eliminar este sticker?" / "Delete this sticker?"
    - `stickerLimitReached` - "Has alcanzado el límite de 50 stickers" / "You've reached the limit of 50 stickers"
    - `stickerUploadSuccess` - "Sticker subido exitosamente" / "Sticker uploaded successfully"
    - `stickerUploadError` - "Error al subir sticker" / "Error uploading sticker"
    - `stickerDeleteSuccess` - "Sticker eliminado" / "Sticker deleted"
    - `imageTooLarge` - "La imagen debe ser menor a 2MB" / "Image must be less than 2MB"
    - `invalidImageDimensions` - "Las dimensiones deben estar entre 100×100 y 1024×1024" / "Dimensions must be between 100×100 and 1024×1024"
    - `invalidImageFormat` - "Formato no válido. Usa PNG, JPG o WebP" / "Invalid format. Use PNG, JPG or WebP"

- [x] 15. Add cached_network_image dependency
  - Edit `pubspec.yaml`
  - Add `cached_network_image: ^3.3.0` to dependencies
  - Run `flutter pub get`

- [x] 16. Create sticker management screen
  - Create `lib/presentation/screens/stickers/sticker_management_screen.dart`
  - Use StickerGallery widget as main content
  - Add AppBar with title "Mis Stickers"
  - Add navigation route in app_router.dart
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 17. Add navigation to sticker management
  - Add menu item or button in user profile/settings to access sticker management
  - Route: `/stickers/manage`

- [x] 18. Test and verify
  - Test uploading stickers (various formats and sizes)
  - Test sticker limit (50 max)
  - Test deleting stickers
  - Test using stickers in comments
  - Test backward compatibility with old sticker IDs
  - Verify Firebase rules work correctly
  - Test on both Android and iOS

---

## Migration Notes

### Backward Compatibility

The new system is designed to be backward compatible:

1. **Old comments with sticker IDs** (e.g., `["sticker_heart", "sticker_fire"]`) will continue to work
2. **StickerDisplay** checks if string starts with "http":
   - If yes → load from URL (new system)
   - If no → load from assets using StickerCatalog (old system)
3. **No data migration needed** - old comments work as-is

### Deprecation Path

1. Keep `StickerCatalog` for backward compatibility
2. Keep asset stickers in `assets/stickers/` for old comments
3. Eventually, old sticker IDs can be migrated to URLs via a background job (optional)

---

## Dependencies

```yaml
dependencies:
  cached_network_image: ^3.3.0  # For efficient image loading and caching
  image_picker: ^1.1.2          # Already in project
  firebase_storage: ^12.3.2     # Already in project
```

---

## Firebase Rules

### storage.rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User stickers
    match /user_stickers/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId
                         && request.resource.size <= 2 * 1024 * 1024  // 2MB
                         && request.resource.contentType.matches('image/(png|jpeg|webp)');
    }
  }
}
```

### firestore.rules (add to existing)

```
match /user_stickers/{userId}/stickers/{stickerId} {
  allow read, write: if request.auth != null 
                     && request.auth.uid == userId
                     && request.resource.data.userId == request.auth.uid;
}
```
