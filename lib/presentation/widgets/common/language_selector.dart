import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

/// Widget que muestra un diálogo para seleccionar el idioma de la aplicación
/// Sigue las guías de arquitectura: Presentation Layer - Widgets
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      subtitle: Text(_getLanguageLabel(currentLocale, l10n)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context, ref, l10n),
    );
  }

  String _getLanguageLabel(Locale? locale, AppLocalizations l10n) {
    if (locale == null) {
      return l10n.languageSystem;
    }
    switch (locale.languageCode) {
      case 'en':
        return l10n.languageEnglish;
      case 'es':
        return l10n.languageSpanish;
      default:
        return l10n.languageSystem;
    }
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final currentLocale = ref.read(localeProvider);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.languageDialogTitle),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              title: l10n.languageSystem,
              subtitle: l10n.languageSystemDescription,
              icon: Icons.phone_android,
              isSelected: currentLocale == null,
              onTap: () {
                ref.read(localeProvider.notifier).setSystemLocale();
                Navigator.of(ctx).pop();
              },
            ),
            const Divider(height: 1),
            _LanguageOption(
              title: l10n.languageEnglish,
              subtitle: l10n.languageEnglishDescription,
              icon: Icons.language,
              isSelected: currentLocale?.languageCode == 'en',
              onTap: () {
                ref.read(localeProvider.notifier).setEnglish();
                Navigator.of(ctx).pop();
              },
            ),
            const Divider(height: 1),
            _LanguageOption(
              title: l10n.languageSpanish,
              subtitle: l10n.languageSpanishDescription,
              icon: Icons.language,
              isSelected: currentLocale?.languageCode == 'es',
              onTap: () {
                ref.read(localeProvider.notifier).setSpanish();
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget interno para cada opción de idioma en el diálogo
class _LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}
