# Requirements Document

## Introduction

Book Club App es una aplicación móvil Flutter con backend Firebase (Authentication, Firestore y Storage) para gestionar un club de lectura. La app permite a los miembros del club seguir el progreso de los libros leídos, registrar reuniones con notas y calificaciones parciales, y compartir opiniones finales sobre cada libro. Existe un sistema de roles que distingue entre usuarios normales y líderes del club, quienes tienen permisos de administración sobre el contenido.

## Glossary

- **App**: La aplicación móvil Book Club App.
- **Auth_Service**: El servicio de autenticación basado en Firebase Authentication.
- **Firestore**: La base de datos en la nube de Firebase (Cloud Firestore).
- **Storage**: El servicio de almacenamiento de archivos de Firebase (Firebase Storage).
- **User**: Persona registrada en la App con rol `member` o `leader`.
- **Leader**: Usuario con rol `leader`, con permisos para crear, editar y eliminar libros y reuniones, y administrar miembros.
- **Member**: Usuario con rol `member`, con permisos de lectura y escritura de comentarios y calificaciones propias.
- **Book**: Entidad que representa un libro gestionado dentro del club, con título, autor, portada, descripción y estado.
- **Meeting**: Entidad que representa una reunión del club asociada a un Book, con fecha, notas y calificación parcial.
- **Comment**: Texto escrito por un User sobre un Book o una Meeting.
- **Rating**: Calificación numérica (1–5) asignada por un User a un Book o a una Meeting.
- **FinalReview**: Conjunto de reflexiones finales de un User sobre un Book terminado: frases favoritas, personaje favorito, personaje odiado y escena de cringe.
- **Membership**: Relación que indica que un User pertenece al club.
- **Book_Status**: Estado de un Book: `reading` (leyendo actualmente) o `read` (leído).
- **Book_List_Screen**: Pantalla principal que muestra el listado de libros del club.
- **Book_Detail_Screen**: Pantalla que muestra la información completa de un Book.
- **Meeting_Screen**: Pantalla que muestra las reuniones asociadas a un Book.
- **Auth_Screen**: Pantalla de inicio de sesión.

---

## Requirements

### Requirement 1: Autenticación con Google

**User Story:** Como visitante, quiero iniciar sesión con mi cuenta de Google, para acceder a la App de forma segura sin crear una contraseña adicional.

#### Acceptance Criteria

1. WHEN el visitante pulsa el botón "Iniciar sesión con Google", THE Auth_Service SHALL autenticar al visitante mediante el flujo OAuth de Google Sign-In.
2. WHEN la autenticación de Google es exitosa y el User no existe en Firestore, THE Auth_Service SHALL crear un documento en la colección `users` con los campos: `uid`, `email`, `displayName`, `photoUrl`, `role` (valor inicial `member`) y `createdAt`.
3. WHEN la autenticación de Google es exitosa y el User ya existe en Firestore, THE Auth_Service SHALL actualizar los campos `displayName` y `photoUrl` del documento existente.
4. IF la autenticación de Google falla, THEN THE Auth_Service SHALL mostrar un mensaje de error descriptivo al visitante sin cerrar la Auth_Screen.
5. WHEN el User cierra sesión, THE Auth_Service SHALL revocar el token de sesión activo y redirigir al usuario a la Auth_Screen.

---

### Requirement 2: Control de acceso por membresía

**User Story:** Como líder, quiero que solo los miembros del club puedan ver el contenido, para mantener la privacidad del club.

#### Acceptance Criteria

1. WHILE el User autenticado no posee un documento activo en la colección `memberships`, THE App SHALL mostrar únicamente una pantalla de "Acceso pendiente" sin exponer contenido del club.
2. WHEN un Leader aprueba la solicitud de membresía de un User, THE App SHALL actualizar el campo `status` del documento en `memberships` a `active` y conceder acceso al contenido del club.
3. THE App SHALL aplicar reglas de seguridad en Firestore que rechacen lecturas de las colecciones `books`, `meetings` y `memberships` a Users sin membresía activa.

---

### Requirement 3: Gestión de roles

**User Story:** Como administrador del sistema, quiero que existan roles diferenciados (member y leader), para controlar quién puede modificar el contenido del club.

#### Acceptance Criteria

1. THE App SHALL soportar exactamente dos roles de User: `member` y `leader`.
2. WHEN un Leader modifica el campo `role` de un User en Firestore a `leader`, THE App SHALL conceder a ese User permisos de escritura sobre las colecciones `books` y `meetings`.
3. WHILE el User autenticado tiene rol `member`, THE App SHALL ocultar los controles de creación, edición y eliminación de Books y Meetings en la interfaz.
4. THE App SHALL aplicar reglas de seguridad en Firestore que rechacen escrituras en `books` y `meetings` realizadas por Users con rol distinto de `leader`.

