# Guía del Selector de Idioma

## 📱 Funcionalidad Implementada

Se ha implementado un selector de idioma en la aplicación que permite a los usuarios cambiar entre español e inglés, o usar el idioma del sistema.

## 🎯 Ubicación

El selector de idioma se encuentra en:
- **Pantalla de Perfil** → Sección "Configuración" → "Idioma"

## 🔧 Archivos Creados/Modificados

### Nuevos Archivos

1. **`lib/presentation/providers/locale_provider.dart`**
   - Provider de Riverpod para gestionar el idioma de la aplicación
   - Guarda la preferencia del usuario en SharedPreferences
   - Soporta: Inglés, Español, o Sistema (automático)

2. **`lib/presentation/widgets/common/language_selector.dart`**
   - Widget que muestra el selector de idioma
   - Diálogo con las opciones disponibles
   - Indicador visual del idioma seleccionado

3. **`lib/presentation/widgets/common/theme_selector.dart`**
   - Widget similar para el selector de tema
   - Mantiene consistencia en el diseño

### Archivos Modificados

1. **`lib/main.dart`**
   - Agregado `locale: locale` al MaterialApp.router
   - Importado el `locale_provider`

2. **`lib/presentation/screens/profile/profile_screen.dart`**
   - Agregada sección de "Configuración"
   - Incluye selector de idioma y tema

3. **`lib/l10n/app_en.arb`** y **`lib/l10n/app_es.arb`**
   - Agregadas nuevas claves de traducción:
     - `languageDialogTitle`
     - `languageSystem`, `languageEnglish`, `languageSpanish`
     - `language`, `theme`, `settings`

## 🚀 Cómo Usar

### Para el Usuario Final

1. Abre la aplicación
2. Ve a tu perfil (menú lateral → "Mi Perfil")
3. En la sección "Configuración", toca "Idioma"
4. Selecciona una opción:
   - **Sistema**: Usa el idioma configurado en el teléfono
   - **English**: Fuerza el idioma inglés
   - **Español**: Fuerza el idioma español
5. El cambio se aplica inmediatamente

### Comportamiento

- **Persistencia**: La selección se guarda en el dispositivo y se mantiene entre sesiones
- **Cambio inmediato**: No requiere reiniciar la aplicación
- **Predeterminado**: Si no se ha seleccionado nada, usa el idioma del sistema

## 🏗️ Arquitectura

La implementación sigue las guías de arquitectura del proyecto:

```
Presentation Layer
├── Providers (locale_provider.dart)
│   └── Gestiona el estado del idioma
├── Widgets (language_selector.dart)
│   └── UI del selector
└── Screens (profile_screen.dart)
    └── Integra el selector

Data Layer
└── SharedPreferences
    └── Persiste la preferencia del usuario
```

## 🔄 Flujo de Datos

```
Usuario selecciona idioma
    ↓
LanguageSelector llama a LocaleNotifier
    ↓
LocaleNotifier actualiza el estado
    ↓
LocaleNotifier guarda en SharedPreferences
    ↓
MaterialApp.router recibe el nuevo locale
    ↓
Flutter recarga la UI con las nuevas traducciones
```

## 🧪 Pruebas

### Prueba Manual

1. **Cambio de idioma**:
   - Cambia entre inglés y español
   - Verifica que todos los textos cambien

2. **Persistencia**:
   - Cambia el idioma
   - Cierra la app completamente
   - Abre la app nuevamente
   - Verifica que el idioma se mantenga

3. **Modo Sistema**:
   - Selecciona "Sistema"
   - Cambia el idioma del teléfono
   - Verifica que la app cambie automáticamente

### Casos de Prueba

```dart
// Ejemplo de test unitario para el provider
test('LocaleNotifier should change to Spanish', () async {
  final notifier = LocaleNotifier();
  await notifier.setSpanish();
  expect(notifier.state?.languageCode, 'es');
});
```

## 📝 Notas Técnicas

### SharedPreferences Key
- Clave usada: `app_locale`
- Valores posibles: `null` (sistema), `'en'`, `'es'`

### Idiomas Soportados
- Inglés (`en`)
- Español (`es`)

Para agregar más idiomas:
1. Crear archivo `lib/l10n/app_XX.arb` (donde XX es el código del idioma)
2. Agregar `Locale('XX')` a `supportedLocales` en `main.dart`
3. Agregar opción en `language_selector.dart`

## 🎨 Diseño

El selector sigue el diseño de Material Design 3:
- Diálogo con opciones claras
- Indicador visual (✓) del idioma seleccionado
- Iconos descriptivos
- Colores del tema de la aplicación

## 🔐 Seguridad

- No se envía información del idioma al servidor
- La preferencia se guarda localmente en el dispositivo
- No afecta la seguridad de la aplicación

## 🐛 Solución de Problemas

### El idioma no cambia
- Verifica que los archivos `.arb` estén completos
- Ejecuta `flutter gen-l10n` para regenerar las traducciones
- Limpia el build: `flutter clean && flutter pub get`

### El idioma no persiste
- Verifica que SharedPreferences esté funcionando
- Revisa los permisos de la aplicación
- Verifica que no haya errores en los logs

## 📚 Referencias

- [Flutter Internationalization](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [Riverpod State Management](https://riverpod.dev/)
- [SharedPreferences](https://pub.dev/packages/shared_preferences)
