# Implementation Plan: Comment Stickers

## Overview

Adds illustrated sticker support to comments and personal notes. Stickers are stored as local PNG assets and persisted in Firestore as snake_case ID strings. The implementation follows the presentation/domain/data layer architecture with Riverpod, go_router, and full i18n (ES/EN).

The plan proceeds in this order:
1. Asset infrastructure and catalog (no dependencies)
2. Domain model extensions (Comment + PersonalNote)
3. Data layer validation (CommentService)
4. New presentation widgets (StickerCatalog, StickerPicker, StickerDisplay)
5. Modifications to existing widgets (CommentForm, CommentTile, PersonalNoteField)
6. i18n strings
7. Integration checkpoints

---

## Tasks

- [x] 1. Set up sticker asset infrastructure and register in pubspec
  - Create the `assets/stickers/` directory with 20 placeholder PNG files (one per sticker ID defined in the design: `sticker_heart.png` … `sticker_pen.png`). Placeholders can be 1×1 transparent PNGs or colored squares with the ID as text — they will be replaced by the design team.
  - Add `- assets/stickers/` to the `assets:` section in `pubspec.yaml` (alongside the existing `- assets/images/` entry).
  - _Requirements: 1.4_

- [x] 2. Implement `StickerCatalog`
  - Create `lib/presentation/widgets/comment/sticker_catalog.dart`.
  - Define `abstract class StickerCatalog` with `static const Map<String, String> all` (20 entries, ID → `assets/stickers/<id>.png`) and `static const List<String> ids` (same 20 IDs in order), exactly as specified in the design.
  - Add a private `StickerCatalog._()` constructor to prevent instantiation.
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [x] 2.1 Write property test for StickerCatalog consistency
    - **Property 1: Consistencia del catálogo** — for every ID in `StickerCatalog.ids`, that ID must also be a key in `StickerCatalog.all`, and vice versa.
    - **Property 2: Rutas de asset válidas** — every value in `StickerCatalog.all` must match the pattern `assets/stickers/<sticker_id>.png`.
    - Create `test/presentation/widgets/comment/sticker_catalog_test.dart`.
    - Use `glados` (already in `dev_dependencies`) for property generation over the catalog entries.
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.4**

- [x] 3. Extend `Comment` domain model with `stickers` field
  - Edit `lib/domain/models/comment.dart`.
  - Add `final List<String> stickers` field with default `const []`.
  - Update the constructor, `fromMap`, and `toMap` as specified in the design:
    - `fromMap`: read `map['stickers']` as `List<String>.from(...)` when present, otherwise `[]`.
    - `toMap`: include `'stickers': stickers` only when `stickers.isNotEmpty` (conditional field).
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 10.1_

  - [x] 3.1 Write property tests for Comment serialization
    - **Property 5: Round-trip de serialización de Comment** — `Comment.fromMap(comment.toMap(), comment.id).stickers` equals the original list for any valid stickers list (length 0–5, known IDs).
    - **Property 6: Campo condicional en Comment.toMap()** — `comment.toMap()` must NOT contain the key `'stickers'` when `stickers` is empty.
    - **Property 7: Retrocompatibilidad en Comment.fromMap()** — `Comment.fromMap(map, id).stickers` equals `[]` when `map` has no `'stickers'` key.
    - Create `test/domain/models/comment_test.dart`.
    - **Validates: Requirements 6.2, 6.3, 6.5, 10.1**

- [x] 4. Extend `PersonalNote` domain model with `stickers` field
  - Edit `lib/domain/models/personal_note.dart`.
  - Add `final List<String> stickers` field with default `const []`.
  - Update constructor, `fromMap`, and `toMap` following the same pattern as `Comment` (conditional field, backward-compatible deserialization).
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 10.2_

  - [x] 4.1 Write property tests for PersonalNote serialization
    - **Property 8: Round-trip de serialización de PersonalNote** — `PersonalNote.fromMap(note.toMap()).stickers` equals the original list for any valid stickers list.
    - **Property 9: Campo condicional en PersonalNote.toMap()** — `note.toMap()` must NOT contain the key `'stickers'` when `stickers` is empty.
    - **Property 10: Retrocompatibilidad en PersonalNote.fromMap()** — `PersonalNote.fromMap(map).stickers` equals `[]` when `map` has no `'stickers'` key.
    - Create `test/domain/models/personal_note_test.dart`.
    - **Validates: Requirements 7.2, 7.3, 7.5, 10.2_