---

### Requirement 4: Gestión de libros

**User Story:** Como líder, quiero crear, editar y eliminar libros en el club, para mantener actualizado el catálogo de lecturas.

#### Acceptance Criteria

1. WHEN un Leader envía el formulario de creación de Book con título, autor, descripción y portada, THE App SHALL almacenar la imagen de portada en Storage y guardar el documento en la colección `books` con los campos: `title`, `author`, `description`, `coverUrl`, `status` (valor inicial `reading`), `createdBy` y `createdAt`.
2. THE App SHALL requerir que los campos `title` y `author` no estén vacíos antes de permitir el envío del formulario de creación de Book.
3. WHEN un Leader edita un Book existente, THE App SHALL actualizar únicamente los campos modificados en el documento de Firestore correspondiente.
4. WHEN un Leader elimina un Book, THE App SHALL eliminar el documento de `books`, la imagen de portada en Storage y todos los documentos de `meetings` asociados a ese Book.
5. WHEN un Leader cambia el `status` de un Book a `read`, THE App SHALL registrar el campo `finishedAt` con la fecha actual en el documento del Book.

---

### Requirement 5: Listado y detalle de libros

**User Story:** Como miembro, quiero ver el listado de libros y el detalle de cada uno, para conocer el estado y la información de las lecturas del club.

#### Acceptance Criteria

1. WHEN el Member accede a la Book_List_Screen, THE App SHALL mostrar todos los Books del club ordenados por `createdAt` descendente, incluyendo portada, título, autor y `status`.
2. WHEN el Member pulsa sobre un Book en la Book_List_Screen, THE App SHALL navegar a la Book_Detail_Screen mostrando: portada, título, autor, descripción, `status`, lista de Meetings asociadas, lista de Comments y Rating promedio.
3. WHILE el Book tiene `status` igual a `reading`, THE Book_Detail_Screen SHALL mostrar la etiqueta "Leyendo actualmente".
4. WHILE el Book tiene `status` igual a `read`, THE Book_Detail_Screen SHALL mostrar la etiqueta "Leído" y la calificación final promedio.

---

### Requirement 6: Gestión de reuniones

**User Story:** Como líder, quiero crear y gestionar reuniones asociadas a un libro, para registrar el progreso y las discusiones del club.

#### Acceptance Criteria

1. WHEN un Leader envía el formulario de creación de Meeting con fecha, notas y calificación parcial, THE App SHALL guardar el documento en la colección `meetings` con los campos: `bookId`, `date`, `notes`, `partialRating` (entero 1–5), `createdBy` y `createdAt`.
2. THE App SHALL requerir que los campos `date` y `partialRating` no estén vacíos antes de permitir el envío del formulario de creación de Meeting.
3. WHEN un Leader edita una Meeting existente, THE App SHALL actualizar únicamente los campos modificados en el documento de Firestore correspondiente.
4. WHEN un Leader elimina una Meeting, THE App SHALL eliminar el documento correspondiente de la colección `meetings`.
5. WHEN el Member accede a la Meeting_Screen de un Book, THE App SHALL mostrar todas las Meetings de ese Book ordenadas por `date` ascendente.

---

### Requirement 7: Comentarios en libros y reuniones

**User Story:** Como miembro, quiero escribir comentarios en libros y reuniones, para compartir mis opiniones con el club.

#### Acceptance Criteria

1. WHEN un Member envía un Comment sobre un Book, THE App SHALL guardar el documento en la subcolección `books/{bookId}/comments` con los campos: `authorId`, `authorName`, `text` y `createdAt`.
2. WHEN un Member envía un Comment sobre una Meeting, THE App SHALL guardar el documento en la subcolección `meetings/{meetingId}/comments` con los campos: `authorId`, `authorName`, `text` y `createdAt`.
3. THE App SHALL requerir que el campo `text` del Comment tenga al menos 1 carácter y no supere 1000 caracteres antes de permitir el envío.
4. WHEN un Member envía un Comment, THE App SHALL mostrar el nuevo Comment en la lista sin requerir recarga manual de la pantalla.

---

### Requirement 8: Calificaciones

**User Story:** Como miembro, quiero calificar las reuniones y el libro al finalizar, para registrar mi valoración de cada lectura.

#### Acceptance Criteria

