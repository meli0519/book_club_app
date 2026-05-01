# Plan de Implementación: Mis Libros Personales (personal-books)

## Overview

Implementación incremental de la feature "Mis Libros Personales" siguiendo la arquitectura en capas del proyecto (Domain → Data → Presentation). Cada tarea construye sobre la anterior, terminando con la integración completa en la navegación de la app.

## Tasks

- [x] 1. Modelo de dominio y constantes
  - Crear `lib/domain/models/personal_book.dart` con la clase `PersonalBook` (campos: `id`, `userId`, `title`, `author`, `description`, `coverUrl`, `status`, `notes`, `rating`, `createdAt`, `updatedAt`, `startedAt`, `finishedAt`)
  - Implementar `PersonalBook.fromMap(Map<String, dynamic> map, String id, String userId)` convirtiendo `Timestamp` a `DateTime`
  - Implementar `PersonalBook.toMap()` convirtiendo `DateTime` a `Timestamp`
  - Crear clase `PersonalBookStatus` con constantes `wantToRead`, `reading`, `read` y lista `all`
  - Añadir `PersonalBook` al barrel file `lib/domain/models/models.dart` si existe
  - _Requirements: 2.1, 3.1, 3.2, 3.3_

  - [x] 1.1 Escribir property test para round-trip fromMap/toMap de PersonalBook
    - Verificar que `PersonalBook.fromMap(book.toMap(), book.id, book.userId)` produce un objeto igual al original para cualquier `PersonalBook` válido
    - Usar `glados` con generadores para todos los campos opcionales
    - _Requirements: 2.1_

- [x] 2. Servicio de datos (PersonalBookService)
  - Crear `lib/data/services/personal_book_service.dart` con la clase `PersonalBookService`
  - Implementar `watchPersonalBooks(String uid)`: stream de `users/{uid}/personal_books` ordenado por `updatedAt` descendente
  - Implementar `watchPersonalBooksByStatus(String uid, String status)`: stream filtrado por campo `status`
  - Implementar `watchPersonalBook(String uid, String bookId)`: stream de un documento individual
  - Implementar `getPersonalBook(String uid, String bookId)`: lectura única
  - Implementar `createPersonalBook(String uid, PersonalBook book, Uint8List? imageBytes, String? imageFileName)`: si `imageBytes != null`, subir a Storage antes de guardar el documento
  - Implementar `updatePersonalBook(String uid, String bookId, Map<String, dynamic> fields)`: actualiza solo los campos del mapa más `updatedAt`
  - Implementar `deletePersonalBook(String uid, String bookId)`: elimina documento y portada en Storage si existe
  - Implementar `uploadCover(String uid, String bookId, Uint8List bytes, String fileName)`: sube imagen y retorna URL
  - Cada método DEBE tener try-catch con `FirebaseException` y error genérico
  - _Requirements: 1.2, 2.1, 2.3, 3.1, 4.1, 5.1, 5.2_

  - [x] 2.1 Escribir property test P1: Aislamiento de libros personales por usuario
    - **Property 1: Aislamiento de libros personales por usuario**
    - Verificar que `watchPersonalBooks(uid)` retorna únicamente documentos cuyo `userId == uid`
    - Usar Firestore Emulator; generar listas de `PersonalBook` con `userId` mixtos
    - **Validates: Requirements 1.2**

  - [x] 2.2 Escribir property test P2: Creación preserva todos los campos requeridos
    - **Property 2: Creación de Personal_Book preserva todos los campos requeridos**
    - Para cualquier par válido `(title, author)`, verificar que el documento guardado contiene `title`, `author`, `status == 'want_to_read'`, `createdAt` y `updatedAt`
    - **Validates: Requirements 2.1**

  - [x] 2.3 Escribir property test P4: Actualización parcial preserva campos no modificados
    - **Property 4: Actualización parcial preserva campos no modificados**
    - Para cualquier `PersonalBook` existente y cualquier subconjunto de campos, verificar que `updatePersonalBook` solo modifica los campos del mapa más `updatedAt`
    - **Validates: Requirements 3.1**

  - [x] 2.4 Escribir property test P5: Transiciones de estado registran timestamps correctos
    - **Property 5: Transiciones de estado registran timestamps correctos**
    - Al cambiar `status` a `'read'`, verificar que `finishedAt >= createdAt`
    - Al cambiar `status` a `'reading'` sin `startedAt` previo, verificar que `startedAt >= createdAt`
    - Al cambiar `status` a `'reading'` con `startedAt` existente, verificar que no se sobreescribe
    - **Validates: Requirements 3.2, 3.3**