- [x] 5. Add sticker validation to `CommentService`
  - Edit `lib/data/services/comment_service.dart`.
  - In `addBookComment` and `addMeetingComment`, add validation before the Firestore write:
    - If `comment.stickers.length > 5`, throw `Exception('Máximo 5 stickers permitidos')`.
    - For each ID in `comment.stickers`, if the ID is not in `StickerCatalog.all.keys`, throw `Exception('Sticker no válido: $id')`.
  - Import `StickerCatalog` from the presentation layer (or extract it to `lib/domain/` if preferred — keep consistent with where it is created in task 2).
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [x] 5.1 Write unit tests for CommentService sticker validation
    - Test that `addBookComment` and `addMeetingComment` throw when `stickers.length > 5`.
    - Test that they throw when a sticker ID is not in `StickerCatalog.all.keys`.
    - Test that they succeed (no throw) for valid stickers lists (0–5 known IDs).
    - Use `fake_cloud_firestore` (already in `dev_dependencies`).
    - Create `test/data/services/comment_service_sticker_test.dart`.
    - **Validates: Requirements 8.3, 8.4**

  - [x] 5.2 Write property tests for CommentService validation
    - **Property 13: Validación del límite en CommentService** — for any `Comment` with `stickers.length > 5`, both `addBookComment` and `addMeetingComment` must throw without writing to Firestore.
    - **Property 14: Validación del catálogo en CommentService** — for any `Comment` containing an unknown sticker ID, both methods must throw without writing to Firestore.
    - **Validates: Requirements 8.3, 8.4**

- [x] 6. Checkpoint — Ensure all tests pass
  - Run `flutter test` and confirm all tests from tasks 2–5 pass.
  - Ensure `flutter analyze` reports no errors or warnings.
  - Ask the user if any questions arise before proceeding to UI work.

- [x] 7. Implement `StickerDisplay` widget
  - Create `lib/presentation/widgets/comment/sticker_display.dart`.
  - `StickerDisplay` is a `StatelessWidget` that accepts `final List<String> stickers`.
  - Render a `Wrap` with `spacing: 4`. For each ID in `stickers`, filter with `.where((id) => StickerCatalog.all.containsKey(id))` and render `Image.asset(StickerCatalog.all[id]!, width: 40, height: 40)`.
  - Return `const SizedBox.shrink()` (or an empty `Wrap`) when the filtered list is empty.
  - _Requirements: 5.2, 5.3, 5.4, 10.3_

  - [x] 7.1 Write property test for StickerDisplay unknown ID handling
    - **Property 11: StickerDisplay ignora IDs desconocidos** — for any list of sticker IDs that includes unknown IDs, `StickerDisplay` must render only the known subset without throwing.
    - Create `test/presentation/widgets/comment/sticker_display_test.dart`.
    - Use `flutter_test` widget testing; pump `StickerDisplay` with mixed known/unknown IDs and verify no exception and correct widget count.
    - **Validates: Requirements 5.3, 5.4, 10.3**

- [x] 8. Implement `StickerPicker` widget
  - Create `lib/presentation/widgets/comment/sticker_picker.dart`.
  - `StickerPicker` is a `StatefulWidget` with:
    - `final List<String> selectedStickers` (pre-selected IDs)
    - `final int maxStickers` (default 5)
    - `final void Function(List<String>) onConfirm`
  - Internal state: `List<String> _selected` initialized from `widget.selectedStickers`.
  - Implement `_toggleSticker(String id)`:
    - If `id` is in `_selected` → remove it.
    - Else if `_selected.length < maxStickers` → add it.
    - Else → no-op (limit reached).
  - Build a `GridView.builder` with `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8)` iterating over `StickerCatalog.ids`.
  - Each cell: `GestureDetector` wrapping a `Stack` with `Image.asset` (56×56) and, when selected, a `DecoratedBox` border overlay using `Theme.of(context).colorScheme.primary`. Apply `Opacity(opacity: 0.35)` when the sticker is disabled (not selected and limit reached).
  - Include a "Confirmar" / "Confirm" button at the bottom that calls `onConfirm(_selected)`.
  - Follow the Alquimia design system (use `Theme` colors, `BorderRadius.circular(8)`).
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [x] 8.1 Write property test for StickerPicker toggle logic
    - **Property 3: Idempotencia del toggle (doble toggle)** — applying `_toggleSticker` twice with the same ID returns a list equivalent to the original.
    - **Property 4: El toggle respeta el límite máximo** — when `_selected.length == maxStickers`, calling `_toggleSticker` with an unknown ID leaves the list unchanged.
    - Extract the pure toggle logic into a top-level function `List<String> toggleSticker(List<String> current, String id, int max)` in `sticker_picker.dart` (or a separate utility file) so it can be tested without a widget.
    - Create `test/presentation/widgets/comment/sticker_picker_test.dart`.
    - **Validates: Requirements 2.3, 2.4**

  - [x] 8.2 Write property test for sticker ID storage (no asset paths)
    - **Property 12: Solo IDs en Firestore (no rutas de asset)** — verify that `StickerPicker.onConfirm` emits IDs (snake_case strings) and never asset paths (strings starting with `'assets/'`).
    - **Validates: Requirements 6.1, 8.1, 8.2**

