# Tasks

## Task List

- [x] 1. Configuración del proyecto y Firebase
  - [x] 1.1 Añadir dependencias de Firebase al pubspec.yaml (firebase_core, firebase_auth, cloud_firestore, firebase_storage, google_sign_in)
  - [x] 1.2 Configurar Firebase en la app (google-services.json / GoogleService-Info.plist)
  - [x] 1.3 Inicializar Firebase en main.dart
  - [x] 1.4 Configurar Firebase Emulator Suite para tests locales
  - [x] 1.5 Añadir dependencia glados para property-based testing

- [x] 2. Modelos de datos y DTOs
  - [x] 2.1 Implementar clase AppUser con serialización Firestore
  - [x] 2.2 Implementar clase Book con serialización Firestore (incluye reviewQuestionIds)
  - [x] 2.3 Implementar clase Meeting con serialización Firestore
  - [x] 2.4 Implementar clase Comment con serialización Firestore
  - [x] 2.5 Implementar clase Rating con serialización Firestore
  - [x] 2.6 Implementar clase FinalReview con serialización Firestore (incluye answers map)
  - [x] 2.7 Implementar clase Membership con serialización Firestore
  - [x] 2.8 Implementar clase ReviewQuestion con serialización Firestore

- [x] 3. Autenticación (Requirement 1)
  - [x] 3.1 Implementar AuthService con Google Sign-In
  - [x] 3.2 Implementar lógica de creación de usuario nuevo en Firestore al autenticarse
  - [x] 3.3 Implementar lógica de actualización de displayName y photoUrl para usuario existente
  - [x] 3.4 Implementar manejo de errores de autenticación con mensaje descriptivo
  - [x] 3.5 Implementar cierre de sesión con revocación de token
  - [x] 3.6 Escribir property test P1: creación de usuario nuevo preserva todos los campos requeridos
  - [x] 3.7 Escribir property test P2: actualización de usuario existente solo modifica displayName y photoUrl

- [x] 4. Control de acceso por membresía (Requirement 2 y 10)
  - [x] 4.1 Implementar MembershipRepository con operaciones CRUD en Firestore
  - [x] 4.2 Implementar flujo de solicitud de membresía al primer login
  - [x] 4.3 Implementar pantalla PendingAccessScreen
  - [x] 4.4 Implementar pantalla WaitingScreen para membresía pendiente
  - [x] 4.5 Implementar lógica de aprobación de membresía por leader
  - [x] 4.6 Implementar lógica de rechazo/eliminación de membresía
  - [x] 4.7 Implementar MemberManagementScreen para leaders
  - [x] 4.8 Escribir property test P16: solicitud de membresía crea documento con estado pending
  - [x] 4.9 Escribir property test P17: aprobación de membresía actualiza todos los campos requeridos

- [x] 5. Gestión de roles (Requirement 3)
  - [x] 5.1 Implementar constantes/enum para roles (member, leader)
  - [x] 5.2 Implementar lógica de permisos basada en rol en la UI (ocultar controles para member)
  - [x] 5.3 Configurar reglas de seguridad Firestore para escritura solo por leaders en books y meetings
  - [x] 5.4 Escribir smoke test para verificar que solo existen dos roles válidos
  - [x] 5.5 Escribir smoke test para reglas de seguridad Firestore (rechazo de escritura por non-leaders)

- [x] 6. Gestión de libros (Requirement 4)
  - [x] 6.1 Implementar BookRepository con operaciones CRUD en Firestore y Storage
  - [x] 6.2 Implementar CreateEditBookScreen con formulario de validación
  - [x] 6.3 Implementar subida de imagen de portada a Firebase Storage
  - [x] 6.4 Implementar eliminación en cascada (libro + imagen + meetings)
  - [x] 6.5 Implementar cambio de estado a `read` con registro de finishedAt
  - [x] 6.6 Escribir property test P3: validación de campos obligatorios de Book
  - [x] 6.7 Escribir property test P4: creación de Book preserva todos los campos requeridos
  - [x] 6.8 Escribir property test P5: actualización parcial de Book solo modifica campos enviados
  - [x] 6.9 Escribir property test P6: eliminación de Book elimina todos los recursos asociados
  - [x] 6.10 Escribir property test P7: cambio de estado a read registra finishedAt

