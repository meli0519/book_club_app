// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Club de Lectura';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get signInError =>
      'Error al iniciar sesión. Por favor, inténtalo de nuevo.';

  @override
  String get emailPasswordSignIn => 'Iniciar sesión con Email';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Ingresa tu email';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordHint => 'Ingresa tu contraseña';

  @override
  String get invalidEmail => 'Por favor, ingresa un email válido.';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get signInButton => 'Iniciar sesión';

  @override
  String get togglePasswordVisibility => 'Mostrar/ocultar contraseña';

  @override
  String get noAccount => '¿No tienes cuenta?';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get pendingAccessTitle => 'Acceso Pendiente';

  @override
  String get pendingAccessMessage =>
      'Tu solicitud de membresía ha sido enviada. Un líder del club la revisará en breve.';

  @override
  String get waitingTitle => 'Solicitud en Revisión';

  @override
  String get waitingMessage =>
      'Tu solicitud de membresía está siendo revisada. Tendrás acceso una vez que un líder la apruebe.';

  @override
  String get rejectedTitle => 'Acceso Denegado';

  @override
  String get rejectedMessage =>
      'Tu solicitud de membresía no fue aprobada. Por favor, contacta a un líder del club para más información.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get loading => 'Cargando...';

  @override
  String get drawerWelcome => '¡Bienvenido!';

  @override
  String get drawerBooks => 'Libros';

  @override
  String get drawerMembers => 'Gestión de usuarios';

  @override
  String get drawerProfile => 'Mi perfil';

  @override
  String get memberManagementTitle => 'Gestión de Miembros';

  @override
  String get pendingRequests => 'Solicitudes Pendientes';

  @override
  String get noPendingRequests => 'No hay solicitudes de membresía pendientes.';

  @override
  String get approve => 'Aprobar';

  @override
  String get reject => 'Rechazar';

  @override
  String get memberApprovedSuccess => 'Membresía aprobada.';

  @override
  String get memberRejectedSuccess => 'Membresía rechazada.';

  @override
  String get memberActionError =>
      'Ocurrió un error. Por favor, inténtalo de nuevo.';

  @override
  String requestedAt(String date) {
    return 'Solicitado: $date';
  }

  @override
  String get addBook => 'Agregar libro';

  @override
  String get editBook => 'Editar libro';

  @override
  String get deleteBook => 'Eliminar libro';

  @override
  String get addMeeting => 'Agregar reunión';

  @override
  String get editMeeting => 'Editar reunión';

  @override
  String get deleteMeeting => 'Eliminar reunión';

  @override
  String get createBook => 'Crear libro';

  @override
  String get bookTitle => 'Título';

  @override
  String get bookTitleHint => 'Ingresa el título del libro';

  @override
  String get bookAuthor => 'Autor';

  @override
  String get bookAuthorHint => 'Ingresa el nombre del autor';

  @override
  String get bookDescription => 'Descripción';

  @override
  String get bookDescriptionHint => 'Ingresa la descripción del libro';

  @override
  String get bookCover => 'Imagen de portada';

  @override
  String get bookCoverHint => 'Toca para seleccionar una imagen de portada';

  @override
  String get fieldRequired => 'Este campo es obligatorio';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get bookCreatedSuccess => 'Libro creado exitosamente';

  @override
  String get bookUpdatedSuccess => 'Libro actualizado exitosamente';

  @override
  String get bookSaveError =>
      'Error al guardar el libro. Por favor, inténtalo de nuevo.';

  @override
  String get selectImage => 'Seleccionar imagen';

  @override
  String get changeImage => 'Cambiar imagen';

  @override
  String get bookListEmpty =>
      'Aún no hay libros. Un líder puede agregar el primero.';

  @override
  String get bookListError =>
      'Error al cargar los libros. Por favor, inténtalo de nuevo.';

  @override
  String get statusReading => 'Leyendo actualmente';

  @override
  String get statusRead => 'Leído';

  @override
  String get bookDetailError => 'Error al cargar los detalles del libro.';

  @override
  String get bookNotFound => 'Libro no encontrado.';

  @override
  String get meetings => 'Reuniones';

  @override
  String get noMeetings => 'Aún no hay reuniones.';

  @override
  String get comments => 'Comentarios';

  @override
  String get noComments => 'Aún no hay comentarios.';

  @override
  String get averageRating => 'Calificación promedio';

  @override
  String get noRatings => 'Aún no hay calificaciones.';

  @override
  String finishedAt(String date) {
    return 'Terminado: $date';
  }

  @override
  String get markAsRead => 'Marcar como leído';

  @override
  String get markAsReadConfirm => '¿Marcar este libro como leído?';

  @override
  String get confirm => 'Confirmar';

  @override
  String get deleteBookConfirm =>
      '¿Eliminar este libro? También se eliminarán todas las reuniones asociadas.';

  @override
  String get delete => 'Eliminar';

  @override
  String get bookDeletedSuccess => 'Libro eliminado exitosamente.';

  @override
  String get bookDeleteError =>
      'Error al eliminar el libro. Por favor, inténtalo de nuevo.';

  @override
  String get bookMarkedAsRead => 'Libro marcado como leído.';

  @override
  String get bookMarkAsReadError =>
      'Error al actualizar el estado del libro. Por favor, inténtalo de nuevo.';

  @override
  String get createMeeting => 'Crear reunión';

  @override
  String get meetingDate => 'Fecha';

  @override
  String get meetingNotes => 'Notas';

  @override
  String get meetingNotesHint => 'Ingresa las notas de la reunión';

  @override
  String get meetingPartialRating => 'Calificación parcial (1–5)';

  @override
  String get meetingPartialRatingHint => 'Ingresa una calificación entre 1 y 5';

  @override
  String get meetingRatingInvalid =>
      'La calificación debe ser un número entre 1 y 5';

  @override
  String get meetingCreatedSuccess => 'Reunión creada exitosamente';

  @override
  String get meetingUpdatedSuccess => 'Reunión actualizada exitosamente';

  @override
  String get meetingSaveError =>
      'Error al guardar la reunión. Por favor, inténtalo de nuevo.';

  @override
  String get meetingDeletedSuccess => 'Reunión eliminada exitosamente.';

  @override
  String get meetingDeleteError =>
      'Error al eliminar la reunión. Por favor, inténtalo de nuevo.';

  @override
  String get deleteMeetingConfirm => '¿Eliminar esta reunión?';

  @override
  String get meetingScreenTitle => 'Reuniones';

  @override
  String partialRating(int rating) {
    return 'Calificación: $rating★';
  }

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get addComment => 'Agregar comentario';

  @override
  String get commentHint => 'Escribe un comentario...';

  @override
  String get commentLabel => 'Comentario';

  @override
  String get commentTooShort => 'El comentario debe tener al menos 1 carácter.';

  @override
  String get commentTooLong =>
      'El comentario no debe superar los 1000 caracteres.';

  @override
  String get commentSendError =>
      'Error al enviar el comentario. Por favor, inténtalo de nuevo.';

  @override
  String get send => 'Enviar';

  @override
  String commentCharCount(int count) {
    return '$count/1000';
  }

  @override
  String get ratingOnlyForReadBooks =>
      'La calificación solo está disponible cuando el libro ha sido marcado como leído';

  @override
  String get noRatingsYet => 'Sin calificaciones';

  @override
  String get rateThisBook => 'Califica este libro';

  @override
  String get rateThisMeeting => 'Califica esta reunión';

  @override
  String get reviewQuestionsManagementTitle => 'Preguntas de Reseña';

  @override
  String get addReviewQuestion => 'Agregar pregunta';

  @override
  String get editReviewQuestion => 'Editar pregunta';

  @override
  String get deleteReviewQuestion => 'Eliminar pregunta';

  @override
  String get reviewQuestionLabel => 'Pregunta';

  @override
  String get reviewQuestionHint => 'Ingresa la pregunta de reseña';

  @override
  String get reviewQuestionOrderLabel => 'Orden';

  @override
  String get reviewQuestionOrderHint =>
      'Ingresa el orden de visualización (número)';

  @override
  String get reviewQuestionOrderInvalid => 'El orden debe ser un número válido';

  @override
  String get reviewQuestionCreatedSuccess => 'Pregunta creada exitosamente';

  @override
  String get reviewQuestionUpdatedSuccess =>
      'Pregunta actualizada exitosamente';

  @override
  String get reviewQuestionDeletedSuccess => 'Pregunta eliminada exitosamente';

  @override
  String get reviewQuestionSaveError =>
      'Error al guardar la pregunta. Por favor, inténtalo de nuevo.';

  @override
  String get reviewQuestionDeleteError =>
      'Error al eliminar la pregunta. Por favor, inténtalo de nuevo.';

  @override
  String get deleteReviewQuestionConfirm =>
      '¿Eliminar esta pregunta de reseña?';

  @override
  String get noReviewQuestions => 'Aún no hay preguntas de reseña.';

  @override
  String get reviewQuestionsForBook => 'Preguntas de Reseña';

  @override
  String get finalReviewTitle => 'Reseña Final';

  @override
  String get favoritePhrases => 'Frases Favoritas';

  @override
  String get favoritePhraseRequired =>
      'Agrega al menos una frase favorita del libro.';

  @override
  String get favoritePhraseRequiredError =>
      'Agrega al menos una frase favorita antes de enviar.';

  @override
  String get favoritePhrasesHint =>
      'Ingresa una frase favorita y presiona Agregar';

  @override
  String get addPhrase => 'Agregar';

  @override
  String get submitReview => 'Enviar Reseña';

  @override
  String get reviewSubmittedSuccess => 'Reseña enviada exitosamente';

  @override
  String get noReviewQuestionsConfigured =>
      'Este libro aún no tiene preguntas de reseña configuradas. Un líder debe agregar preguntas antes de poder enviar reseñas.';

  @override
  String get reviewSubmitError =>
      'Error al enviar la reseña. Por favor, inténtalo de nuevo.';

  @override
  String get allReviewsTitle => 'Reseñas de Miembros';

  @override
  String get noReviewsYet => 'Aún no hay reseñas.';

  @override
  String reviewByAuthor(String authorId) {
    return 'Reseña de $authorId';
  }

  @override
  String answerLabel(String answer) {
    return 'Respuesta: $answer';
  }

  @override
  String get reviewQuestionsManagementRoute => 'Gestión de Preguntas de Reseña';

  @override
  String get networkError =>
      'Error de red. Por favor, verifica tu conexión e inténtalo de nuevo.';

  @override
  String get permissionDenied =>
      'No tienes permisos para realizar esta acción.';

  @override
  String get forgotPassword => '¿Olvidé mi contraseña?';

  @override
  String get passwordRecoveryTitle => 'Restablecer contraseña';

  @override
  String get passwordRecoveryDescription =>
      'Ingresa tu dirección de correo electrónico y te enviaremos un enlace para restablecer tu contraseña.';

  @override
  String get sendResetLink => 'Enviar enlace de restablecimiento';

  @override
  String get passwordResetSent =>
      'Correo de restablecimiento de contraseña enviado exitosamente. Por favor, revisa tu correo.';

  @override
  String get passwordResetError =>
      'Error al enviar el correo de restablecimiento. Por favor, inténtalo de nuevo.';

  @override
  String get backToSignIn => 'Volver a iniciar sesión';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get nameHint => 'Ingresa tu nombre';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get confirmPasswordHint => 'Vuelve a ingresar tu contraseña';

  @override
  String get registerButton => 'Registrarse';

  @override
  String get alreadyHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get nameRequired => 'El nombre es requerido';

  @override
  String get weakPassword =>
      'La contraseña debe tener al menos 8 caracteres con mayúscula, minúscula y número';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get registrationSuccess => 'Cuenta creada exitosamente';

  @override
  String get emailAlreadyInUse => 'Este correo ya está registrado';

  @override
  String get homeScreenTitle => 'Inicio';

  @override
  String get profileTitle => 'Mi Perfil';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String registrationDate(String date) {
    return 'Miembro desde: $date';
  }

  @override
  String get noPhotoAvailable => 'Sin foto disponible';

  @override
  String get signOutConfirmTitle => 'Cerrar sesión';

  @override
  String get signOutConfirmMessage =>
      '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get editProfileTitle => 'Editar Perfil';

  @override
  String get displayNameLabel => 'Nombre';

  @override
  String get displayNameHint => 'Ingresa tu nombre';

  @override
  String get displayNameRequired => 'El nombre no puede estar vacío';

  @override
  String get profilePhotoLabel => 'Foto de Perfil';

  @override
  String get changePhoto => 'Cambiar foto';

  @override
  String get selectPhoto => 'Seleccionar foto';

  @override
  String get profileUpdatedSuccess => 'Perfil actualizado exitosamente';

  @override
  String get profileUpdateError =>
      'Error al actualizar el perfil. Por favor, inténtalo de nuevo.';

  @override
  String get libraryTitle => 'Mi Biblioteca';

  @override
  String get libraryTabWantToRead => 'Quiero leer';

  @override
  String get libraryTabReading => 'Leyendo';

  @override
  String get libraryTabRead => 'Leídos';

  @override
  String get libraryEmptyWantToRead =>
      'Aún no tienes libros en tu lista de quiero leer.';

  @override
  String get libraryEmptyReading =>
      'No estás leyendo ningún libro actualmente.';

  @override
  String get libraryEmptyRead => 'Aún no has marcado ningún libro como leído.';

  @override
  String get libraryErrorLoading =>
      'Error al cargar tu biblioteca. Por favor, inténtalo de nuevo.';

  @override
  String get libraryChangeCategory => 'Cambiar categoría';

  @override
  String get libraryRemoveFromLibrary => 'Eliminar de mi biblioteca';

  @override
  String get libraryCategoryWantToRead => 'Quiero leer';

  @override
  String get libraryCategoryReading => 'Leyendo';

  @override
  String get libraryCategoryRead => 'Leído';

  @override
  String get libraryCategoryChangedSuccess => 'Categoría actualizada';

  @override
  String get libraryRemovedSuccess => 'Libro eliminado de tu biblioteca';

  @override
  String get libraryCategoryChangeError =>
      'Error al actualizar la categoría. Por favor, inténtalo de nuevo.';

  @override
  String get libraryRemoveError =>
      'Error al eliminar el libro. Por favor, inténtalo de nuevo.';

  @override
  String get ratingCommentLabel => 'Comentario (opcional)';

  @override
  String get ratingCommentHint =>
      'Comparte tus impresiones sobre esta reunión...';

  @override
  String get saveRatingComment => 'Guardar';

  @override
  String get yourRating => 'Tu calificación:';

  @override
  String yourRatingValue(int value) {
    return '$value/5';
  }

  @override
  String get yourRatingComment => 'Tu comentario:';

  @override
  String get editRating => 'Editar calificación';

  @override
  String get ratingsScreenTitle => 'Calificaciones de Miembros';

  @override
  String get noRatingsForMeeting =>
      'Aún no hay calificaciones para esta reunión.';

  @override
  String get sortByScore => 'Ordenar por puntuación';

  @override
  String get sortByName => 'Ordenar por nombre';

  @override
  String ratingValue(int value) {
    return '$value/5';
  }

  @override
  String get viewAllRatings => 'Ver todas las calificaciones';

  @override
  String get personalBooksTitle => 'Mis Libros Personales';

  @override
  String get personalBookStatusWantToRead => 'Quiero leer';

  @override
  String get personalBookStatusReading => 'Leyendo';

  @override
  String get personalBookStatusRead => 'Leído';

  @override
  String get personalBookEmptyTitle => 'Aún no tienes libros personales';

  @override
  String get personalBookEmptyMessage =>
      'Agrega tu primer libro para comenzar a registrar tus lecturas personales.';

  @override
  String get addPersonalBook => 'Agregar libro';

  @override
  String get personalBookTitleLabel => 'Título';

  @override
  String get personalBookTitleHint => 'Ingresa el título del libro';

  @override
  String get personalBookAuthorLabel => 'Autor';

  @override
  String get personalBookAuthorHint => 'Ingresa el nombre del autor';

  @override
  String get personalBookDescriptionLabel => 'Descripción';

  @override
  String get personalBookDescriptionHint =>
      'Ingresa la descripción del libro (opcional)';

  @override
  String get personalBookCoverLabel => 'Imagen de portada';

  @override
  String get personalBookCoverHint =>
      'Toca para seleccionar una imagen de portada';

  @override
  String get personalBookStatusLabel => 'Estado';

  @override
  String get personalBookNotesLabel => 'Comentarios';

  @override
  String get personalBookNotesHint =>
      'Escribe tus comentarios personales sobre este libro...';

  @override
  String get personalBookRatingLabel => 'Tu calificación';

  @override
  String personalBookRatingValue(int value) {
    return '$value/5';
  }

  @override
  String get personalBookRatingOnlyForRead =>
      'Solo puedes calificar libros que hayan sido marcados como leídos';

  @override
  String personalBookNoteTooLong(int max, int current) {
    return 'El comentario no debe superar los $max caracteres (actual: $current)';
  }

  @override
  String get personalBookCreatedSuccess =>
      'Libro agregado a tu biblioteca personal';

  @override
  String get personalBookUpdatedSuccess => 'Libro actualizado exitosamente';

  @override
  String get personalBookDeletedSuccess =>
      'Libro eliminado de tu biblioteca personal';

  @override
  String get personalBookSaveError =>
      'Error al guardar el libro. Por favor, inténtalo de nuevo.';

  @override
  String get personalBookDeleteError =>
      'Error al eliminar el libro. Por favor, inténtalo de nuevo.';

  @override
  String get personalBookDeleteConfirm =>
      '¿Eliminar este libro de tu biblioteca personal?';

  @override
  String get personalBookErrorLoading =>
      'Error al cargar tus libros. Por favor, inténtalo de nuevo.';

  @override
  String get personalBookFilterAll => 'Todos';

  @override
  String get personalBookStartedAt => 'Started reading';

  @override
  String get personalBookFinishedAt => 'Finished reading';

  @override
  String get retry => 'Reintentar';

  @override
  String get personalBookReviewTitle => 'Reseña del Libro';

  @override
  String get personalBookReviewThoughtsLabel => 'Tus Pensamientos';

  @override
  String get personalBookReviewThoughtsHint =>
      'Comparte tus pensamientos generales sobre este libro...';

  @override
  String get personalBookReviewSubmittedSuccess =>
      'Reseña enviada exitosamente';

  @override
  String get personalBookReviewSubmitError =>
      'Error al enviar la reseña. Por favor, inténtalo de nuevo.';

  @override
  String get selectReviewQuestions => 'Seleccionar Preguntas de Reseña';

  @override
  String get selectReviewQuestionsHint =>
      'Elige qué preguntas quieres responder sobre este libro';

  @override
  String get questionsSelected => 'preguntas seleccionadas';

  @override
  String get answerSelectedQuestions => 'Responder Preguntas Seleccionadas';

  @override
  String get noQuestionsSelected =>
      'No se han seleccionado preguntas. Por favor selecciona al menos una arriba.';

  @override
  String get question => 'Pregunta';

  @override
  String get answerPlaceholder => 'Tu respuesta...';

  @override
  String get selectedQuestions => 'Preguntas Seleccionadas';

  @override
  String get questionAnswers => 'Respuestas a Preguntas';

  @override
  String get continueText => 'Continuar';

  @override
  String questionWithNumber(int number) {
    return 'Pregunta $number:';
  }

  @override
  String get userManagementTitle => 'Gestión de Usuarios';

  @override
  String get errorLoadingUsers =>
      'Error al cargar los usuarios. Por favor, inténtalo de nuevo.';

  @override
  String get noUsersFound => 'No se encontraron usuarios.';

  @override
  String get noName => 'Sin nombre';

  @override
  String get you => 'Tú';

  @override
  String get leader => 'Líder';

  @override
  String get member => 'Miembro';

  @override
  String get active => 'Activo';

  @override
  String get pending => 'Pendiente';

  @override
  String get inactive => 'Inactivo';

  @override
  String get unknown => 'Desconocido';

  @override
  String get makeAMember => 'Hacer miembro';

  @override
  String get makeALeader => 'Hacer líder';

  @override
  String get deactivate => 'Desactivar';

  @override
  String get reactivate => 'Reactivar';

  @override
  String get roleUpdatedSuccess => 'Rol actualizado exitosamente';

  @override
  String get roleUpdateError =>
      'Error al actualizar el rol. Por favor, inténtalo de nuevo.';

  @override
  String get confirmDeactivation => 'Confirmar desactivación';

  @override
  String get deactivationWarning =>
      '¿Estás seguro de que deseas desactivar este usuario? El usuario perderá acceso a la aplicación.';

  @override
  String get userDeactivatedSuccess => 'Usuario desactivado exitosamente';

  @override
  String get userReactivatedSuccess => 'Usuario reactivado exitosamente';

  @override
  String get userActionError =>
      'Error al realizar la acción. Por favor, inténtalo de nuevo.';

  @override
  String get allUsers => 'Todos los usuarios';

  @override
  String get themeDialogTitle => 'Seleccionar Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeSystemDescription => 'Usar el tema del sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeLightDescription => 'Tema claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeDarkDescription => 'Tema oscuro';

  @override
  String get languageDialogTitle => 'Seleccionar Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageSystemDescription => 'Usar idioma del sistema';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageEnglishDescription => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSpanishDescription => 'Español';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get settings => 'Configuración';

  @override
  String get bookStartDate => 'Fecha de inicio';

  @override
  String get bookEndDate => 'Fecha de fin';
}
