import 'package:flutter/material.dart';

/// A chip that displays a phrase and can be expanded to show the full text
/// when tapped if the text is too long.
///
/// Features:
/// - Shows truncated text with ellipsis if too long
/// - Expands to show full text when tapped
/// - Optional delete button
/// - Automatically collapses when tapped again
class ExpandablePhraseChip extends StatefulWidget {
  final String phrase;
  final VoidCallback? onDeleted;
  final int maxLines;
  final MaterialTapTargetSize? materialTapTargetSize;

  const ExpandablePhraseChip({
    required this.phrase,
    this.onDeleted,
    this.maxLines = 2,
    this.materialTapTargetSize,
    super.key,
  });

  @override
  State<ExpandablePhraseChip> createState() => _ExpandablePhraseChipState();
}

class _ExpandablePhraseChipState extends State<ExpandablePhraseChip> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.phrase,
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (widget.onDeleted != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: widget.onDeleted,
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