- [x] 7. Listado y detalle de libros (Requirement 5)
  - [x] 7.1 Implementar BookListScreen con stream de Firestore ordenado por createdAt desc
  - [x] 7.2 Implementar BookDetailScreen con portada, título, autor, descripción, estado, meetings, comments y rating promedio
  - [x] 7.3 Implementar etiquetas de estado ("Leyendo actualmente" / "Leído") en BookDetailScreen
  - [x] 7.4 Implementar indicador de carga durante fetch de datos
  - [x] 7.5 Escribir property test P8: listado de libros siempre ordenado por createdAt descendente

- [x] 8. Gestión de reuniones (Requirement 6)
  - [x] 8.1 Implementar MeetingRepository con operaciones CRUD en Firestore
  - [x] 8.2 Implementar CreateEditMeetingScreen con formulario de validación
  - [x] 8.3 Implementar MeetingScreen con stream de Firestore ordenado por date ascendente
  - [x] 8.4 Escribir property test P9: validación de campos obligatorios de Meeting
  - [x] 8.5 Escribir property test P10: listado de reuniones siempre ordenado por date ascendente

- [x] 9. Comentarios (Requirement 7)
  - [x] 9.1 Implementar CommentRepository para subcolecciones de books y meetings
  - [x] 9.2 Implementar widget de lista de comentarios con stream en tiempo real
  - [x] 9.3 Implementar formulario de envío de comentario con validación de longitud
  - [x] 9.4 Escribir property test P11: validación de longitud de Comment (1-1000 chars)
  - [x] 9.5 Escribir property test P12: almacenamiento de Comment en subcolección correcta

- [x] 10. Calificaciones (Requirement 8)
  - [x] 10.1 Implementar RatingRepository con upsert en subcolecciones de books y meetings
  - [x] 10.2 Implementar widget de selección de rating (1-5 estrellas)
  - [x] 10.3 Implementar cálculo y visualización de promedio redondeado a un decimal
  - [x] 10.4 Implementar bloqueo de rating en libros con estado `reading` con mensaje informativo
  - [x] 10.5 Escribir property test P13: upsert de Rating garantiza exactamente un documento por autor
  - [x] 10.6 Escribir property test P14: cálculo de promedio de calificaciones redondeado a un decimal

- [x] 11. Reseña final (Requirement 9)
  - [x] 11.1 Implementar ReviewQuestionRepository con operaciones CRUD en colección reviewQuestions
  - [x] 11.2 Implementar ReviewRepository con upsert en subcolección books/{bookId}/reviews
  - [x] 11.3 Implementar ReviewQuestionsManagementScreen para leaders (crear, editar, eliminar preguntas)
  - [x] 11.4 Implementar selección de preguntas de reseña en CreateEditBookScreen
  - [x] 11.5 Implementar formulario de FinalReview (visible solo para libros con status `read`) con preguntas dinámicas
  - [x] 11.6 Implementar visualización de todas las FinalReviews en BookDetailScreen para libros leídos con preguntas y respuestas
  - [x] 11.7 Escribir property test P15: upsert de FinalReview garantiza exactamente un documento por autor
  - [x] 11.8 Escribir property test P18: preguntas de reseña configurables por libro

- [x] 12. Reglas de seguridad Firestore (Requirement 11)
  - [x] 12.1 Configurar reglas de lectura de books y meetings solo para miembros activos
  - [x] 12.2 Configurar reglas de escritura en books y meetings solo para leaders
  - [x] 12.3 Configurar reglas de lectura/escritura de users solo para el propio usuario
  - [x] 12.4 Configurar reglas de escritura en subcolecciones comments, ratings y reviews solo para miembros activos
  - [x] 12.5 Configurar reglas de escritura en memberships para leaders o el propio usuario (solicitud inicial)
  - [x] 12.6 Escribir smoke tests para cada regla de seguridad con Firebase Emulator

- [x] 13. Interfaz de usuario y navegación (Requirement 12)
  - [x] 13.1 Implementar sistema de navegación con go_router o Navigator 2.0
  - [x] 13.2 Implementar tema visual consistente (tipografía, colores, espaciado)
  - [x] 13.3 Implementar manejo global de errores de red con SnackBar descriptivo
  - [x] 13.4 Escribir tests de navegación entre pantallas según rol y estado de membresía

- [x] 14. Autenticación con Email y Contraseña
  - [x] 14.1 Crear formulario de login con campos email y password
  - [x] 14.2 Implementar validación básica de email y contraseña
  - [x] 14.3 Integrar Firebase Auth para login con email/password
  - [x] 14.4 Mostrar errores descriptivos si el login falla
  - [x] 14.5 Escribir tests para flujo de login exitoso y fallido

