# Assets de Imágenes

## Logo de la aplicación

Coloca aquí el logo de la aplicación Book Club App.

### Archivos recomendados:

- **logo.png** - Logo principal (recomendado: 512x512px o mayor)
- **logo_white.png** - Variante en blanco para fondos oscuros (opcional)
- **logo_transparent.png** - Logo con fondo transparente (opcional)

### Formatos soportados:
- PNG (recomendado para logos con transparencia)
- JPG/JPEG
- SVG (requiere paquete adicional como `flutter_svg`)

### Uso en código:

```dart
// Imagen desde assets
Image.asset(
  'assets/images/logo.png',
  width: 200,
  height: 200,
)
```

### Notas:
- Asegúrate de que el archivo esté en esta carpeta antes de ejecutar la app
- Después de agregar imágenes, ejecuta `flutter pub get`
- Para diferentes resoluciones, puedes crear subcarpetas: 2.0x, 3.0x, etc.