- [x] 9. Modify `CommentForm` to support sticker selection
  - Edit `lib/presentation/widgets/comment/comment_form.dart`.
  - Add `List<String> _selectedStickers = []` to `_CommentFormState`.
  - Add a sticker `IconButton` (e.g., `Icons.emoji_emotions_outlined`) next to the text field. On tap, call `_openStickerPicker(context)`.
  - Implement `_openStickerPicker`: calls `showModalBottomSheet` presenting `StickerPicker(selectedStickers: _selectedStickers, onConfirm: (ids) { setState(() => _selectedStickers = ids); Navigator.pop(context); })`.
  - Show a `StickerDisplay(stickers: _selectedStickers)` preview above the text field when `_selectedStickers.isNotEmpty`.
  - In `_submit`, pass `stickers: _selectedStickers` when constructing the `Comment`.
  - After a successful submit, add `setState(() => _selectedStickers = [])` to clear the preview.
  - On error (catch block), preserve `_selectedStickers` (no reset).
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 9.1_

- [x] 10. Modify `CommentTile` to display stickers
  - Edit `lib/presentation/widgets/comment/comment_list.dart` (where `CommentTile` is defined).
  - In `CommentTile.build`, after `Text(comment.text)`, add:
    ```dart
    if (comment.stickers.isNotEmpty)
      StickerDisplay(stickers: comment.stickers),
    ```
  - Import `StickerDisplay` and `StickerCatalog`.
  - _Requirements: 5.1, 5.5, 10.4_

- [x] 11. Modify `PersonalNoteField` to support sticker selection
  - Edit `lib/presentation/widgets/personal_book/personal_note_field.dart`.
  - Add `List<String> _selectedStickers = []` to `_PersonalNoteFieldState`.
  - Add a sticker `IconButton` next to the "Guardar" / "Save" button. On tap, open `StickerPicker` via `showModalBottomSheet` (same pattern as `CommentForm`).
  - Update `_handleSave`: change the `onAddNote` callback signature to accept stickers, or construct a `PersonalNote` internally and pass it to a new `onAddNoteWithStickers` callback. Choose the approach that requires fewer changes to callers — check how `PersonalNoteField` is used in the screens before deciding.
  - After a successful save, reset `_selectedStickers = []`.
  - On error, preserve `_selectedStickers`.
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 9.2_

- [x] 12. Add i18n strings for sticker UI
  - Edit `lib/l10n/app_es.arb` and `lib/l10n/app_en.arb`.
  - Add the following keys (adjust wording to match the app's tone):
    - `stickerPickerTitle` — "Stickers" / "Stickers"
    - `stickerPickerConfirm` — "Confirmar" / "Confirm"
    - `stickerButtonTooltip` — "Agregar sticker" / "Add sticker"
    - `stickerLimitReached` — "Límite de stickers alcanzado (máx. {max})" / "Sticker limit reached (max {max})" (with `max` placeholder)
  - Replace any hardcoded strings in `StickerPicker`, `CommentForm`, and `PersonalNoteField` with `AppLocalizations.of(context)!.<key>`.
  - _Requirements: (architecture guideline — all UI text must be internationalized)_

- [x] 13. Final checkpoint — Ensure all tests pass and analyze is clean
  - Run `flutter test` and confirm all tests pass (unit, widget, and property tests).
  - Run `flutter analyze` and fix any warnings or errors.
  - Verify `flutter pub get` succeeds (no dependency issues after pubspec change).
  - Ask the user if any questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP.
- `StickerCatalog` is placed in `lib/presentation/widgets/comment/` because it is a pure presentation-layer constant (asset paths). If `CommentService` needs to import it for validation, consider moving it to `lib/domain/models/sticker_catalog.dart` to avoid a data→presentation dependency.
- Placeholder sticker images (task 1) must be replaced with the final illustrated PNG/WebP assets before production release.
- The `glados` package (property-based testing) is already present in `dev_dependencies`.
- `fake_cloud_firestore` is already present in `dev_dependencies` for service tests.
- Each property test references the property number from the design document's "Correctness Properties" section for traceability.
- The `PersonalNoteField.onAddNote` callback currently accepts `String text`. Task 11 may require updating callers (screens) to pass stickers — check `lib/presentation/screens/personal_books/` before implementing.
