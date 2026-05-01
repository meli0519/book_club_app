import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import '../../../domain/models/personal_book.dart';

/// A row of filterable chips for filtering personal books by status.
class PersonalBookStatusFilter extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;

  const PersonalBookStatusFilter({
    required this.selectedStatus,
    required this.onStatusSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterChip(
            context: context,
            status: 'all',
            label: l10n.personalBookFilterAll,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            status: PersonalBookStatus.wantToRead,
            label: l10n.personalBookStatusWantToRead,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            status: PersonalBookStatus.reading,
            label: l10n.personalBookStatusReading,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            status: PersonalBookStatus.read,
            label: l10n.personalBookStatusRead,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String status,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedStatus == status;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => onStatusSelected(status),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Returns the localized label for a given status.
String getStatusLabel(String status, AppLocalizations l10n) {
  switch (status) {
    case PersonalBookStatus.read:
      return l10n.personalBookStatusRead;
    case PersonalBookStatus.reading:
      return l10n.personalBookStatusReading;
    case PersonalBookStatus.wantToRead:
    default:
      return l10n.personalBookStatusWantToRead;
  }
}