1. WHEN un Member envía una Rating sobre una Meeting, THE App SHALL guardar o actualizar el documento en la subcolección `meetings/{meetingId}/ratings` con los campos: `authorId` y `value` (entero 1–5).
2. WHEN un Member envía una Rating final sobre un Book con `status` igual a `read`, THE App SHALL guardar o actualizar el documento en la subcolección `books/{bookId}/ratings` con los campos: `authorId` y `value` (entero 1–5).
3. IF un Member intenta calificar un Book con `status` igual a `reading`, THEN THE App SHALL mostrar un mensaje indicando que la calificación final solo está disponible cuando el libro ha sido marcado como leído.
4. WHEN se calculan las calificaciones, THE App SHALL mostrar el promedio de todos los valores de Rating de la subcolección correspondiente redondeado a un decimal.

---

### Requirement 9: Reseña final del libro

**User Story:** Como miembro, quiero registrar mis reflexiones finales sobre un libro terminado, para compartir mis impresiones más memorables con el club.

#### Acceptance Criteria

1. WHILE el Book tiene `status` igual a `read`, THE App SHALL mostrar en la Book_Detail_Screen un formulario de FinalReview con el campo `favoritePhrases` (lista de textos) y las preguntas configurables asociadas al libro.
2. WHEN un Leader crea o edita un Book, THE App SHALL permitir seleccionar las preguntas de reseña que los miembros deberán responder al finalizar el libro.
3. WHEN un Member envía un FinalReview, THE App SHALL guardar o actualizar el documento en la subcolección `books/{bookId}/reviews` con los campos: `authorId`, `favoritePhrases`, `answers` (mapa de questionId -> respuesta) y `updatedAt`.
4. THE App SHALL permitir que cada Member tenga exactamente un FinalReview por Book, sobrescribiendo el anterior si ya existe.
5. WHEN el Member accede a la Book_Detail_Screen de un Book con `status` igual a `read`, THE App SHALL mostrar las FinalReviews de todos los Members del club con las preguntas y respuestas correspondientes.
6. THE App SHALL permitir a los Leaders gestionar (crear, editar, eliminar) las preguntas de reseña disponibles en una colección global `reviewQuestions`.

---

### Requirement 10: Administración de miembros

**User Story:** Como líder, quiero gestionar los miembros del club, para controlar quién tiene acceso al contenido.

#### Acceptance Criteria

1. WHEN un User autenticado solicita unirse al club, THE App SHALL crear un documento en la colección `memberships` con los campos: `userId`, `status` (valor inicial `pending`) y `requestedAt`.
2. WHEN un Leader aprueba la solicitud de un User, THE App SHALL actualizar el campo `status` del documento en `memberships` a `active` y registrar `approvedAt` y `approvedBy`.
3. WHEN un Leader rechaza o elimina la membresía de un User, THE App SHALL actualizar el campo `status` del documento en `memberships` a `rejected` y revocar el acceso al contenido del club.
4. WHILE el User tiene `status` igual a `pending` en `memberships`, THE App SHALL mostrar una pantalla de espera indicando que la solicitud está en revisión.

---

### Requirement 11: Seguridad en Firestore

**User Story:** Como administrador del sistema, quiero que las reglas de seguridad de Firestore protejan los datos, para evitar accesos y modificaciones no autorizadas.

#### Acceptance Criteria

1. THE App SHALL configurar reglas de Firestore que permitan lectura de `books` y `meetings` únicamente a Users con membresía `active`.
2. THE App SHALL configurar reglas de Firestore que permitan escritura en `books` y `meetings` únicamente a Users con rol `leader`.
3. THE App SHALL configurar reglas de Firestore que permitan a cada User leer y escribir únicamente su propio documento en la colección `users`.
4. THE App SHALL configurar reglas de Firestore que permitan escritura en subcolecciones `comments`, `ratings` y `reviews` únicamente a Users con membresía `active`.
5. THE App SHALL configurar reglas de Firestore que permitan escritura en la colección `memberships` únicamente a Leaders o al propio User para crear su solicitud inicial.

---

### Requirement 12: Interfaz de usuario

**User Story:** Como miembro, quiero una interfaz limpia y moderna, para navegar por la app de forma intuitiva.

#### Acceptance Criteria

1. THE App SHALL implementar una Book_List_Screen como pantalla principal accesible tras el inicio de sesión exitoso y membresía activa.
2. THE App SHALL implementar una Book_Detail_Screen accesible desde cada elemento de la Book_List_Screen.
3. THE App SHALL implementar una Meeting_Screen accesible desde la Book_Detail_Screen de cada Book.
4. THE App SHALL utilizar un sistema de diseño consistente con tipografía, colores y espaciado uniformes en todas las pantallas.
5. WHEN la App está cargando datos desde Firestore, THE App SHALL mostrar un indicador de carga visible al usuario.
6. IF una operación de red falla, THEN THE App SHALL mostrar un mensaje de error descriptivo sin bloquear la navegación del usuario.