- [x] 3. Checkpoint — Capa de datos funcional
  - Asegurar que todos los tests de la capa de datos pasan. Consultar al usuario si hay dudas sobre el comportamiento esperado de Storage Emulator.

- [x] 4. Providers de Riverpod
  - Crear `lib/presentation/providers/personal_book_provider.dart`
  - Implementar `personalBookServiceProvider` como `Provider<PersonalBookService>`
  - Implementar `personalBooksStreamProvider` como `StreamProvider<List<PersonalBook>>` usando `authStateProvider`; retornar `Stream.empty()` si el usuario es null
  - Implementar `personalBooksByStatusProvider` como `StreamProvider.family<List<PersonalBook>, String>`
  - Implementar `personalBookStreamProvider` como `StreamProvider.family<PersonalBook?, String>`
  - _Requirements: 1.2, 5.1, 5.2_

  - [x] 4.1 Escribir property test P6: Listado ordenado por updatedAt descendente
    - **Property 6: Listado ordenado por updatedAt descendente**
    - Para cualquier colección de `PersonalBook`, verificar que la lista retornada cumple `books[i].updatedAt >= books[i+1].updatedAt` para todo par adyacente
    - **Validates: Requirements 5.1**

  - [x] 4.2 Escribir property test P7: Filtrado por status retorna solo libros con ese status
    - **Property 7: Filtrado por status retorna solo libros con ese status**
    - Para cualquier conjunto de `PersonalBook` con statuses mixtos y cualquier valor `s ∈ {want_to_read, reading, read}`, verificar que `watchPersonalBooksByStatus(uid, s)` retorna únicamente libros con `status == s`
    - **Validates: Requirements 5.2**

- [x] 5. Widgets reutilizables de Personal Books
  - Crear `lib/presentation/widgets/personal_book/personal_book_card.dart`: tarjeta con portada (o placeholder), título, autor y chip de status; navega a detalle al hacer tap
  - Crear `lib/presentation/widgets/personal_book/personal_book_status_chip.dart`: chip con color y etiqueta según `PersonalBookStatus`
  - Crear `lib/presentation/widgets/personal_book/personal_book_status_filter.dart`: fila de chips filtrables (Todos / Quiero leer / Leyendo / Leído)
  - Crear `lib/presentation/widgets/personal_book/personal_note_field.dart`: `TextFormField` con contador de caracteres en tiempo real; deshabilita guardado y muestra error inline si supera 5000 chars
  - Crear `lib/presentation/widgets/personal_book/personal_rating_widget.dart`: control de 5 estrellas; solo visible/habilitado cuando `status == 'read'`
  - Todos los textos visibles deben usar `AppLocalizations` (español e inglés)
  - _Requirements: 5.1, 6.2, 6.3, 7.1, 9.1_

  - [x] 5.1 Escribir property test P3: Validación de campos obligatorios (title y author)
    - **Property 3: Validación de campos obligatorios (title y author)**
    - Para cualquier cadena compuesta solo de espacios o vacía usada como `title` o `author`, verificar que el formulario no envía la petición y muestra error inline
    - **Validates: Requirements 2.2, 3.4**

  - [x] 5.2 Escribir property test P8: Validación de longitud de notas
    - **Property 8: Validación de longitud de notas**
    - Para cualquier cadena, verificar que `PersonalNoteField` acepta el guardado si y solo si `length <= 5000`; cadenas con más de 5000 chars deben mostrar error y no enviar
    - **Validates: Requirements 6.2, 6.3**

