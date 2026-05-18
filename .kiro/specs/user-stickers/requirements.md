# Requirements Document: User-Uploaded Stickers

## Introduction

Esta feature permite a los usuarios subir sus propias imágenes como stickers personalizados y usarlos en comentarios. Los stickers se almacenan en Firebase Storage y sus metadatos en Firestore. Cada usuario tiene su propia colección de stickers que puede gestionar (subir, ver, eliminar).

---

## Glossary

- **UserSticker**: Modelo de dominio que representa un sticker subido por un usuario (ID, userId, imageUrl, uploadedAt)
- **StickerUploadService**: Servicio que maneja la subida de imágenes a Firebase Storage
- **UserStickerService**: Servicio que gestiona los metadatos de stickers en Firestore
- **StickerGallery**: Widget que muestra la galería de stickers del usuario con opción de subir nuevos
- **StickerPicker**: Widget modificado que muestra los stickers del usuario actual
- **Comment**: Modelo extendido que ahora almacena URLs de stickers en lugar de IDs fijos

---

## Requirements

### Requirement 1: Modelo de UserSticker

**User Story:** As a developer, I want a UserSticker model to represent user-uploaded stickers with their metadata.

#### Acceptance Criteria

1. THE UserSticker model SHALL contain: id (String), userId (String), imageUrl (String), uploadedAt (DateTime)
2. THE UserSticker model SHALL provide fromMap() and toMap() methods for Firestore serialization
3. THE imageUrl field SHALL contain the Firebase Storage download URL
4. THE userId field SHALL match the authenticated user's UID

---

### Requirement 2: Subida de Stickers

**User Story:** As a user, I want to upload my own images as stickers, so that I can personalize my comments.

#### Acceptance Criteria

1. WHEN a user taps "Upload Sticker", THE app SHALL open the image picker
2. THE app SHALL accept PNG, JPG, and WebP formats
3. THE app SHALL validate that the image size is ≤ 2MB
4. THE app SHALL validate that the image dimensions are between 100×100 and 1024×1024 pixels
5. WHEN an image is selected, THE app SHALL upload it to Firebase Storage at `user_stickers/{userId}/{timestamp}_{filename}`
6. AFTER successful upload, THE app SHALL create a UserSticker document in `user_stickers/{userId}/stickers/{stickerId}`
7. IF upload fails, THE app SHALL display an error message and NOT create a Firestore document

---

### Requirement 3: Listado de Stickers del Usuario

**User Story:** As a user, I want to see all my uploaded stickers in a gallery, so that I can manage them.

#### Acceptance Criteria

1. THE StickerGallery SHALL display all stickers uploaded by the current user in a grid layout
2. THE stickers SHALL be ordered by uploadedAt descending (newest first)
3. EACH sticker SHALL display the image thumbnail (150×150px)
4. EACH sticker SHALL have a delete button (trash icon)
5. THE gallery SHALL show an "Upload New Sticker" button at the top
6. WHEN the gallery is empty, THE app SHALL display a message "No tienes stickers. ¡Sube tu primer sticker!"

---

### Requirement 4: Eliminación de Stickers

**User Story:** As a user, I want to delete my uploaded stickers, so that I can remove stickers I no longer want.

#### Acceptance Criteria

1. WHEN a user taps the delete button on a sticker, THE app SHALL show a confirmation dialog
2. IF the user confirms, THE app SHALL delete the image from Firebase Storage
3. THE app SHALL delete the UserSticker document from Firestore
4. THE app SHALL update the gallery to remove the deleted sticker
5. IF the sticker is being used in existing comments, THE comments SHALL still display the sticker (URLs remain valid until Storage cleanup)

---

### Requirement 5: Selección de Stickers en Comentarios

**User Story:** As a user, I want to select from my uploaded stickers when commenting, so that I can use my personalized stickers.

#### Acceptance Criteria

