import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/comment.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/comment_provider.dart';
import 'sticker_picker.dart';
import 'sticker_display.dart';

/// Dialog that lets the comment author edit the text and stickers of their
/// existing comment. Validates the same rules as [CommentForm]:
/// text must be 1–1000 characters, max 5 stickers.
class CommentEditDialog extends ConsumerStatefulWidget {
  final Comment comment;
  final String parentId;
  final bool isBook;
  final String currentUserId;

  const CommentEditDialog({
    required this.comment,
    required this.parentId,
    required this.isBook,
    required this.currentUserId,
    super.key,
  });

  @override
  ConsumerState<CommentEditDialog> createState() => _CommentEditDialogState();
}

class _CommentEditDialogState extends ConsumerState<CommentEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late List<String> _stickers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.comment.text);
    _stickers = List<String>.from(widget.comment.stickers);
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
        userId: widget.currentUserId,
        selectedStickers: _stickers,
        onConfirm: (urls) => setState(() => _stickers = urls),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final service = ref.read(commentServiceProvider);
      if (widget.isBook) {
        await service.updateBookComment(
          widget.parentId,
          widget.comment.id,
          _controller.text.trim(),
          _stickers,
        );
      } else {
        await service.updateMeetingComment(
          widget.parentId,
          widget.comment.id,
          _controller.text.trim(),
          _stickers,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.commentEditError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
              // Sticker preview + remove
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
              // Text field
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: l10n.commentLabel,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                maxLength: 1000,
                maxLines: 4,
                minLines: 2,
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed.isEmpty) return l10n.commentTooShort;
                  if (trimmed.length > 1000) return l10n.commentTooLong;
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Sticker button
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
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
