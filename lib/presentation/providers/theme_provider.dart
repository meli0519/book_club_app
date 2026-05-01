import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gestionar el modo de tema de la aplicación
/// Sigue las guías de arquitectura: Presentation Layer - Providers
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeModeKey = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Carga el modo de tema guardado en SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeModeKey);
      
      if (themeModeString != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      print('Error loading theme mode: $e');
      // Si hay error, mantener el valor por defecto (system)
    }
  }

  /// Guarda el modo de tema en SharedPreferences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.toString());
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }

  /// Cambia al tema claro
  Future<void> setLightMode() async {
    state = ThemeMode.light;
    await _saveThemeMode(ThemeMode.light);
  }

  /// Cambia al tema oscuro
  Future<void> setDarkMode() async {
    state = ThemeMode.dark;
    await _saveThemeMode(ThemeMode.dark);
  }

  /// Cambia al tema del sistema
  Future<void> setSystemMode() async {
    state = ThemeMode.system;
    await _saveThemeMode(ThemeMode.system);
  }

  /// Alterna entre tema claro y oscuro
  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }
}

/// Provider principal para el modo de tema
final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Provider helper para saber si el tema actual es oscuro
/// Útil para widgets que necesitan adaptar su UI según el tema
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  
  // Si es system, necesitamos verificar el brillo del sistema
  // Este provider es solo para referencia, en widgets usa Theme.of(context).brightness
  return themeMode == ThemeMode.dark;
});
