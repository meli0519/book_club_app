import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

/// Widget para alternar entre tema claro y oscuro
/// Sigue las guías de arquitectura: Presentation Layer - Widgets reutilizables
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
      ),
      tooltip: isDark ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggleTheme();
      },
    );
  }
}
