import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/comment.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/comment_provider.dart';

/// Validates comment text length: must be 1–1000 characters.
/// Requirement 7.3
String? validateCommentText(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) return l10n.commentTooShort;
  if (value.length > 1000) return l10n.commentTooLong;
  return null;
}

/// Form widget for submitting a comment on a book or meeting.
/// Requirement 7.3 – validates length before allowing submission.
/// Requirement 7.4 – after submit the stream updates the list automatically.
class CommentForm extends ConsumerStatefulWidget {
  final String parentId;
  final bool isBook;
  final String currentUserId;
  final String currentUserName;

  const CommentForm({
    required this.parentId,
    required this.isBook,
    required this.currentUserId,
    required this.currentUserName,
    super.key,
  });

  @override
  ConsumerState<CommentForm> createState() => _CommentFormState();
}

class _CommentFormState extends ConsumerState<CommentForm> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(commentServiceProvider);
      final comment = Comment(
        id: '',
        authorId: widget.currentUserId,
        authorName: widget.currentUserName,
        text: _controller.text.trim(),
        createdAt: DateTime.now(),
      );

      if (widget.isBook) {
        await service.addBookComment(widget.parentId, comment);
      } else {
        await service.addMeetingComment(widget.parentId, comment);
      }

      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commentSendError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: l10n.commentLabel,
                hintText: l10n.commentHint,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              maxLength: 1000,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              validator: (value) => validateCommentText(value?.trim(), l10n),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          _isSubmitting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton.filled(
                  icon: const Icon(Icons.send),
                  tooltip: l10n.send,
                  onPressed: _submit,
                ),
        ],
      ),
    );
  }
}
