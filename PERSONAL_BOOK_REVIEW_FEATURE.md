# Funcionalidad de Reseñas para Libros Personales

## Resumen

Se ha agregado la funcionalidad de reseñas para libros personales. Ahora, cuando un usuario marca un libro personal como "Leído" (status: `read`), puede agregar una reseña que incluye:

- **Frases favoritas**: Al menos una frase favorita del libro (requerido)
- **Pensamientos**: Texto libre opcional para compartir impresiones generales sobre el libro (máximo 2000 caracteres)

## Archivos Creados

### 1. `lib/domain/models/personal_book_review.dart`
Modelo de datos para la reseña de un libro personal. Similar a `FinalReview` pero simplificado para libros personales.

**Campos:**
- `favoritePhrases`: Lista de frases favoritas (requerido, al menos una)
- `thoughts`: Texto libre opcional con pensamientos sobre el libro
- `createdAt`: Fecha de creación de la reseña

### 2. `lib/presentation/widgets/personal_book/personal_review_form.dart`
Widget de formulario para crear y mostrar reseñas de libros personales.

**Características:**
- Solo se muestra cuando el libro tiene status `read`
- Permite agregar múltiples frases favoritas
- Campo de texto opcional para pensamientos (máximo 2000 caracteres)
- Una vez enviada, muestra un resumen de solo lectura
- Validación: requiere al menos una frase favorita

## Archivos Modificados

### 1. `lib/domain/models/personal_book.dart`
- Agregado campo `review` de tipo `PersonalBookReview?`
- Actualizado `fromMap()` para deserializar la reseña
- Actualizado `toMap()` para serializar la reseña
- Actualizado constructor para incluir el campo `review`

### 2. `lib/presentation/screens/personal_books/personal_book_detail_screen.dart`
- Importado `PersonalBookReview` y `PersonalReviewForm`
- Agregado método `_saveReview()` para guardar la reseña
- Integrado `PersonalReviewForm` en `_BookDetailContent`
- El formulario se muestra entre el rating y las notas

### 3. `lib/l10n/app_en.arb` y `lib/l10n/app_es.arb`
Agregadas las siguientes claves de traducción:
- `personalBookReviewTitle`: "Book Review" / "Reseña del Libro"
- `personalBookReviewThoughtsLabel`: "Your Thoughts" / "Tus Pensamientos"
- `personalBookReviewThoughtsHint`: Hint para el campo de pensamientos
- `personalBookReviewSubmittedSuccess`: Mensaje de éxito
- `personalBookReviewSubmitError`: Mensaje de error

## Estructura de Datos en Firestore

La reseña se almacena como un campo anidado en el documento del libro personal:

```
users/{uid}/personal_books/{bookId}
  ├── title: string
  ├── author: string
  ├── status: string
  ├── rating: number (opcional)
  ├── review: {
  │     ├── favoritePhrases: array<string>
  │     ├── thoughts: string (opcional)
  │     └── createdAt: timestamp
  │   }
  └── ... otros campos
```

## Flujo de Usuario

1. Usuario crea un libro personal con cualquier status
2. Usuario marca el libro como "Leído" (status: `read`)
3. En la pantalla de detalle, aparecen:
   - Widget de calificación (1-5 estrellas)
   - **Formulario de reseña** (nuevo)
   - Campo de notas personales
4. Usuario completa la reseña:
   - Agrega al menos una frase favorita
   - Opcionalmente escribe sus pensamientos
   - Presiona "Enviar Reseña"
5. La reseña se guarda y se muestra en modo solo lectura

## Validaciones

- **Frases favoritas**: Al menos una es requerida
- **Pensamientos**: Opcional, máximo 2000 caracteres
- **Status**: Solo disponible cuando el libro está marcado como "Leído"

## Diferencias con Reseñas de Libros del Club

| Característica | Libros del Club | Libros Personales |
|----------------|-----------------|-------------------|
| Frases favoritas | ✓ | ✓ |
| Preguntas configurables | ✓ | ✗ |
| Texto libre | ✗ | ✓ (Pensamientos) |
| Almacenamiento | Subcolección `reviews` | Campo anidado `review` |
| Una por usuario | ✓ | ✓ |

## Arquitectura

La implementación sigue las guías de arquitectura del proyecto:

- **Domain Layer**: Modelo `PersonalBookReview` en `lib/domain/models/`
- **Presentation Layer**: 
  - Widget `PersonalReviewForm` en `lib/presentation/widgets/personal_book/`
  - Integración en `PersonalBookDetailScreen`
- **Data Layer**: Usa el servicio existente `PersonalBookService` para guardar
- **Internacionalización**: Textos en español e inglés

## Testing

Para probar la funcionalidad:

1. Crear un libro personal
2. Cambiar su status a "Leído"
3. Abrir el detalle del libro
4. Completar el formulario de reseña
5. Verificar que se muestre el resumen de solo lectura
6. Verificar que los datos se guarden correctamente en Firestore

## Próximos Pasos (Opcional)

- Agregar la posibilidad de editar una reseña ya enviada
- Mostrar las reseñas en la lista de libros personales
- Agregar estadísticas de reseñas (total de frases favoritas, etc.)
