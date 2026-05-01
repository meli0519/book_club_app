import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gestionar el idioma de la aplicación
/// Sigue las guías de arquitectura: Presentation Layer - Providers
class LocaleNotifier extends StateNotifier<Locale?> {
  static const String _localeKey = 'app_locale';

  LocaleNotifier() : super(null) {
    _loadLocale();
  }

  /// Carga el idioma guardado en SharedPreferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      
      if (localeCode != null && localeCode.isNotEmpty) {
        state = Locale(localeCode);
      } else {
        // null significa usar el idioma del sistema
        state = null;
      }
    } catch (e) {
      // Si hay error, mantener el valor por defecto (null = sistema)
      state = null;
    }
  }

  /// Guarda el idioma en SharedPreferences
  Future<void> _saveLocale(String? localeCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (localeCode != null) {
        await prefs.setString(_localeKey, localeCode);
      } else {
        await prefs.remove(_localeKey);
      }
    } catch (e) {
      // Error al guardar, pero no afecta la funcionalidad
    }
  }

  /// Cambia al idioma inglés
  Future<void> setEnglish() async {
    state = const Locale('en');
    await _saveLocale('en');
  }

  /// Cambia al idioma español
  Future<void> setSpanish() async {
    state = const Locale('es');
    await _saveLocale('es');
  }

  /// Usa el idioma del sistema
  Future<void> setSystemLocale() async {
    state = null;
    await _saveLocale(null);
  }

  /// Cambia a un idioma específico por código
  Future<void> setLocale(String? localeCode) async {
    if (localeCode == null || localeCode.isEmpty) {
      await setSystemLocale();
    } else {
      state = Locale(localeCode);
      await _saveLocale(localeCode);
    }
  }
}

/// Provider principal para el idioma de la aplicación
/// null = usar idioma del sistema
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

/// Provider helper para obtener el código del idioma actual
/// Útil para mostrar en la UI qué idioma está seleccionado
final currentLocaleCodeProvider = Provider<String?>((ref) {
  final locale = ref.watch(localeProvider);
  return locale?.languageCode;
});
