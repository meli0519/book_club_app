# Requirements Document

## Introduction

Esta feature permite a los usuarios adjuntar stickers ilustrados a sus comentarios y notas personales en la app Book Club. Los stickers son imágenes PNG/WebP con fondo transparente almacenadas como assets locales. Se seleccionan desde un picker tipo cuadrícula antes de enviar el comentario, y se persisten en Firestore como IDs de sticker (strings snake_case). La feature aplica a los tres contextos donde existen comentarios: libros del club (`books/{bookId}/comments`), libros personales (`users/{uid}/personal_books/{bookId}`) y reuniones (`meetings/{meetingId}/comments`).

El diseño extiende el modelo `Comment` existente y el widget `PersonalNoteField` con un campo opcional `stickers`, sin romper compatibilidad con comentarios ya guardados.

---

## Glossary

- **StickerCatalog**: Clase abstracta que define el catálogo cerrado de stickers disponibles en la app. Centraliza el mapa `ID → ruta de asset`.
- **StickerPicker**: Widget reutilizable que muestra la cuadrícula de stickers y gestiona la selección del usuario.
- **StickerDisplay**: Widget de solo lectura que renderiza la fila de stickers adjuntos a un comentario o nota ya guardado.
- **Comment**: Modelo de dominio que representa un comentario en un libro del club o reunión. Incluye el campo opcional `stickers`.
- **PersonalNote**: Modelo de dominio que representa una nota en un libro personal. Incluye el campo opcional `stickers`.
- **CommentForm**: Widget de formulario para crear comentarios en libros del club y reuniones.
- **PersonalNoteField**: Widget de formulario para crear notas en libros personales.
- **CommentTile**: Widget de solo lectura que muestra un comentario en una lista.
- **CommentService**: Servicio de la capa de datos que persiste comentarios en Firestore.
- **PersonalBookService**: Servicio de la capa de datos que persiste notas personales en Firestore.
- **Sticker_ID**: String en formato snake_case que identifica un sticker (ej. `sticker_heart`). Debe pertenecer a `StickerCatalog.all.keys`.
- **maxStickers**: Límite máximo de stickers seleccionables simultáneamente por comentario o nota. Valor por defecto: 5.

---

## Requirements

### Requirement 1: Catálogo de Stickers

**User Story:** As a developer, I want a centralized sticker catalog, so that all components use the same source of truth for sticker IDs and asset paths.

#### Acceptance Criteria

1. THE StickerCatalog SHALL define a static map of Sticker_ID to asset path for exactly 20 stickers.
2. THE StickerCatalog SHALL provide a static list of IDs (`ids`) that contains exactly the same keys as the `all` map.
3. WHEN a Sticker_ID is present in `StickerCatalog.ids`, THE StickerCatalog SHALL also contain that ID as a key in `StickerCatalog.all`.
4. THE StickerCatalog SHALL map each Sticker_ID to an asset path following the pattern `assets/stickers/<sticker_id>.png`.

---

### Requirement 2: Selección de Stickers (StickerPicker)

**User Story:** As a user, I want to select illustrated stickers from a grid picker, so that I can attach them to my comments and notes.

#### Acceptance Criteria

1. WHEN the StickerPicker is opened, THE StickerPicker SHALL display all stickers from `StickerCatalog.ids` in a grid layout.
2. WHEN a user taps an unselected sticker and the selected count is less than `maxStickers`, THE StickerPicker SHALL add that sticker to the selected list and display a visual selection indicator on it.
3. WHEN a user taps a selected sticker, THE StickerPicker SHALL remove it from the selected list and hide the selection indicator.
4. WHILE the selected sticker count equals `maxStickers`, THE StickerPicker SHALL display unselected stickers with reduced opacity (0.35) and SHALL NOT add them to the selected list when tapped.
5. WHEN the user confirms the selection, THE StickerPicker SHALL invoke the `onConfirm` callback with the current list of selected Sticker_IDs.
6. WHEN the StickerPicker is opened with a pre-existing `selectedStickers` list, THE StickerPicker SHALL display those stickers with the selection indicator already applied.

