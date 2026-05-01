---
inclusion: always
---

# Flutter Architecture Guidelines - Book Club App

Este documento define las reglas de arquitectura y mejores prácticas que DEBEN seguirse en toda la implementación de la aplicación Book Club App.

## Arquitectura en Capas

La aplicación DEBE seguir una arquitectura limpia separada en tres capas:

### 1. Presentation Layer (UI)
**Ubicación:** `lib/presentation/`

- **Screens:** `lib/presentation/screens/` - Pantallas completas de la app
- **Widgets:** `lib/presentation/widgets/` - Widgets reutilizables
- **Providers:** `lib/presentation/providers/` - Riverpod providers para estado de UI

**Reglas:**
- NO incluir lógica de negocio en widgets o screens
- NO hacer llamadas directas a Firebase desde la UI
- Usar providers para acceder a servicios y estado
- Mantener widgets pequeños y reutilizables

### 2. Domain Layer (Modelos)
**Ubicación:** `lib/domain/`

- **Models:** `lib/domain/models/` - Modelos de datos (AppUser, Book, Meeting, etc.)
- **Repositories (interfaces):** `lib/domain/repositories/` - Interfaces abstractas de repositorios

**Reglas:**
- Modelos inmutables con campos `final`
- Incluir métodos `fromMap()` y `toMap()` para serialización Firestore
- NO incluir lógica de Firebase en los modelos
- Usar `Timestamp` de Firestore para campos DateTime

### 3. Data Layer (Servicios y Firebase)
**Ubicación:** `lib/data/`

- **Services:** `lib/data/services/` - Servicios de Firebase
- **Repositories (implementaciones):** `lib/data/repositories/` - Implementaciones concretas

**Servicios requeridos:**
- `auth_service.dart` - Autenticación con Google
- `user_service.dart` - Operaciones CRUD de usuarios
- `book_service.dart` - Operaciones CRUD de libros
- `meeting_service.dart` - Operaciones CRUD de reuniones
- `comment_service.dart` - Operaciones de comentarios
- `rating_service.dart` - Operaciones de calificaciones
- `review_service.dart` - Operaciones de reseñas finales
- `review_question_service.dart` - Operaciones de preguntas de reseña
- `membership_service.dart` - Operaciones de membresías

**Reglas:**
- Cada servicio DEBE manejar errores con try-catch
- Usar `async/await` correctamente
- Retornar tipos específicos o `Future<void>`
- Usar streams (`Stream<T>`) para datos en tiempo real
- NO exponer instancias de Firebase directamente

## Gestión de Estado

**Manejador de estado:** Riverpod

### Providers

**Ubicación:** `lib/presentation/providers/`

**Tipos de providers a usar:**
- `Provider` - Para valores inmutables o servicios
- `StateProvider` - Para estado simple
- `StateNotifierProvider` - Para estado complejo con lógica
- `StreamProvider` - Para streams de Firestore
- `FutureProvider` - Para operaciones asíncronas

**Ejemplo de estructura:**
```dart
// lib/presentation/providers/auth_provider.dart
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// lib/presentation/providers/book_provider.dart
final bookServiceProvider = Provider<BookService>((ref) {
  return BookService();
});

final booksStreamProvider = StreamProvider<List<Book>>((ref) {
  final bookService = ref.watch(bookServiceProvider);
  return bookService.watchBooks();
});
```

## Código Limpio