- [x] 15. Recuperación de Contraseña
  - [x] 15.1 Agregar botón "Olvidé mi contraseña" en AuthScreen
  - [x] 15.2 Crear pantalla de recuperación con campo para email
  - [x] 15.3 Integrar Firebase Auth para envío de correo de recuperación
  - [x] 15.4 Mostrar confirmación al usuario cuando se envía el correo
  - [x] 15.5 Escribir tests para flujo de recuperación de contraseña

- [x] 16. Registro de Usuario
  - [x] 16.1 Crear formulario de registro con nombre, email y password
  - [x] 16.2 Implementar validación de campos (nombre no vacío, email válido, password fuerte)
  - [x] 16.3 Crear usuario en Firebase Auth
  - [x] 16.4 Guardar datos del usuario en Firestore (uid, nombre, email)
  - [x] 16.5 Crear documento de membresía con estado `pending` al registrarse
  - [x] 16.6 Escribir tests para flujo de registro completo

- [x] 17. Pantalla de Inicio con Historial
  - [x] 17.1 Crear HomeScreen que muestre lista de libros del club
  - [x] 17.2 Mostrar portada, título y autor de cada libro
  - [x] 17.3 Mostrar calificación en estrellas (promedio) para cada libro
  - [x] 17.4 Implementar carga desde Firestore con indicador de progreso
  - [x] 17.5 Escribir tests para carga correcta de lista de libros

- [x] 18. Pantalla de Perfil
  - [x] 18.1 Crear ProfileScreen que muestre nombre del usuario
  - [x] 18.2 Mostrar foto de perfil del usuario
  - [x] 18.3 Agregar botón "Editar Perfil"
  - [x] 18.4 Mostrar información adicional (email, fecha de registro)
  - [x] 18.5 Agregar botón de cierre de sesión

- [x] 19. Editar Perfil
  - [x] 19.1 Crear pantalla EditProfileScreen con formulario
  - [x] 19.2 Permitir cambiar nombre del usuario
  - [x] 19.3 Implementar subida de foto a Firebase Storage
  - [x] 19.4 Guardar cambios en Firestore
  - [x] 19.5 Mostrar cambios en tiempo real en ProfileScreen
  - [x] 19.6 Escribir tests para edición de perfil

- [x] 20. Libros Personales por Categoría
  - [x] 20.1 Crear pantalla LibraryScreen con categorías (leídos, leyendo, quiero leer)
  - [x] 20.2 Implementar filtrado de libros por categoría
  - [x] 20.3 Mostrar lista de libros por categoría con portada y calificación
  - [x] 20.4 Permitir cambiar categoría de un libro
  - [x] 20.5 Escribir tests para filtrado y visualización por categoría

- [x] 21. Pantalla de Detalle de Libro (Mejoras)
  - [x] 21.1 Verificar que todos los iconos se renderizan correctamente
  - [x] 21.2 Corregir problema de iconos no visibles (revisar tema y colores)
  - [x] 21.3 Mostrar información completa del libro (título, autor, descripción)
  - [x] 21.4 Mostrar estado del libro (leyendo/leído)
  - [x] 21.5 Escribir tests para renderizado correcto de iconos

- [x] 22. Crear Reunión
  - [x] 22.1 Crear pantalla CreateMeetingScreen con formulario
  - [x] 22.2 Permitir seleccionar libro asociado a la reunión
  - [x] 22.3 Agregar campo de fecha de reunión
  - [x] 22.4 Agregar campo de comentarios/notas
  - [x] 22.5 Agregar campo de calificación parcial (1-5)
  - [x] 22.6 Guardar reunión en Firestore con todos los campos
  - [x] 22.7 Escribir tests para creación de reunión

- [x] 23. Calificaciones por Usuario
  - [x] 23.1 Permitir que cada miembro califique reuniones
  - [x] 23.2 Guardar calificación con userId, rating y comentario
  - [x] 23.3 Permitir actualizar calificación existente
  - [x] 23.4 Mostrar calificación individual del usuario
  - [x] 23.5 Escribir tests para guardado de calificaciones individuales

- [x] 24. Mostrar Calificaciones de Todos los Miembros
  - [x] 24.1 Crear pantalla RatingsScreen que muestre todas las calificaciones
  - [x] 24.2 Mostrar nombre del usuario, calificación y comentario
  - [x] 24.3 Ordenar calificaciones por fecha o puntuación
  - [x] 24.4 Mostrar promedio de calificaciones de la reunión
  - [x] 24.5 Escribir tests para visualización correcta de calificaciones