---

### Requirement 3: Adjuntar Stickers en CommentForm

**User Story:** As a user, I want to attach stickers to my club book and meeting comments, so that I can express reactions visually alongside my text.

#### Acceptance Criteria

1. THE CommentForm SHALL display a sticker button alongside the text input field.
2. WHEN a user taps the sticker button, THE CommentForm SHALL open the StickerPicker as a modal bottom sheet.
3. WHEN the StickerPicker confirms a selection, THE CommentForm SHALL display a preview of the selected stickers above the text input field using StickerDisplay.
4. WHEN a user submits the form, THE CommentForm SHALL include the selected Sticker_IDs in the `stickers` field of the Comment object passed to CommentService.
5. WHEN a comment is submitted successfully, THE CommentForm SHALL clear the selected stickers list and reset the sticker preview.
6. IF the text field is empty, THEN THE CommentForm SHALL prevent submission regardless of whether stickers are selected.

---

### Requirement 4: Adjuntar Stickers en PersonalNoteField

**User Story:** As a user, I want to attach stickers to my personal book notes, so that I can express reactions in my private reading journal.

#### Acceptance Criteria

1. THE PersonalNoteField SHALL display a sticker button alongside the save button.
2. WHEN a user taps the sticker button, THE PersonalNoteField SHALL open the StickerPicker as a modal bottom sheet.
3. WHEN the StickerPicker confirms a selection, THE PersonalNoteField SHALL update the internal selected stickers state.
4. WHEN a user saves the note, THE PersonalNoteField SHALL include the selected Sticker_IDs in the `stickers` field of the PersonalNote object passed to PersonalBookService.
5. WHEN a note is saved successfully, THE PersonalNoteField SHALL clear the selected stickers list.

---

### Requirement 5: Visualización de Stickers (StickerDisplay)

**User Story:** As a user, I want to see the stickers attached to comments and notes, so that I can read the full expressive content of each entry.

#### Acceptance Criteria

1. WHEN a CommentTile renders a comment with a non-empty `stickers` list, THE CommentTile SHALL render a StickerDisplay widget below the comment text.
2. WHEN StickerDisplay renders a list of Sticker_IDs, THE StickerDisplay SHALL display each known Sticker_ID as an `Image.asset` of 40×40px inside a `Wrap`.
3. WHEN StickerDisplay receives a Sticker_ID that is not present in `StickerCatalog.all`, THE StickerDisplay SHALL silently ignore that ID and SHALL NOT throw an exception.
4. WHEN the `stickers` list is empty or all IDs are unknown, THE StickerDisplay SHALL render no visible content.
5. WHEN a CommentTile renders a comment with an empty `stickers` list, THE CommentTile SHALL NOT render a StickerDisplay widget.

---

### Requirement 6: Serialización y Deserialización de Comment

**User Story:** As a developer, I want the Comment model to correctly serialize and deserialize sticker data, so that stickers are persisted accurately in Firestore and backward compatibility is maintained.

#### Acceptance Criteria

1. WHEN `Comment.toMap()` is called on a Comment with a non-empty `stickers` list, THE Comment SHALL include a `stickers` field in the resulting map containing only Sticker_IDs (not asset paths).
2. WHEN `Comment.toMap()` is called on a Comment with an empty `stickers` list, THE Comment SHALL omit the `stickers` field from the resulting map.
3. WHEN `Comment.fromMap()` is called with a map that does not contain a `stickers` field, THE Comment SHALL set `stickers` to an empty list.
4. WHEN `Comment.fromMap()` is called with a map containing a `stickers` field, THE Comment SHALL populate `stickers` with the list of strings from that field, including any unknown IDs.
5. FOR ALL valid Comment objects with stickers, serializing with `toMap()` then deserializing with `fromMap()` SHALL produce a Comment with an equivalent `stickers` list (round-trip property).

---

