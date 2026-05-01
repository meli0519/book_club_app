import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import '../../../domain/models/personal_book.dart';

/// A chip widget that displays the personal book status with appropriate color and label.
class PersonalBookStatusChip extends StatelessWidget {
  final String status;

  const PersonalBookStatusChip({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final (color, label) = _getStatusInfo(theme, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: _getOnColor(color, theme),
        ),
      ),
    );
  }

  (Color color, String label) _getStatusInfo(ThemeData theme, AppLocalizations l10n) {
    switch (status) {
      case PersonalBookStatus.read:
        return (
          theme.colorScheme.secondaryContainer,
          l10n.personalBookStatusRead,
        );
      case PersonalBookStatus.reading:
        return (
          theme.colorScheme.primaryContainer,
          l10n.personalBookStatusReading,
        );
      case PersonalBookStatus.wantToRead:
      default:
        return (
          theme.colorScheme.tertiaryContainer,
          l10n.personalBookStatusWantToRead,
        );
    }
  }

  Color _getOnColor(Color color, ThemeData theme) {
    if (color == theme.colorScheme.secondaryContainer) {
      return theme.colorScheme.onSecondaryContainer;
    }
    if (color == theme.colorScheme.primaryContainer) {
      return theme.colorScheme.onPrimaryContainer;
    }
    return theme.colorScheme.onTertiaryContainer;
  }
}