### Reglas generales:
1. **Modularidad:** Dividir código en funciones y clases pequeñas
2. **DRY (Don't Repeat Yourself):** Evitar duplicación de código
3. **Nombres descriptivos:** Variables, funciones y clases con nombres claros
4. **Comentarios:** Solo cuando sea necesario explicar "por qué", no "qué"
5. **Formato:** Usar `dart format` antes de cada commit

### Manejo de errores:
```dart
// CORRECTO
Future<Book?> getBook(String bookId) async {
  try {
    final doc = await _firestore.collection('books').doc(bookId).get();
    if (!doc.exists) return null;
    return Book.fromMap(doc.data()!, doc.id);
  } on FirebaseException catch (e) {
    print('Error getting book: ${e.message}');
    rethrow;
  } catch (e) {
    print('Unexpected error: $e');
    rethrow;
  }
}

// INCORRECTO - Sin manejo de errores
Future<Book?> getBook(String bookId) async {
  final doc = await _firestore.collection('books').doc(bookId).get();
  return Book.fromMap(doc.data()!, doc.id);
}
```

### Async/await:
```dart
// CORRECTO
Future<void> createBookWithMeetings(Book book, List<Meeting> meetings) async {
  await bookService.createBook(book);
  for (final meeting in meetings) {
    await meetingService.createMeeting(meeting);
  }
}

// INCORRECTO - No esperar correctamente
Future<void> createBookWithMeetings(Book book, List<Meeting> meetings) async {
  bookService.createBook(book); // Falta await
  meetings.forEach((m) => meetingService.createMeeting(m)); // No funciona con async
}
```

## Navegación

**Ubicación:** `lib/presentation/routes/`

**Usar:** `go_router` para navegación declarativa

**Estructura de rutas:**
```dart
// lib/presentation/routes/app_router.dart
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/books',
      builder: (context, state) => const BookListScreen(),
    ),
    GoRoute(
      path: '/books/:id',
      builder: (context, state) {
        final bookId = state.pathParameters['id']!;
        return BookDetailScreen(bookId: bookId);
      },
    ),
  ],
  redirect: (context, state) {
    // Lógica de redirección basada en auth y membresía
  },
);
```

## UI y Widgets

### Widgets reutilizables

**Ubicación:** `lib/presentation/widgets/`

**Categorías:**
- `common/` - Botones, inputs, cards genéricos
- `book/` - Widgets específicos de libros
- `meeting/` - Widgets específicos de reuniones
- `comment/` - Widgets de comentarios
- `rating/` - Widgets de calificación

**Ejemplo:**
```dart
// lib/presentation/widgets/common/custom_button.dart
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const CircularProgressIndicator()
          : Text(label),
    );
  }
}
```

### Diseño:
- Usar `Theme` para colores y tipografía consistentes
- Crear `lib/presentation/theme/app_theme.dart`
- Espaciado consistente (8, 16, 24, 32)
- Responsive cuando sea posible

## Internacionalización (i18n)

**Paquete:** `flutter_localizations` + `intl`

**Ubicación:** `lib/l10n/`

**Idiomas soportados:**
- Español (es)
- Inglés (en)

**Estructura:**
```
lib/l10n/
  app_en.arb  # Traducciones en inglés
  app_es.arb  # Traducciones en español
```

**Uso en código:**
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// En widgets
Text(AppLocalizations.of(context)!.welcomeMessage)

// En providers (con ref)
final l10n = ref.watch(localizationProvider);
```

**Configuración en pubspec.yaml:**
```yaml
flutter:
  generate: true
  
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any
```

**Archivo l10n.yaml:**
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

## Base de Datos (Firestore)

### Buenas prácticas:

1. **Evitar anidación excesiva:**
   - Máximo 2 niveles de subcolecciones
   - Usar referencias cuando sea necesario

2. **Timestamps:**
   - Siempre usar `Timestamp.fromDate()` al escribir
   - Convertir con `.toDate()` al leer

3. **Normalización:**
   - Evitar duplicar datos grandes
   - Usar referencias para relaciones

4. **Índices:**
   - Crear índices para queries complejas
   - Documentar en `firestore.indexes.json`

5. **Reglas de seguridad:**
   - Validar en `firestore.rules`
   - Nunca confiar en el cliente

### Estructura de colecciones:

```
users/{uid}
memberships/{userId}
reviewQuestions/{questionId}
books/{bookId}
  /comments/{commentId}
  /ratings/{authorId}
  /reviews/{authorId}
meetings/{meetingId}
  /comments/{commentId}
  /ratings/{authorId}
```

## Estructura de Directorios Completa

```
lib/
├── main.dart
├── data/
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── user_service.dart
│   │   ├── book_service.dart
│   │   ├── meeting_service.dart
│   │   ├── comment_service.dart
│   │   ├── rating_service.dart
│   │   ├── review_service.dart
│   │   ├── review_question_service.dart
│   │   └── membership_service.dart
│   └── repositories/
│       └── (implementaciones concretas si es necesario)
├── domain/
│   ├── models/
│   │   ├── app_user.dart
│   │   ├── book.dart
│   │   ├── meeting.dart
│   │   ├── comment.dart
│   │   ├── rating.dart
│   │   ├── final_review.dart
│   │   ├── membership.dart
│   │   ├── review_question.dart
│   │   └── models.dart (barrel file)
│   └── repositories/
│       └── (interfaces abstractas si es necesario)
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── user_provider.dart
│   │   ├── book_provider.dart
│   │   ├── meeting_provider.dart
│   │   └── ...
│   ├── routes/
│   │   └── app_router.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── auth_screen.dart
│   │   │   ├── pending_access_screen.dart
│   │   │   └── waiting_screen.dart
│   │   ├── books/
│   │   │   ├── book_list_screen.dart
│   │   │   ├── book_detail_screen.dart
│   │   │   └── create_edit_book_screen.dart
│   │   ├── meetings/
│   │   │   ├── meeting_screen.dart
│   │   │   └── create_edit_meeting_screen.dart
│   │   └── admin/
│   │       ├── member_management_screen.dart
│   │       └── review_questions_management_screen.dart
│   ├── widgets/
│   │   ├── common/
│   │   ├── book/
│   │   ├── meeting/
│   │   ├── comment/
│   │   └── rating/
│   └── theme/
│       └── app_theme.dart
└── l10n/
    ├── app_en.arb
    └── app_es.arb
```

## Checklist de Implementación

Antes de considerar una tarea completa, verificar:

- [ ] Código separado en capas correctas (presentation/domain/data)
- [ ] Sin lógica de negocio en UI
- [ ] Servicios con manejo de errores completo
- [ ] Uso correcto de async/await
- [ ] Providers de Riverpod configurados
- [ ] Widgets reutilizables cuando sea posible
- [ ] Navegación organizada con go_router
- [ ] Textos internacionalizados (español e inglés)
- [ ] Timestamps de Firestore usados correctamente
- [ ] Código formateado con `dart format`
- [ ] Sin warnings de análisis estático
- [ ] Nombres descriptivos y código limpio

## Ejemplo Completo de Flujo

### 1. Modelo (Domain)
```dart
// lib/domain/models/book.dart
class Book {
  final String id;
  final String title;
  // ... otros campos
  
  const Book({required this.id, required this.title});
  
  factory Book.fromMap(Map<String, dynamic> map, String id) { ... }
  Map<String, dynamic> toMap() { ... }
}
```

### 2. Servicio (Data)
```dart
// lib/data/services/book_service.dart
class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<List<Book>> watchBooks() {
    try {
      return _firestore
          .collection('books')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Book.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      print('Error watching books: $e');
      rethrow;
    }
  }
  
  Future<void> createBook(Book book, File coverImage) async {
    try {
      // Subir imagen
      final coverUrl = await _uploadCover(coverImage);
      
      // Crear documento
      await _firestore.collection('books').add({
        ...book.toMap(),
        'coverUrl': coverUrl,
      });
    } on FirebaseException catch (e) {
      print('Firebase error creating book: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error creating book: $e');
      rethrow;
    }
  }
}
```

### 3. Provider (Presentation)
```dart
// lib/presentation/providers/book_provider.dart
final bookServiceProvider = Provider<BookService>((ref) => BookService());

final booksStreamProvider = StreamProvider<List<Book>>((ref) {
  final bookService = ref.watch(bookServiceProvider);
  return bookService.watchBooks();
});
```

### 4. Screen (Presentation)
```dart
// lib/presentation/screens/books/book_list_screen.dart
class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksStreamProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookListTitle)),
      body: booksAsync.when(
        data: (books) => ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) => BookCard(book: books[index]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(l10n.errorLoadingBooks),
        ),
      ),
    );
  }
}
```

### 5. Widget Reutilizable (Presentation)
```dart
// lib/presentation/widgets/book/book_card.dart
class BookCard extends StatelessWidget {
  final Book book;
  
  const BookCard({required this.book, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.network(book.coverUrl),
        title: Text(book.title),
        subtitle: Text(book.author),
        onTap: () => context.go('/books/${book.id}'),
      ),
    );
  }
}
```

---

**IMPORTANTE:** Estas reglas son OBLIGATORIAS para toda implementación. Cualquier código que no siga estas guías debe ser refactorizado antes de considerarse completo.