### Requirement 7: Serialización y Deserialización de PersonalNote

**User Story:** As a developer, I want the PersonalNote model to correctly serialize and deserialize sticker data, so that stickers in personal notes are persisted accurately and backward compatibility is maintained.

#### Acceptance Criteria

1. WHEN `PersonalNote.toMap()` is called on a PersonalNote with a non-empty `stickers` list, THE PersonalNote SHALL include a `stickers` field in the resulting map containing only Sticker_IDs.
2. WHEN `PersonalNote.toMap()` is called on a PersonalNote with an empty `stickers` list, THE PersonalNote SHALL omit the `stickers` field from the resulting map.
3. WHEN `PersonalNote.fromMap()` is called with a map that does not contain a `stickers` field, THE PersonalNote SHALL set `stickers` to an empty list.
4. WHEN `PersonalNote.fromMap()` is called with a map containing a `stickers` field, THE PersonalNote SHALL populate `stickers` with the list of strings from that field.
5. FOR ALL valid PersonalNote objects with stickers, serializing with `toMap()` then deserializing with `fromMap()` SHALL produce a PersonalNote with an equivalent `stickers` list (round-trip property).

---

### Requirement 8: Validación y Persistencia en CommentService

**User Story:** As a developer, I want the CommentService to validate and persist sticker data correctly, so that only valid sticker IDs are stored in Firestore.

#### Acceptance Criteria

1. WHEN `addBookComment` is called with a Comment whose `stickers.length` is between 0 and 5 and all IDs belong to `StickerCatalog.all.keys`, THE CommentService SHALL persist the comment to `books/{bookId}/comments/` with the `stickers` field containing only Sticker_IDs.
2. WHEN `addMeetingComment` is called with a Comment whose `stickers.length` is between 0 and 5 and all IDs belong to `StickerCatalog.all.keys`, THE CommentService SHALL persist the comment to `meetings/{meetingId}/comments/` with the `stickers` field containing only Sticker_IDs.
3. IF a Comment is submitted with `stickers.length > 5`, THEN THE CommentService SHALL throw a `ValidationError` and SHALL NOT write to Firestore.
4. IF a Comment is submitted with a Sticker_ID not present in `StickerCatalog.all.keys`, THEN THE CommentService SHALL throw a `ValidationError` and SHALL NOT write to Firestore.
5. WHEN `addNote` is called on PersonalBookService with a PersonalNote whose stickers are valid, THE PersonalBookService SHALL persist the note using `FieldValue.arrayUnion` with the `stickers` field containing only Sticker_IDs.

---

### Requirement 9: Manejo de Errores en Formularios

**User Story:** As a user, I want the app to handle save errors gracefully, so that I don't lose my selected stickers if a network error occurs.

#### Acceptance Criteria

1. IF `CommentService.addBookComment` or `CommentService.addMeetingComment` throws an exception, THEN THE CommentForm SHALL display an error message via SnackBar and SHALL preserve the selected stickers in the form state.
2. IF `PersonalBookService.addNote` throws an exception, THEN THE PersonalNoteField SHALL display an error message and SHALL preserve the selected stickers in the form state.

---

### Requirement 10: Retrocompatibilidad

**User Story:** As a developer, I want existing comments and notes without sticker data to continue working correctly, so that the feature rollout does not break existing content.

#### Acceptance Criteria

1. WHEN `Comment.fromMap()` is called with a Firestore document that has no `stickers` field, THE Comment SHALL be created successfully with `stickers` equal to an empty list.
2. WHEN `PersonalNote.fromMap()` is called with a map that has no `stickers` field, THE PersonalNote SHALL be created successfully with `stickers` equal to an empty list.
3. WHEN StickerDisplay receives a Sticker_ID that does not exist in `StickerCatalog.all`, THE StickerDisplay SHALL not render that sticker and SHALL NOT throw an exception.
4. WHEN a CommentTile renders a comment with an empty `stickers` list, THE CommentTile SHALL render identically to how it rendered before this feature was introduced.