- [x] 6. PersonalBookFormScreen (crear y editar)
  - Crear `lib/presentation/screens/personal_books/personal_book_form_screen.dart`
  - Recibir parámetro opcional `bookId`; si es null → modo creación, si tiene valor → modo edición (cargar datos existentes)
  - Campos: `title` (obligatorio), `author` (obligatorio), `description` (opcional), portada (image picker, opcional), `status` (selector de `PersonalBookStatus.all`)
  - Validar `title` y `author` no vacíos con error inline antes de enviar
  - En modo edición, pre-rellenar todos los campos con los valores actuales del `PersonalBook`
  - Al guardar en modo creación: llamar `createPersonalBook`; al guardar en modo edición: llamar `updatePersonalBook` con solo los campos modificados más `updatedAt`
  - Al cambiar `status` a `'reading'`: incluir `startedAt` en el mapa de actualización solo si no existía previamente
  - Al cambiar `status` a `'read'`: incluir `finishedAt` en el mapa de actualización
  - Mostrar `CircularProgressIndicator` durante la operación; mostrar `SnackBar` de error si falla
  - Navegar de vuelta a `PersonalBooksScreen` tras éxito
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 9.2, 9.3, 9.4_

- [x] 7. PersonalBooksScreen (listado)
  - Crear `lib/presentation/screens/personal_books/personal_books_screen.dart`
  - Observar `personalBooksStreamProvider`; mostrar `CircularProgressIndicator` mientras carga
  - Mostrar `PersonalBookStatusFilter` en la parte superior; al seleccionar un filtro, cambiar al `personalBooksByStatusProvider` correspondiente
  - Renderizar lista de `PersonalBookCard`; mostrar widget de estado vacío con botón "Agregar libro" cuando la lista esté vacía
  - Incluir `FloatingActionButton` que navega a `PersonalBookFormScreen` en modo creación
  - Mostrar `SnackBar` de error descriptivo si el stream falla, sin bloquear navegación
  - _Requirements: 1.1, 2.5, 4.2, 5.1, 5.2, 5.3, 9.1, 9.2, 9.3_

- [x] 8. PersonalBookDetailScreen (detalle, notas y calificación)
  - Crear `lib/presentation/screens/personal_books/personal_book_detail_screen.dart`
  - Recibir `bookId` como parámetro; observar `personalBookStreamProvider(bookId)`
  - Mostrar todos los campos del `PersonalBook`: portada, título, autor, descripción, status, `startedAt`, `finishedAt`
  - Incluir `PersonalNoteField` pre-rellenado con `notes` actuales; botón de guardar nota llama a `updatePersonalBook` con el campo `notes` y `updatedAt`
  - Mostrar `PersonalRatingWidget` únicamente cuando `status == 'read'`; al cambiar la calificación, llamar a `updatePersonalBook` con `rating` y `updatedAt`
  - Si `status != 'read'` y el usuario intenta calificar, mostrar `SnackBar` informativo
  - Botón de editar navega a `PersonalBookFormScreen` en modo edición
  - Botón de eliminar muestra `AlertDialog` de confirmación; al confirmar, llama a `deletePersonalBook` y navega de vuelta a `PersonalBooksScreen`
  - Mostrar `SnackBar` de error si cualquier operación falla
  - _Requirements: 4.1, 4.2, 4.3, 5.4, 6.1, 6.4, 7.1, 7.2, 7.3, 7.4, 9.2, 9.3_

  - [x] 8.1 Escribir property test P9: Upsert de calificación garantiza exactamente un valor por libro
    - **Property 9: Upsert de calificación garantiza exactamente un valor por libro**
    - Para cualquier `PersonalBook` con `status == 'read'`, independientemente de cuántas veces se guarde una calificación, verificar que `rating` contiene exactamente el último valor enviado (1–5) y `updatedAt` refleja la última actualización
    - **Validates: Requirements 7.2**

  - [x] 8.2 Escribir property test P10: Calificación rechazada para libros no leídos
    - **Property 10: Calificación rechazada para libros no leídos**
    - Para cualquier `PersonalBook` con `status ∈ {want_to_read, reading}`, verificar que cualquier intento de guardar `rating` es rechazado y el campo `rating` del documento no se modifica
    - **Validates: Requirements 7.3**

