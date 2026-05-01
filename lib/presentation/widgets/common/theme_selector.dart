import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';

/// Widget que muestra un diálogo para seleccionar el tema de la aplicación
/// Sigue las guías de arquitectura: Presentation Layer - Widgets
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentThemeMode = ref.watch(themeModeProvider);

    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(l10n.theme),
      subtitle: Text(_getThemeLabel(currentThemeMode, l10n)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, ref, l10n),
    );
  }

  String _getThemeLabel(ThemeMode themeMode, AppLocalizations l10n) {
    switch (themeMode) {
      case ThemeMode.system:
        return l10n.themeSystem;
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
    }
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final currentThemeMode = ref.read(themeModeProvider);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.themeDialogTitle),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              title: l10n.themeSystem,
              subtitle: l10n.themeSystemDescription,
              icon: Icons.phone_android,
              isSelected: currentThemeMode == ThemeMode.system,
              onTap: () {
                ref.read(themeModeProvider.notifier).setSystemMode();
                Navigator.of(ctx).pop();
              },
            ),
            const Divider(height: 1),
            _ThemeOption(
              title: l10n.themeLight,
              subtitle: l10n.themeLightDescription,
              icon: Icons.light_mode,
              isSelected: currentThemeMode == ThemeMode.light,
              onTap: () {
                ref.read(themeModeProvider.notifier).setLightMode();
                Navigator.of(ctx).pop();
              },
            ),
            const Divider(height: 1),
            _ThemeOption(
              title: l10n.themeDark,
              subtitle: l10n.themeDarkDescription,
              icon: Icons.dark_mode,
              isSelected: currentThemeMode == ThemeMode.dark,
              onTap: () {
                ref.read(themeModeProvider.notifier).setDarkMode();
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget interno para cada opción de tema en el diálogo
class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
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
