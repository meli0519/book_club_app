# Spec: Selección de Preguntas de Reseña en Libros Personales

## Resumen

Permitir al usuario elegir qué preguntas de reseña responder cuando finaliza un libro personal, en lugar de responder todas las preguntas disponibles.

## Requisitos Actuales

- Los libros personales tienen un campo `review` de tipo `PersonalBookReview`
- `PersonalBookReview` actualmente tiene: `favoritePhrases` (lista) y `thoughts` (opcional)
- Existe una colección global `reviewQuestions` con preguntas que se usan para los libros de club
- Al finalizar un libro personal, se muestra un formulario de review actualmente estático

## Requisitos Nuevos

1. **Selección de preguntas**: El usuario debe poder seleccionar qué preguntas de reseña responder al finalizar un libro personal
2. **Almacenamiento**: Las preguntas seleccionadas deben guardarse junto con el review
3. **Formulario dinámico**: El formulario debe mostrar solo las preguntas seleccionadas
4. **Persistencia**: Las preguntas seleccionadas deben persistir y mostrarse al editar el review

## Diseño Propuesto

### 1. Actualizar `PersonalBookReview` Model

**Ubicación:** `lib/domain/models/personal_book_review.dart`

```dart
class PersonalBookReview {
  final List<String> favoritePhrases;
  final String? thoughts;
  final List<String> selectedQuestionIds; // NUEVO: IDs de preguntas seleccionadas
  final Map<String, String> questionAnswers; // NUEVO: Respuestas a las preguntas
  final DateTime createdAt;
  
  // ... fromMap y toMap actualizados
}
```

### 2. Actualizar `PersonalBookReviewForm` Widget

**Ubicación:** `lib/presentation/widgets/personal_book/personal_review_form.dart`

- Agregar un paso previo para seleccionar preguntas antes de responder
- Mostrar lista de preguntas disponibles con checkboxes
- Permitir al usuario seleccionar/deseleccionar preguntas
- Guardar selección y mostrar formulario de preguntas

### 3. Actualizar `PersonalBookService`

**Ubicación:** `lib/data/services/personal_book_service.dart`

- No requiere cambios (ya guarda el review completo como mapa anidado)

### 4. Actualizar UI en `PersonalBookDetailScreen`

**Ubicación:** `lib/presentation/screens/personal_books/personal_book_detail_screen.dart`

- Modificar el comportamiento del formulario para incluir selección de preguntas
- Mostrar resumen de preguntas seleccionadas en el modo de solo lectura

## Implementación

### Paso 1: Actualizar modelo `PersonalBookReview`

```dart
class PersonalBookReview {
  final List<String> favoritePhrases;
  final String? thoughts;
  final List<String> selectedQuestionIds; // NUEVO
  final Map<String, String> questionAnswers; // NUEVO
  final DateTime createdAt;
  
  // ... actualizar fromMap y toMap
}
```

### Paso 2: Actualizar widget `PersonalReviewForm`

- Agregar estado para selección de preguntas
- Agregar paso de selección antes del formulario
- Mostrar preguntas seleccionadas en el resumen

### Paso 3: Actualizar `ReviewQuestionService` (si es necesario)

- Agregar método para obtener preguntas por ID
- O usar el stream existente y filtrar en el widget

## Consideraciones

- Las preguntas seleccionadas deben guardarse en Firestore como parte del review
- El formulario debe ser intuitivo y mostrar claramente qué preguntas se están respondiendo
- Debe mantenerse la compatibilidad con reviews existentes que no tengan esta información

## Archivos a Modificar

1. `lib/domain/models/personal_book_review.dart`
2. `lib/presentation/widgets/personal_book/personal_review_form.dart`
3. `lib/presentation/screens/personal_books/personal_book_detail_screen.dart` (posiblemente)
4. `lib/presentation/providers/review_provider.dart` (para cargar preguntas)
