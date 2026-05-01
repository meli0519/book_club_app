# Sistema de Temas - Alquimia Literaria

Este documento explica cómo funciona el sistema de temas claro/oscuro en la aplicación Book Club App.

## Características

- ✅ Tema claro (Light)
- ✅ Tema oscuro (Dark)
- ✅ Tema del sistema (automático según configuración del dispositivo)
- ✅ Persistencia de la preferencia del usuario
- ✅ Cambio instantáneo sin reiniciar la app
- ✅ Internacionalización (español e inglés)

## Arquitectura

El sistema de temas sigue las guías de arquitectura del proyecto:

### 1. Provider (Presentation Layer)
**Ubicación:** `lib/presentation/providers/theme_provider.dart`

```dart
// Provider principal para el modo de tema
final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
```

**Funcionalidades:**
- `setLightMode()` - Cambia al tema claro
- `setDarkMode()` - Cambia al tema oscuro
- `setSystemMode()` - Usa el tema del sistema
- `toggleTheme()` - Alterna entre claro y oscuro
- Persistencia automática usando `SharedPreferences`

### 2. Widgets (Presentation Layer)
**Ubicación:** `lib/presentation/widgets/common/`

#### ThemeToggleButton
Botón simple para alternar entre tema claro y oscuro.

```dart
import 'package:book_club_app/presentation/widgets/common/theme_toggle_button.dart';

// En tu AppBar o donde lo necesites
AppBar(
  actions: [
    ThemeToggleButton(),
  ],
)
```

#### ThemeSelectorDialog
Diálogo completo con tres opciones: Sistema, Claro, Oscuro.

```dart
import 'package:book_club_app/presentation/widgets/common/theme_selector_dialog.dart';

// Para mostrar el diálogo
ThemeSelectorDialog.show(context);
```

### 3. Integración en main.dart
El `main.dart` ya está configurado para usar el provider:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final themeMode = ref.watch(themeModeProvider);
  
  return MaterialApp.router(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: themeMode, // Controlado por el provider
    // ...
  );
}
```

## Uso en la Aplicación

### Opción 1: Desde el Drawer (Ya implementado)
El drawer de navegación ya incluye una opción "Seleccionar Tema" que abre el diálogo completo.

### Opción 2: Botón en AppBar
Puedes agregar el botón de alternancia en cualquier AppBar:

```dart
AppBar(
  title: Text('Mi Pantalla'),
  actions: [
    ThemeToggleButton(),
  ],
)
```

### Opción 3: Programáticamente
Puedes cambiar el tema desde cualquier widget con acceso a `ref`:

```dart
// En un ConsumerWidget o ConsumerStatefulWidget
final themeNotifier = ref.read(themeModeProvider.notifier);

// Cambiar a tema oscuro
themeNotifier.setDarkMode();

// Cambiar a tema claro
themeNotifier.setLightMode();

// Usar tema del sistema
themeNotifier.setSystemMode();

// Alternar entre claro y oscuro
themeNotifier.toggleTheme();
```

## Temas Disponibles

### Tema Claro (Light)
- Fondo blanco/claro
- Colores principales: Verde esmeralda (#2D9B7F)
- Acentos: Púrpura místico (#4A148C)
- Diseñado para lectura diurna

### Tema Oscuro (Dark)
- Fondo oscuro cósmico (#0D1B2A)
- Colores principales: Verde esmeralda claro (#4ECDB3)
- Efecto de brillo en cards
- Diseñado para lectura nocturna

### Tema del Sistema
- Se adapta automáticamente según la configuración del dispositivo
- Cambia dinámicamente si el usuario cambia el tema del sistema

## Persistencia

La preferencia del usuario se guarda automáticamente usando `SharedPreferences`:
- Se carga al iniciar la app
- Se guarda cada vez que el usuario cambia el tema
- Persiste entre sesiones de la app

## Internacionalización

Los textos del selector de tema están traducidos:

**Español:**
- "Seleccionar Tema"
- "Sistema" - "Usar el tema del sistema"
- "Claro" - "Tema claro"
- "Oscuro" - "Tema oscuro"

**Inglés:**
- "Select Theme"
- "System" - "Use system theme"
- "Light" - "Light theme"
- "Dark" - "Dark theme"

## Dependencias

```yaml
dependencies:
  shared_preferences: ^2.2.2  # Para persistencia
  flutter_riverpod: ^2.5.1    # Para gestión de estado
```

## Ejemplo Completo

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_club_app/presentation/providers/theme_provider.dart';
import 'package:book_club_app/presentation/widgets/common/theme_selector_dialog.dart';

class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Pantalla'),
        actions: [
          // Opción 1: Botón simple de alternancia
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark 
                ? Icons.light_mode 
                : Icons.dark_mode
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          
          // Opción 2: Abrir diálogo completo
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () {
              ThemeSelectorDialog.show(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Tema actual: ${themeMode.name}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(themeModeProvider.notifier).setLightMode();
              },
              child: const Text('Tema Claro'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(themeModeProvider.notifier).setDarkMode();
              },
              child: const Text('Tema Oscuro'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(themeModeProvider.notifier).setSystemMode();
              },
              child: const Text('Tema del Sistema'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Testing

Para probar el sistema de temas:

1. **Cambio manual:**
   - Abre el drawer
   - Toca "Seleccionar Tema"
   - Elige una opción
   - Verifica que el tema cambie inmediatamente

2. **Persistencia:**
   - Cambia el tema
   - Cierra la app completamente
   - Vuelve a abrir la app
   - Verifica que el tema seleccionado se mantenga

3. **Tema del sistema:**
   - Selecciona "Sistema"
   - Cambia el tema en la configuración del dispositivo
   - Verifica que la app se adapte automáticamente

## Notas Técnicas

- El provider se inicializa automáticamente al arrancar la app
- La carga de la preferencia guardada es asíncrona pero no bloquea la UI
- Si hay error al cargar/guardar, se usa el valor por defecto (sistema)
- El tema se aplica inmediatamente sin necesidad de reiniciar

## Futuras Mejoras

Posibles mejoras para el futuro:
- [ ] Temas personalizados por el usuario
- [ ] Programación de cambio automático (ej: oscuro de noche)
- [ ] Más variantes de colores
- [ ] Animaciones de transición entre temas