1. WHEN a user opens the StickerPicker, THE app SHALL load the user's uploaded stickers
2. THE StickerPicker SHALL display stickers in a grid (same as current implementation)
3. THE user SHALL be able to select up to 5 stickers
4. WHEN a user submits a comment with stickers, THE Comment SHALL store the imageUrl of each selected sticker
5. THE Comment model SHALL store stickers as List<String> containing imageUrls (not IDs)

---

### Requirement 6: Visualización de Stickers en Comentarios

**User Story:** As a user, I want to see stickers in comments, so that I can view the visual expressions.

#### Acceptance Criteria

1. WHEN a CommentTile renders a comment with stickers, THE app SHALL display each sticker image from its URL
2. EACH sticker SHALL be displayed at 40×40px
3. IF a sticker URL fails to load, THE app SHALL display a placeholder icon
4. THE stickers SHALL be displayed in a Wrap widget below the comment text

---

### Requirement 7: Límites y Validación

**User Story:** As a system, I want to enforce limits on sticker uploads, so that storage costs remain manageable.

#### Acceptance Criteria

1. EACH user SHALL be limited to a maximum of 50 uploaded stickers
2. WHEN a user tries to upload a 51st sticker, THE app SHALL display an error: "Has alcanzado el límite de 50 stickers"
3. THE app SHALL validate image format (PNG, JPG, WebP only)
4. THE app SHALL validate image size (≤ 2MB)
5. THE app SHALL validate image dimensions (100×100 to 1024×1024 pixels)

---

### Requirement 8: Seguridad en Firebase Storage

**User Story:** As a system, I want to secure sticker uploads, so that users can only access their own stickers.

#### Acceptance Criteria

1. Firebase Storage rules SHALL allow users to write only to `user_stickers/{userId}/`
2. Firebase Storage rules SHALL allow users to read only from `user_stickers/{userId}/`
3. Firebase Storage rules SHALL validate file size ≤ 2MB
4. Firebase Storage rules SHALL validate file type (image/png, image/jpeg, image/webp)

---

### Requirement 9: Firestore Security Rules

**User Story:** As a system, I want to secure sticker metadata, so that users can only manage their own stickers.

#### Acceptance Criteria

1. Firestore rules SHALL allow users to read only from `user_stickers/{userId}/stickers/`
2. Firestore rules SHALL allow users to write only to `user_stickers/{userId}/stickers/`
3. Firestore rules SHALL validate that userId in the document matches the authenticated user's UID

---

### Requirement 10: Retrocompatibilidad

**User Story:** As a developer, I want the new system to be backward compatible, so that existing comments continue to work.

#### Acceptance Criteria

1. EXISTING comments with sticker IDs (old system) SHALL continue to display correctly
2. THE StickerDisplay widget SHALL handle both old IDs and new URLs
3. IF a sticker field contains an old ID (e.g., "sticker_heart"), THE app SHALL attempt to load from assets
4. IF a sticker field contains a URL (starts with "http"), THE app SHALL load from the URL

---

## Data Model Changes

### UserSticker Model (New)

```dart
class UserSticker {
  final String id;
  final String userId;
  final String imageUrl;  // Firebase Storage download URL
  final DateTime uploadedAt;

  const UserSticker({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.uploadedAt,
  });
}
```

### Comment Model (Modified)

```dart
class Comment {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final List<String> stickers; // NOW: URLs or legacy IDs
  final DateTime createdAt;
}
```

### Firestore Structure

```
user_stickers/
  {userId}/
    stickers/
      {stickerId}/
        - id: String
        - userId: String
        - imageUrl: String
        - uploadedAt: Timestamp
```

### Firebase Storage Structure

```
user_stickers/
  {userId}/
    {timestamp}_{filename}.png
    {timestamp}_{filename}.jpg
    {timestamp}_{filename}.webp
```

---

## Technical Considerations

1. **Image Optimization**: Consider resizing images on upload to reduce storage costs
2. **Caching**: Use Flutter's cached_network_image for better performance
3. **Loading States**: Show loading indicators while uploading/loading stickers
4. **Error Handling**: Graceful degradation if Storage/Firestore operations fail
5. **Cleanup**: Consider implementing a cleanup job for orphaned Storage files
