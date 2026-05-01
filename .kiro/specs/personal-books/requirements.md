# Requirements Document

## Introduction

La funcionalidad "Mis Libros Personales" permite a cada miembro del club llevar un registro privado de sus propias lecturas, independiente del catálogo compartido del club. Cada usuario puede agregar libros que está leyendo o ha leído por su cuenta, registrar su progreso, escribir notas personales y calificarlos. Estos libros son completamente privados: solo el propio usuario puede verlos y gestionarlos, y no son visibles para el resto del club.

## Glossary

- **App**: La aplicación móvil Book Club App.
- **Personal_Book**: Entidad que representa un libro personal de un Member, almacenado en su colección privada. Distinto de un Book del club.
- **Personal_Book_Status**: Estado de un Personal_Book: `want_to_read` (quiero leer), `reading` (leyendo actualmente) o `read` (leído).
- **Personal_Note**: Texto libre escrito por el Member sobre un Personal_Book, visible únicamente para él.
- **Personal_Rating**: Calificación numérica (1–5) asignada por el Member a un Personal_Book.
- **Member**: Usuario con rol `member` o `leader` con membresía activa en el club.
- **Firestore**: La base de datos en la nube de Firebase (Cloud Firestore).
- **Storage**: El servicio de almacenamiento de archivos de Firebase (Firebase Storage).
- **Personal_Books_Screen**: Pantalla que muestra el listado de Personal_Books del Member autenticado.
- **Personal_Book_Detail_Screen**: Pantalla que muestra la información completa de un Personal_Book.
- **Personal_Book_Form_Screen**: Pantalla con el formulario para crear o editar un Personal_Book.

---

## Requirements

### Requirement 1: Acceso a la sección de libros personales

**User Story:** Como miembro, quiero acceder a una sección dedicada de mis libros personales, para separar mis lecturas privadas del catálogo del club.

#### Acceptance Criteria

1. WHILE el Member tiene membresía activa, THE App SHALL mostrar una entrada de navegación hacia la Personal_Books_Screen accesible desde la pantalla principal.
2. WHEN el Member accede a la Personal_Books_Screen, THE App SHALL mostrar únicamente los Personal_Books creados por el Member autenticado.
3. THE App SHALL configurar reglas de Firestore que rechacen lecturas y escrituras en `users/{uid}/personal_books` a cualquier User cuyo `uid` sea distinto al del documento padre.

---

### Requirement 2: Creación de libros personales

**User Story:** Como miembro, quiero agregar libros a mi lista personal, para registrar mis lecturas independientes del club.

#### Acceptance Criteria

1. WHEN el Member envía el formulario de creación de Personal_Book con título y autor, THE App SHALL guardar el documento en la subcolección `users/{uid}/personal_books` con los campos: `title`, `author`, `status` (valor inicial `want_to_read`), `createdAt` y `updatedAt`.
2. THE App SHALL requerir que los campos `title` y `author` no estén vacíos antes de permitir el envío del formulario de creación de Personal_Book.
3. WHERE el Member proporciona una imagen de portada, THE App SHALL subir la imagen a Storage en la ruta `personal_books/{uid}/{bookId}/cover` y guardar la URL resultante en el campo `coverUrl` del documento.
4. WHERE el Member proporciona una descripción, THE App SHALL guardar el texto en el campo `description` del documento de Personal_Book.
5. WHEN el Personal_Book es creado exitosamente, THE App SHALL mostrar el nuevo Personal_Book en la Personal_Books_Screen sin requerir recarga manual.

---

### Requirement 3: Edición de libros personales

**User Story:** Como miembro, quiero editar la información de mis libros personales, para corregir datos o actualizar el estado de lectura.

#### Acceptance Criteria

1. WHEN el Member edita un Personal_Book existente, THE App SHALL actualizar únicamente los campos modificados en el documento de Firestore y registrar la fecha actual en el campo `updatedAt`.
2. WHEN el Member cambia el `status` de un Personal_Book a `read`, THE App SHALL registrar el campo `finishedAt` con la fecha actual en el documento del Personal_Book.
3. WHEN el Member cambia el `status` de un Personal_Book a `reading`, THE App SHALL registrar el campo `startedAt` con la fecha actual en el documento del Personal_Book, si el campo no existe previamente.
4. IF el Member intenta guardar un Personal_Book con `title` o `author` vacíos, THEN THE App SHALL mostrar un mensaje de error inline en el campo correspondiente y no enviar el formulario.

---

### Requirement 4: Eliminación de libros personales

**User Story:** Como miembro, quiero eliminar libros de mi lista personal, para mantener mi colección organizada.

#### Acceptance Criteria

