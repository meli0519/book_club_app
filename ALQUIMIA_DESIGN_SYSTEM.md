# Sistema de Diseño - Alquimia Literaria

## 🎨 Paleta de Colores

### Colores Principales

Inspirados en el logo del club, que presenta elementos místicos y literarios:

#### Verde Alquímico (Primary)
- **Main**: `#2D9B7F` - Verde esmeralda principal del logo
- **Dark**: `#1A5F4F` - Tonalidad más oscura para contraste
- **Light**: `#4ECDB3` - Tonalidad más clara para acentos

#### Púrpura Místico (Secondary)
- **Deep Purple**: `#4A148C` - Representa la magia y el misterio

#### Colores de Acento
- **Crystal White**: `#F8F9FA` - Blanco cristalino para elementos destacados
- **Magic Gold**: `#FFD700` - Dorado para estrellas y elementos mágicos
- **Dark Background**: `#0D1B2A` - Fondo oscuro cósmico para tema dark

### Uso de Colores

```dart
// Acceder a los colores del tema
final theme = Theme.of(context);
final primaryColor = theme.colorScheme.primary; // Verde alquímico
final secondaryColor = theme.colorScheme.secondary; // Púrpura místico
final tertiaryColor = theme.colorScheme.tertiary; // Dorado mágico
```

## 🌓 Temas

### Tema Claro (Light Theme)
- Fondo: Blanco suave con gradiente sutil
- Elementos: Verde esmeralda con sombras suaves
- Texto: Oscuro sobre fondos claros
- Cards: Bordes verdes translúcidos con sombra sutil

