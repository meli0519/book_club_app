import 'package:flutter/material.dart';

import '../../../domain/models/personal_note.dart';
import '../../../l10n/app_localizations.dart';
import '../comment/sticker_display.dart';
import '../comment/sticker_picker.dart';

/// Input field to add a new personal note, plus a list of existing notes below.
///
/// - User types a comment and presses "Guardar"
/// - The field clears and the new comment appears in the list
/// - Each note shows its text and the date it was added
/// - Notes can be deleted with a long-press or swipe, or edited via the menu
class PersonalNoteField extends StatefulWidget {
  /// Existing notes to display, newest first.
  final List<PersonalNote> notes;
  final int maxLength;
  final Future<void> Function(PersonalNote note) onAddNote;
  final Future<void> Function(PersonalNote note) onDeleteNote;
  final Future<void> Function(PersonalNote oldNote, PersonalNote newNote)? onUpdateNote;
  final bool enabled;

  /// ID of the current user, used to load their stickers in the picker.
  final String userId;

  const PersonalNoteField({
    required this.notes,
    required this.onAddNote,
    required this.onDeleteNote,
    required this.userId,
    this.onUpdateNote,
    this.maxLength = 5000,
    this.enabled = true,
    super.key,
  });

  @override
  State<PersonalNoteField> createState() => _PersonalNoteFieldState();
}

class _PersonalNoteFieldState extends State<PersonalNoteField> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _isSaving = false;
  List<String> _selectedStickers = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    _controller.removeListener(_validateInput);
    _controller.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _controller.text;
    final newError = text.length > widget.maxLength
        ? AppLocalizations.of(context)!
            .personalBookNoteTooLong(widget.maxLength, text.length)
        : null;
    if (newError != _error) {
      setState(() => _error = newError);
    }
  }

  void _openStickerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (_) => StickerPicker(
        userId: widget.userId,
        selectedStickers: _selectedStickers,
        onConfirm: (urls) {
          setState(() => _selectedStickers = urls);
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSaving || _error != null) return;

    setState(() => _isSaving = true);
    try {
      final note = PersonalNote(
        text: text,
        stickers: _selectedStickers,
        createdAt: DateTime.now(),
      );
      await widget.onAddNote(note);
      if (mounted) {
        _controller.clear();
        setState(() => _selectedStickers = []);
      }
    } catch (_) {
      // _selectedStickers is intentionally NOT reset here so the user can retry.
      if (mounted) {
        // Error handling is done by the caller (screen shows SnackBar)
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete(PersonalNote note) async {
    await widget.onDeleteNote(note);
  }

  Future<void> _handleEdit(PersonalNote note) async {
    if (widget.onUpdateNote == null) return;
    final updated = await showDialog<PersonalNote>(
      context: context,
      builder: (_) => _NoteEditDialog(note: note, userId: widget.userId),
    );
    if (updated != null) {
      await widget.onUpdateNote!(note, updated);
    }
  }

  Future<void> _confirmDelete(PersonalNote note) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCommentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _handleDelete(note);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Input field ──────────────────────────────────────────────────────
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          maxLength: widget.maxLength,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.personalBookNotesLabel,
            hintText: l10n.personalBookNotesHint,
            alignLabelWithHint: true,
            errorText: _error,
            counterStyle: theme.textTheme.bodySmall?.copyWith(
              color: _error != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onFieldSubmitted: (_) => _handleSave(),
        ),
        // ── Sticker preview ──────────────────────────────────────────────────
        if (_selectedStickers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedStickers.map((url) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 52,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedStickers.remove(url)),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        if (widget.enabled)
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  tooltip: l10n.stickerButtonTooltip,
                  onPressed: () => _openStickerPicker(context),
                ),
                ElevatedButton.icon(
                  onPressed: (_error == null && !_isSaving) ? _handleSave : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(l10n.save),
                ),
              ],
            ),
          ),

        // ── Notes list ───────────────────────────────────────────────────────
        if (widget.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.personalBookNotesLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.notes.map(
            (note) => _NoteCard(
              note: note,
              formatDate: _formatDate,
              onEdit: widget.onUpdateNote != null
                  ? () => _handleEdit(note)
                  : null,
              onDelete: () => _confirmDelete(note),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Note card with edit/delete menu
// ---------------------------------------------------------------------------

enum _NoteAction { edit, delete }

class _NoteCard extends StatelessWidget {
  final PersonalNote note;
  final String Function(DateTime) formatDate;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.formatDate,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  note.text,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              PopupMenuButton<_NoteAction>(
                iconSize: 18,
                padding: EdgeInsets.zero,
                onSelected: (action) {
                  if (action == _NoteAction.edit) {
                    onEdit?.call();
                  } else {
                    onDelete();
                  }
                },
                itemBuilder: (ctx) => [
                  if (onEdit != null)
                    PopupMenuItem(
                      value: _NoteAction.edit,
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.editComment),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: _NoteAction.delete,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.deleteComment,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (note.stickers.isNotEmpty) ...[
            const SizedBox(height: 6),
            StickerDisplay(stickers: note.stickers),
          ],
          const SizedBox(height: 4),
          Text(
            formatDate(note.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Note edit dialog
// ---------------------------------------------------------------------------

class _NoteEditDialog extends StatefulWidget {
  final PersonalNote note;
  final String userId;

  const _NoteEditDialog({required this.note, required this.userId});

  @override
  State<_NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<_NoteEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late List<String> _stickers;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.text);
    _stickers = List<String>.from(widget.note.stickers);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openStickerPicker() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => StickerPicker(
        userId: widget.userId,
        selectedStickers: _stickers,
        onConfirm: (urls) => setState(() => _stickers = urls),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.editComment),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticker preview
              if (_stickers.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _stickers.map((url) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        StickerDisplay(stickers: [url]),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _stickers.remove(url)),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: l10n.personalBookNotesLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                minLines: 2,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n.commentTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _openStickerPicker,
                icon: const Icon(Icons.emoji_emotions_outlined),
                label: Text(l10n.stickerButtonTooltip),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                PersonalNote(
                  text: _controller.text.trim(),
                  stickers: _stickers,
                  createdAt: widget.note.createdAt, // preserve original timestamp
                ),
              );
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Validates that the comment text does not exceed the maximum length.
String? validateNoteLength(
    String? value, int maxLength, AppLocalizations l10n) {
  if (value != null && value.length > maxLength) {
    return l10n.personalBookNoteTooLong(maxLength, value.length);
  }
  return null;
}