- [x] 9. Checkpoint — Pantallas funcionales
  - Asegurar que todos los tests de widgets y providers pasan. Consultar al usuario si hay dudas sobre el flujo de navegación o el comportamiento de los formularios.

- [x] 10. Integración en navegación y drawer
  - Añadir constantes de rutas en `lib/presentation/routes/app_router.dart`:
    - `personalBooks = '/personal-books'`
    - `createPersonalBook = '/personal-books/create'`
    - `personalBookDetailPath = '/personal-books/:id'`
    - `editPersonalBookPath = '/personal-books/:id/edit'`
    - Métodos helper `personalBookDetail(String id)` y `editPersonalBook(String id)`
  - Registrar las cuatro rutas en el `GoRouter` apuntando a las pantallas correspondientes
  - Añadir entrada "Mis Libros Personales" al `Drawer` de `HomeScreen`, visible únicamente para Members con membresía activa
  - _Requirements: 1.1, 5.4_

- [x] 11. Internacionalización (i18n)
  - Añadir todas las cadenas de texto de la feature a `lib/l10n/app_es.arb` (español) y `lib/l10n/app_en.arb` (inglés)
  - Cadenas requeridas: títulos de pantallas, etiquetas de campos, mensajes de error inline, textos de `SnackBar`, etiquetas de status (`want_to_read`, `reading`, `read`), texto de estado vacío, textos del diálogo de confirmación de eliminación, placeholder de portada
  - Reemplazar cualquier cadena hardcodeada en widgets y pantallas por referencias a `AppLocalizations`
  - _Requirements: 9.1_

- [x] 12. Reglas de seguridad Firestore y Storage
  - Añadir a `firestore.rules` la regla para `users/{userId}/personal_books/{bookId}`: solo lectura/escritura si `request.auth.uid == userId`
  - Añadir a `storage.rules` la regla para `personal_books/{userId}/{allPaths=**}`: solo lectura/escritura si `request.auth.uid == userId`
  - _Requirements: 1.3, 8.1, 8.2_

- [x] 13. Tests de integración con Firebase Emulator
  - Crear `test/integration/personal_books_security_test.dart`

  - [x] 13.1 Smoke test: reglas Firestore — usuario B no puede leer/escribir libros de usuario A
    - Verificar con Firebase Emulator Suite que `users/{uidA}/personal_books` rechaza operaciones de `uidB`
    - _Requirements: 1.3, 8.1_

  - [x] 13.2 Smoke test: reglas Storage — usuario B no puede acceder a portadas de usuario A
    - Verificar con Storage Emulator que `personal_books/{uidA}/` rechaza acceso de `uidB`
    - _Requirements: 8.2_

  - [x] 13.3 Integration test: subida de portada a Storage
    - Crear un `PersonalBook` con portada, verificar que `coverUrl` apunta a `personal_books/{uid}/{bookId}/cover`
    - _Requirements: 2.3_

  - [x] 13.4 Integration test: eliminación con portada
    - Eliminar un `PersonalBook` que tiene portada, verificar que el archivo en Storage también se elimina
    - _Requirements: 4.1_

  - [x] 13.5 Smoke test: aislamiento en pantallas del club
    - Verificar mediante revisión de código y tests que ninguna query del club toca la subcolección `personal_books`
    - _Requirements: 8.3_

- [ ] 14. Checkpoint final — Integración completa
  - Asegurar que todos los tests pasan (unit, property, widget e integración). Verificar que la entrada del drawer navega correctamente a `PersonalBooksScreen`. Consultar al usuario si hay dudas antes de cerrar la feature.

## Notes

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia los requisitos específicos para trazabilidad completa
- Los property tests usan `glados` con mínimo 100 iteraciones por propiedad
- Los tests de integración requieren Firebase Emulator Suite configurado localmente
- El lenguaje de implementación es **Dart/Flutter** siguiendo las guías de arquitectura del proyecto
- Los timestamps de Firestore deben convertirse con `Timestamp.fromDate()` al escribir y `.toDate()` al leer