### Tema Oscuro (Dark Theme)
- Fondo: Negro cósmico (#0D1B2A) con partículas verdes flotantes
- Elementos: Verde brillante con efecto de brillo
- Texto: Blanco cristalino sobre fondos oscuros
- Cards: Bordes verdes luminosos con efecto de resplandor

## 📐 Espaciado

Sistema de espaciado basado en múltiplos de 8:

```dart
AppTheme.spacingXs  // 8px  - Espaciado extra pequeño
AppTheme.spacingSm  // 16px - Espaciado pequeño
AppTheme.spacingMd  // 24px - Espaciado mediano
AppTheme.spacingLg  // 32px - Espaciado grande
```

## 🔲 Border Radius

```dart
AppTheme.radiusSm   // 8px  - Bordes sutiles
AppTheme.radiusMd   // 12px - Bordes medianos (default para cards)
AppTheme.radiusLg   // 16px - Bordes grandes (FAB, modales)
```

## 🎭 Componentes Personalizados

### 1. AlchemicalCard
Card con estilo místico, bordes brillantes y efecto de resplandor opcional.

```dart
AlchemicalCard(
  showGlow: true, // Efecto de brillo
  onTap: () {}, // Opcional
  child: YourContent(),
)
```

**Características:**
- Bordes verdes translúcidos
- Sombra con color del tema
- Efecto de resplandor en tema oscuro
- Soporte para tap

### 2. MysticalDivider
Divisor decorativo con línea ondulada y icono de libro central.

```dart
const MysticalDivider(
  height: 40,
  color: Colors.green, // Opcional
)
```

**Características:**
- Línea ondulada que simula humo/serpiente del logo
- Icono de libro en el centro
- Animación sutil

### 3. StarRatingDisplay
Muestra calificaciones con estrellas doradas místicas.

```dart
const StarRatingDisplay(
  rating: 4.5,
  maxRating: 5,
  size: 20,
  showValue: true, // Muestra el número
)
```

**Características:**
- Estrellas doradas (#FFD700)
- Soporte para medias estrellas
- Opción de mostrar valor numérico

### 4. AlquimiaLogo
Logo animado del club con texto y elementos decorativos.

```dart
const AlquimiaLogo(
  size: 120,
  showText: true,
  animate: true, // Animación de entrada
)
```

**Características:**
- Animación de fade-in y scale
- Icono de libro con resplandor
- Texto "Alquimia Literaria" con tipografía serif
- Elementos decorativos (estrellas/varitas)

### 5. AlchemicalBackground
Fondo decorativo con partículas flotantes animadas.

```dart
AlchemicalBackground(
  isDark: true,
  child: YourContent(),
)
```

**Características:**
- Gradiente de fondo
- Partículas verdes flotantes animadas
- Efecto de profundidad
- Optimizado para rendimiento

## 🔤 Tipografía

### Títulos
```dart
theme.textTheme.headlineLarge   // 32px, bold
theme.textTheme.headlineMedium  // 28px, bold
theme.textTheme.headlineSmall   // 24px, bold
```

### Títulos de Sección
```dart
theme.textTheme.titleLarge   // 22px, medium
theme.textTheme.titleMedium  // 16px, medium
theme.textTheme.titleSmall   // 14px, medium
```

### Cuerpo de Texto
```dart
theme.textTheme.bodyLarge   // 16px, regular
theme.textTheme.bodyMedium  // 14px, regular
theme.textTheme.bodySmall   // 12px, regular
```

### Etiquetas
```dart
theme.textTheme.labelLarge   // 14px, medium
theme.textTheme.labelMedium  // 12px, medium
theme.textTheme.labelSmall   // 11px, medium
```

## 🎨 Elementos del Logo

El logo de Alquimia Literaria incluye:

1. **Libro Abierto** - Base literaria del club
2. **Serpiente/Humo Místico** - Elemento alquímico y mágico
3. **Cristales** - Representan conocimiento y claridad
4. **Poción** - Símbolo de transformación
5. **Ave** - Libertad y elevación del espíritu
6. **Estrellas** - Magia y aspiraciones
7. **Manchas Verdes** - Efecto de acuarela/tinta mágica

Estos elementos se reflejan en:
- Colores verde esmeralda y dorado
- Iconografía de libros, estrellas y magia
- Efectos de partículas flotantes
- Bordes y sombras con resplandor

## 📱 Uso en Pantallas

### Ejemplo Completo

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Pantalla'),
      ),
      body: AlchemicalBackground(
        isDark: isDark,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          children: [
            const AlquimiaLogo(),
            const MysticalDivider(),
            AlchemicalCard(
              child: Column(
                children: [
                  Text('Contenido', style: theme.textTheme.titleLarge),
                  const StarRatingDisplay(rating: 4.5, showValue: true),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.auto_fix_high),
      ),
    );
  }
}
```

## 🎯 Mejores Prácticas

### 1. Consistencia
- Usar siempre los componentes personalizados cuando sea posible
- Mantener el espaciado consistente con las constantes de `AppTheme`
- Respetar la paleta de colores del tema

### 2. Accesibilidad
- Los colores tienen suficiente contraste para WCAG AA
- Tamaños de texto legibles (mínimo 12px)
- Áreas táctiles de al menos 48x48px

### 3. Rendimiento
- `AlchemicalBackground` usa animaciones optimizadas
- Evitar múltiples backgrounds animados en la misma pantalla
- Usar `const` constructors cuando sea posible

### 4. Tema Oscuro
- Siempre verificar que los componentes se vean bien en ambos temas
- Usar `theme.brightness` para detectar el tema actual
- Los colores se ajustan automáticamente

## 🚀 Pantalla de Demostración

Para ver todos los componentes en acción:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ThemeDemoScreen(),
  ),
);
```

La pantalla de demostración muestra:
- Logo animado
- Cards con diferentes estilos
- Botones de todos los tipos
- Campos de entrada
- Calificaciones con estrellas
- Chips y tags
- Divisores místicos
- Fondo animado

## 📦 Importación

```dart
// Tema
import 'package:book_club_app/presentation/theme/app_theme.dart';

// Widgets comunes
import 'package:book_club_app/presentation/widgets/common/common_widgets.dart';

// O importar individualmente
import 'package:book_club_app/presentation/widgets/common/alchemical_card.dart';
import 'package:book_club_app/presentation/widgets/common/mystical_divider.dart';
// etc.
```

## 🎨 Inspiración

El diseño está inspirado en:
- **Alquimia**: Transformación, magia, misterio
- **Literatura**: Libros, conocimiento, historias
- **Naturaleza**: Verde esmeralda, cristales, elementos naturales
- **Cosmos**: Estrellas, oscuridad, profundidad

El resultado es una experiencia visual que combina elegancia literaria con un toque de magia y misterio, perfecta para un club de lectura que explora mundos fantásticos y realidades transformadoras.

---

**Alquimia Literaria** - Donde la magia y la literatura se encuentran ✨📚
