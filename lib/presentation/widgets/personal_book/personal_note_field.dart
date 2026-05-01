import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// A text field for personal comments with real-time character counter.
/// Disables save and shows inline error if text exceeds 5000 characters.
class PersonalNoteField extends StatefulWidget {
  final String? initialValue;
  final int maxLength;
  final ValueChanged<String> onSaved;
  final VoidCallback? onSave;
  final bool enabled;

  const PersonalNoteField({
    this.initialValue,
    this.maxLength = 5000,
    required this.onSaved,
    this.onSave,
    this.enabled = true,
    super.key,
  });

  @override
  State<PersonalNoteField> createState() => _PersonalNoteFieldState();
}

class _PersonalNoteFieldState extends State<PersonalNoteField> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
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
    final maxLength = widget.maxLength;

    setState(() {
      if (text.length > maxLength) {
        _error = AppLocalizations.of(context)!.personalBookNoteTooLong(
          maxLength,
          text.length,
        );
      } else {
        _error = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          maxLength: widget.maxLength,
          maxLines: 5,
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
          onSaved: (_) => widget.onSaved(_controller.text),
        ),
        if (widget.onSave != null && widget.enabled)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _error == null ? widget.onSave : null,
              icon: const Icon(Icons.save),
              label: Text(l10n.save),
            ),
          ),
      ],
    );
  }
}

/// Validates that the comment text does not exceed the maximum length.
String? validateNoteLength(String? value, int maxLength, AppLocalizations l10n) {
  if (value != null && value.length > maxLength) {
    return l10n.personalBookNoteTooLong(maxLength, value.length);
  }
  return null;
}