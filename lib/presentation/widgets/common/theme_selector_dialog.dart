import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

/// Diálogo para seleccionar el modo de tema
/// Permite elegir entre: Sistema, Claro u Oscuro
class ThemeSelectorDialog extends ConsumerWidget {
  const ThemeSelectorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.themeDialogTitle),
      contentPadding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeOption(
            title: l10n.themeSystem,
            subtitle: l10n.themeSystemDescription,
            icon: Icons.brightness_auto,
            isSelected: themeMode == ThemeMode.system,
            onTap: () {
              ref.read(themeModeProvider.notifier).setSystemMode();
              Navigator.of(context).pop();
            },
          ),
          _ThemeOption(
            title: l10n.themeLight,
            subtitle: l10n.themeLightDescription,
            icon: Icons.light_mode,
            isSelected: themeMode == ThemeMode.light,
            onTap: () {
              ref.read(themeModeProvider.notifier).setLightMode();
              Navigator.of(context).pop();
            },
          ),
          _ThemeOption(
            title: l10n.themeDark,
            subtitle: l10n.themeDarkDescription,
            icon: Icons.dark_mode,
            isSelected: themeMode == ThemeMode.dark,
            onTap: () {
              ref.read(themeModeProvider.notifier).setDarkMode();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  /// Muestra el diálogo de selección de tema
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ThemeSelectorDialog(),
    );
  }
}

/// Widget interno para cada opción de tema
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
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}