1. WHEN el Member elimina un Personal_Book, THE App SHALL eliminar el documento de `users/{uid}/personal_books/{bookId}` y, si existe, la imagen de portada asociada en Storage.
2. WHEN la eliminación es exitosa, THE App SHALL actualizar la Personal_Books_Screen reflejando la eliminación sin requerir recarga manual.
3. BEFORE ejecutar la eliminación, THE App SHALL mostrar un diálogo de confirmación al Member.

---

### Requirement 5: Listado de libros personales

**User Story:** Como miembro, quiero ver mi lista de libros personales organizada y filtrable, para encontrar rápidamente lo que busco.

#### Acceptance Criteria

1. WHEN el Member accede a la Personal_Books_Screen, THE App SHALL mostrar todos sus Personal_Books ordenados por `updatedAt` descendente, incluyendo portada (o imagen de placeholder si no tiene), título, autor y `status`.
2. WHEN el Member selecciona un filtro de `status` en la Personal_Books_Screen, THE App SHALL mostrar únicamente los Personal_Books cuyo `status` coincida con el filtro seleccionado.
3. WHILE el Member no tiene ningún Personal_Book registrado, THE App SHALL mostrar un mensaje de estado vacío con una acción para agregar el primer libro.
4. WHEN el Member pulsa sobre un Personal_Book en la Personal_Books_Screen, THE App SHALL navegar a la Personal_Book_Detail_Screen mostrando todos los campos del Personal_Book.

---

### Requirement 6: Notas personales

**User Story:** Como miembro, quiero escribir notas privadas sobre mis libros personales, para registrar mis pensamientos durante la lectura.

#### Acceptance Criteria

1. WHEN el Member guarda una Personal_Note sobre un Personal_Book, THE App SHALL actualizar el campo `notes` del documento en `users/{uid}/personal_books/{bookId}` con el texto proporcionado y registrar la fecha actual en `updatedAt`.
2. THE App SHALL requerir que el campo `notes` tenga como máximo 5000 caracteres antes de permitir el guardado.
3. IF el Member intenta guardar una Personal_Note con más de 5000 caracteres, THEN THE App SHALL mostrar un mensaje de error con el conteo de caracteres actual y no enviar el formulario.
4. WHEN el Member accede a la Personal_Book_Detail_Screen, THE App SHALL mostrar las notas actuales del Personal_Book en un campo editable.

---

### Requirement 7: Calificación de libros personales

**User Story:** Como miembro, quiero calificar mis libros personales, para registrar mi valoración de cada lectura.

#### Acceptance Criteria

1. WHILE el Personal_Book tiene `status` igual a `read`, THE App SHALL mostrar un control de calificación (1–5 estrellas) en la Personal_Book_Detail_Screen.
2. WHEN el Member asigna una Personal_Rating a un Personal_Book con `status` igual a `read`, THE App SHALL guardar o actualizar el campo `rating` (entero 1–5) en el documento del Personal_Book y registrar la fecha actual en `updatedAt`.
3. IF el Member intenta calificar un Personal_Book con `status` distinto de `read`, THEN THE App SHALL mostrar un mensaje indicando que la calificación solo está disponible cuando el libro ha sido marcado como leído.
4. WHEN el Member accede a la Personal_Book_Detail_Screen de un Personal_Book con `status` igual a `read` y `rating` registrado, THE App SHALL mostrar la calificación actual del Member.

---

### Requirement 8: Seguridad y privacidad de los datos personales

**User Story:** Como miembro, quiero que mis libros personales sean completamente privados, para que ningún otro usuario del club pueda verlos.

#### Acceptance Criteria

1. THE App SHALL configurar reglas de Firestore que permitan lectura y escritura en `users/{uid}/personal_books` únicamente al User cuyo `uid` coincida con el segmento `{uid}` de la ruta.
2. THE App SHALL configurar reglas de Storage que permitan lectura y escritura en `personal_books/{uid}/` únicamente al User cuyo `uid` coincida con el segmento `{uid}` de la ruta.
3. THE App SHALL garantizar que ninguna query, listado o pantalla del club exponga documentos de la subcolección `personal_books` a otros Members.

---

### Requirement 9: Interfaz de usuario de libros personales

**User Story:** Como miembro, quiero una interfaz coherente con el resto de la app para gestionar mis libros personales, para tener una experiencia de uso uniforme.

#### Acceptance Criteria

1. THE App SHALL implementar la Personal_Books_Screen siguiendo el sistema de diseño existente de la App (tipografía, colores y espaciado definidos en `app_theme.dart`).
2. WHEN la App está cargando Personal_Books desde Firestore, THE App SHALL mostrar un indicador de carga visible al Member.
3. IF una operación sobre un Personal_Book falla, THEN THE App SHALL mostrar un mensaje de error descriptivo sin bloquear la navegación del Member.
4. THE App SHALL implementar la Personal_Book_Form_Screen como pantalla reutilizable tanto para la creación como para la edición de Personal_Books.
