// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Book Club';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInError => 'Sign-in failed. Please try again.';

  @override
  String get emailPasswordSignIn => 'Sign in with Email';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get invalidEmail => 'Please enter a valid email address.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters.';

  @override
  String get signInButton => 'Sign In';

  @override
  String get togglePasswordVisibility => 'Show/hide password';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get pendingAccessTitle => 'Access Pending';

  @override
  String get pendingAccessMessage =>
      'Your membership request has been submitted. A club leader will review it shortly.';

  @override
  String get waitingTitle => 'Request Under Review';

  @override
  String get waitingMessage =>
      'Your membership request is being reviewed. You will gain access once a leader approves it.';

  @override
  String get rejectedTitle => 'Access Denied';

  @override
  String get rejectedMessage =>
      'Your membership request was not approved. Please contact a club leader for more information.';

  @override
  String get signOut => 'Sign Out';

  @override
  String get loading => 'Loading...';

  @override
  String get drawerWelcome => 'Welcome!';

  @override
  String get drawerBooks => 'Books';

  @override
  String get drawerMembers => 'User Management';

  @override
  String get drawerProfile => 'My Profile';

  @override
  String get memberManagementTitle => 'Member Management';

  @override
  String get pendingRequests => 'Pending Requests';

  @override
  String get noPendingRequests => 'No pending membership requests.';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get memberApprovedSuccess => 'Membership approved.';

  @override
  String get memberRejectedSuccess => 'Membership rejected.';

  @override
  String get memberActionError => 'An error occurred. Please try again.';

  @override
  String requestedAt(String date) {
    return 'Requested: $date';
  }

  @override
  String get addBook => 'Add Book';

  @override
  String get editBook => 'Edit Book';

  @override
  String get deleteBook => 'Delete Book';

  @override
  String get addMeeting => 'Add Meeting';

  @override
  String get editMeeting => 'Edit Meeting';

  @override
  String get deleteMeeting => 'Delete Meeting';

  @override
  String get createBook => 'Create Book';

  @override
  String get bookTitle => 'Title';

  @override
  String get bookTitleHint => 'Enter book title';

  @override
  String get bookAuthor => 'Author';

  @override
  String get bookAuthorHint => 'Enter author name';

  @override
  String get bookDescription => 'Description';

  @override
  String get bookDescriptionHint => 'Enter book description';

  @override
  String get bookCover => 'Cover Image';

  @override
  String get bookCoverHint => 'Tap to select a cover image';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get bookCreatedSuccess => 'Book created successfully';

  @override
  String get bookUpdatedSuccess => 'Book updated successfully';

  @override
  String get bookSaveError => 'Error saving book. Please try again.';

  @override
  String get selectImage => 'Select Image';

  @override
  String get changeImage => 'Change Image';

  @override
  String get bookListEmpty => 'No books yet. A leader can add the first one.';

  @override
  String get bookListError => 'Error loading books. Please try again.';

  @override
  String get statusReading => 'Currently Reading';

  @override
  String get statusRead => 'Read';

  @override
  String get bookDetailError => 'Error loading book details.';

  @override
  String get bookNotFound => 'Book not found.';

  @override
  String get meetings => 'Meetings';

  @override
  String get noMeetings => 'No meetings yet.';

  @override
  String get comments => 'Comments';

  @override
  String get noComments => 'No comments yet.';

  @override
  String get averageRating => 'Average Rating';

  @override
  String get noRatings => 'No ratings yet.';

  @override
  String finishedAt(String date) {
    return 'Finished: $date';
  }

  @override
  String get markAsRead => 'Mark as Read';

  @override
  String get markAsReadConfirm => 'Mark this book as read?';

  @override
  String get confirm => 'Confirm';

  @override
  String get deleteBookConfirm =>
      'Delete this book? This will also delete all associated meetings.';

  @override
  String get delete => 'Delete';

  @override
  String get bookDeletedSuccess => 'Book deleted successfully.';

  @override
  String get bookDeleteError => 'Error deleting book. Please try again.';

  @override
  String get bookMarkedAsRead => 'Book marked as read.';

  @override
  String get bookMarkAsReadError =>
      'Error updating book status. Please try again.';

  @override
  String get createMeeting => 'Create Meeting';

  @override
  String get meetingDate => 'Date';

  @override
  String get meetingNotes => 'Notes';

  @override
  String get meetingNotesHint => 'Enter meeting notes';

  @override
  String get meetingPartialRating => 'Partial Rating (1–5)';

  @override
  String get meetingPartialRatingHint => 'Enter a rating between 1 and 5';

  @override
  String get meetingRatingInvalid => 'Rating must be a number between 1 and 5';

  @override
  String get meetingCreatedSuccess => 'Meeting created successfully';

  @override
  String get meetingUpdatedSuccess => 'Meeting updated successfully';

  @override
  String get meetingSaveError => 'Error saving meeting. Please try again.';

  @override
  String get meetingDeletedSuccess => 'Meeting deleted successfully.';

  @override
  String get meetingDeleteError => 'Error deleting meeting. Please try again.';

  @override
  String get deleteMeetingConfirm => 'Delete this meeting?';

  @override
  String get meetingScreenTitle => 'Meetings';

  @override
  String partialRating(int rating) {
    return 'Rating: $rating★';
  }

  @override
  String get selectDate => 'Select Date';

  @override
  String get addComment => 'Add Comment';

  @override
  String get commentHint => 'Write a comment...';

  @override
  String get commentLabel => 'Comment';

  @override
  String get commentTooShort => 'Comment must be at least 1 character.';

  @override
  String get commentTooLong => 'Comment must not exceed 1000 characters.';

  @override
  String get commentSendError => 'Error sending comment. Please try again.';

  @override
  String get send => 'Send';

  @override
  String commentCharCount(int count) {
    return '$count/1000';
  }

  @override
  String get ratingOnlyForReadBooks =>
      'Rating is only available when the book has been marked as read';

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String get rateThisBook => 'Rate this book';

  @override
  String get rateThisMeeting => 'Rate this meeting';

  @override
  String get reviewQuestionsManagementTitle => 'Review Questions';

  @override
  String get addReviewQuestion => 'Add Question';

  @override
  String get editReviewQuestion => 'Edit Question';

  @override
  String get deleteReviewQuestion => 'Delete Question';

  @override
  String get reviewQuestionLabel => 'Question';

  @override
  String get reviewQuestionHint => 'Enter the review question';

  @override
  String get reviewQuestionOrderLabel => 'Order';

  @override
  String get reviewQuestionOrderHint => 'Enter display order (number)';

  @override
  String get reviewQuestionOrderInvalid => 'Order must be a valid number';

  @override
  String get reviewQuestionCreatedSuccess => 'Question created successfully';

  @override
  String get reviewQuestionUpdatedSuccess => 'Question updated successfully';

  @override
  String get reviewQuestionDeletedSuccess => 'Question deleted successfully';

  @override
  String get reviewQuestionSaveError =>
      'Error saving question. Please try again.';

  @override
  String get reviewQuestionDeleteError =>
      'Error deleting question. Please try again.';

  @override
  String get deleteReviewQuestionConfirm => 'Delete this review question?';

  @override
  String get noReviewQuestions => 'No review questions yet.';

  @override
  String get reviewQuestionsForBook => 'Review Questions';

  @override
  String get finalReviewTitle => 'Final Review';

  @override
  String get favoritePhrases => 'Favorite Phrases';

  @override
  String get favoritePhraseRequired =>
      'Add at least one favorite phrase from the book.';

  @override
  String get favoritePhraseRequiredError =>
      'Add at least one favorite phrase before submitting.';

  @override
  String get favoritePhrasesHint => 'Enter a favorite phrase and press Add';

  @override
  String get addPhrase => 'Add';

  @override
  String get submitReview => 'Submit Review';

  @override
  String get reviewSubmittedSuccess => 'Review submitted successfully';

  @override
  String get noReviewQuestionsConfigured =>
      'This book has no review questions configured yet. A leader must add questions before reviews can be submitted.';

  @override
  String get reviewSubmitError => 'Error submitting review. Please try again.';

  @override
  String get allReviewsTitle => 'Member Reviews';

  @override
  String get noReviewsYet => 'No reviews yet.';

  @override
  String reviewByAuthor(String authorId) {
    return 'Review by $authorId';
  }

  @override
  String answerLabel(String answer) {
    return 'Answer: $answer';
  }

  @override
  String get reviewQuestionsManagementRoute => 'Review Questions Management';

  @override
  String get networkError =>
      'Network error. Please check your connection and try again.';

  @override
  String get permissionDenied =>
      'You don\'t have permission to perform this action.';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get passwordRecoveryTitle => 'Reset Password';

  @override
  String get passwordRecoveryDescription =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get passwordResetSent =>
      'Password reset email sent successfully. Please check your email.';

  @override
  String get passwordResetError =>
      'Error sending password reset email. Please try again.';

  @override
  String get backToSignIn => 'Back to Sign In';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'Enter your name';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get registerButton => 'Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get weakPassword =>
      'Password must be at least 8 characters with uppercase, lowercase and number';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get registrationSuccess => 'Account created successfully';

  @override
  String get emailAlreadyInUse => 'This email is already registered';

  @override
  String get homeScreenTitle => 'Home';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String registrationDate(String date) {
    return 'Member since: $date';
  }

  @override
  String get noPhotoAvailable => 'No photo available';

  @override
  String get signOutConfirmTitle => 'Sign Out';

  @override
  String get signOutConfirmMessage => 'Are you sure you want to sign out?';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get displayNameLabel => 'Name';

  @override
  String get displayNameHint => 'Enter your name';

  @override
  String get displayNameRequired => 'Name cannot be empty';

  @override
  String get profilePhotoLabel => 'Profile Photo';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get selectPhoto => 'Select Photo';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get profileUpdateError => 'Error updating profile. Please try again.';

  @override
  String get libraryTitle => 'My Library';

  @override
  String get libraryTabWantToRead => 'Want to Read';

  @override
  String get libraryTabReading => 'Reading';

  @override
  String get libraryTabRead => 'Read';

  @override
  String get libraryEmptyWantToRead =>
      'No books in your want-to-read list yet.';

  @override
  String get libraryEmptyReading => 'You are not currently reading any books.';

  @override
  String get libraryEmptyRead => 'You have not marked any books as read yet.';

  @override
  String get libraryErrorLoading =>
      'Error loading your library. Please try again.';

  @override
  String get libraryChangeCategory => 'Change category';

  @override
  String get libraryRemoveFromLibrary => 'Remove from library';

  @override
  String get libraryCategoryWantToRead => 'Want to read';

  @override
  String get libraryCategoryReading => 'Reading';

  @override
  String get libraryCategoryRead => 'Read';

  @override
  String get libraryCategoryChangedSuccess => 'Category updated';

  @override
  String get libraryRemovedSuccess => 'Book removed from library';

  @override
  String get libraryCategoryChangeError =>
      'Error updating category. Please try again.';

  @override
  String get libraryRemoveError => 'Error removing book. Please try again.';

  @override
  String get ratingCommentLabel => 'Comment (optional)';

  @override
  String get ratingCommentHint => 'Share your thoughts about this meeting...';

  @override
  String get saveRatingComment => 'Save';

  @override
  String get yourRating => 'Your rating:';

  @override
  String yourRatingValue(int value) {
    return '$value/5';
  }

  @override
  String get yourRatingComment => 'Your comment:';

  @override
  String get editRating => 'Edit rating';

  @override
  String get ratingsScreenTitle => 'Member Ratings';

  @override
  String get noRatingsForMeeting => 'No ratings yet for this meeting.';

  @override
  String get sortByScore => 'Sort by score';

  @override
  String get sortByName => 'Sort by name';

  @override
  String ratingValue(int value) {
    return '$value/5';
  }

  @override
  String get viewAllRatings => 'View all ratings';

  @override
  String get personalBooksTitle => 'My Personal Books';

  @override
  String get personalBookStatusWantToRead => 'Want to Read';

  @override
  String get personalBookStatusReading => 'Reading';

  @override
  String get personalBookStatusRead => 'Read';

  @override
  String get personalBookEmptyTitle => 'No personal books yet';

  @override
  String get personalBookEmptyMessage =>
      'Add your first book to start tracking your personal reading.';

  @override
  String get addPersonalBook => 'Add Book';

  @override
  String get personalBookTitleLabel => 'Title';

  @override
  String get personalBookTitleHint => 'Enter book title';

  @override
  String get personalBookAuthorLabel => 'Author';

  @override
  String get personalBookAuthorHint => 'Enter author name';

  @override
  String get personalBookDescriptionLabel => 'Description';

  @override
  String get personalBookDescriptionHint => 'Enter book description (optional)';

  @override
  String get personalBookCoverLabel => 'Cover Image';

  @override
  String get personalBookCoverHint => 'Tap to select a cover image';

  @override
  String get personalBookStatusLabel => 'Status';

  @override
  String get personalBookNotesLabel => 'Comments';

  @override
  String get personalBookNotesHint =>
      'Write your personal comments about this book...';

  @override
  String get personalBookRatingLabel => 'Your Rating';

  @override
  String personalBookRatingValue(int value) {
    return '$value/5';
  }

  @override
  String get personalBookRatingOnlyForRead =>
      'You can only rate books that have been marked as read';

  @override
  String personalBookNoteTooLong(int max, int current) {
    return 'Comment must not exceed $max characters (current: $current)';
  }

  @override
  String get personalBookCreatedSuccess =>
      'Book added to your personal library';

  @override
  String get personalBookUpdatedSuccess => 'Book updated successfully';

  @override
  String get personalBookDeletedSuccess =>
      'Book removed from your personal library';

  @override
  String get personalBookSaveError => 'Error saving book. Please try again.';

  @override
  String get personalBookDeleteError =>
      'Error deleting book. Please try again.';

  @override
  String get personalBookDeleteConfirm =>
      'Delete this book from your personal library?';

  @override
  String get personalBookErrorLoading =>
      'Error loading your books. Please try again.';

  @override
  String get personalBookFilterAll => 'All';

  @override
  String get personalBookStartedAt => 'Started reading';

  @override
  String get personalBookFinishedAt => 'Finished reading';

  @override
  String get retry => 'Retry';

  @override
  String get personalBookReviewTitle => 'Book Review';

  @override
  String get personalBookReviewThoughtsLabel => 'Your Thoughts';

  @override
  String get personalBookReviewThoughtsHint =>
      'Share your overall thoughts about this book...';

  @override
  String get personalBookReviewSubmittedSuccess =>
      'Review submitted successfully';

  @override
  String get personalBookReviewSubmitError =>
      'Error submitting review. Please try again.';

  @override
  String get selectReviewQuestions => 'Select Review Questions';

  @override
  String get selectReviewQuestionsHint =>
      'Choose which questions you want to answer about this book';

  @override
  String get questionsSelected => 'questions selected';

  @override
  String get answerSelectedQuestions => 'Answer Selected Questions';

  @override
  String get noQuestionsSelected =>
      'No questions selected. Please select at least one question above.';

  @override
  String get question => 'Question';

  @override
  String get answerPlaceholder => 'Your answer...';

  @override
  String get selectedQuestions => 'Selected Questions';

  @override
  String get questionAnswers => 'Question Answers';

  @override
  String get continueText => 'Continue';

  @override
  String questionWithNumber(int number) {
    return 'Question $number:';
  }

  @override
  String get userManagementTitle => 'User Management';

  @override
  String get errorLoadingUsers => 'Error loading users. Please try again.';

  @override
  String get noUsersFound => 'No users found.';

  @override
  String get noName => 'No name';

  @override
  String get you => 'You';

  @override
  String get leader => 'Leader';

  @override
  String get member => 'Member';

  @override
  String get active => 'Active';

  @override
  String get pending => 'Pending';

  @override
  String get inactive => 'Inactive';

  @override
  String get unknown => 'Unknown';

  @override
  String get makeAMember => 'Make member';

  @override
  String get makeALeader => 'Make leader';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get reactivate => 'Reactivate';

  @override
  String get roleUpdatedSuccess => 'Role updated successfully';

  @override
  String get roleUpdateError => 'Error updating role. Please try again.';

  @override
  String get confirmDeactivation => 'Confirm Deactivation';

  @override
  String get deactivationWarning =>
      'Are you sure you want to deactivate this user? The user will lose access to the application.';

  @override
  String get userDeactivatedSuccess => 'User deactivated successfully';

  @override
  String get userReactivatedSuccess => 'User reactivated successfully';

  @override
  String get userActionError => 'Error performing action. Please try again.';

  @override
  String get allUsers => 'All Users';

  @override
  String get themeDialogTitle => 'Select Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemDescription => 'Use system theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeLightDescription => 'Light theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkDescription => 'Dark theme';

  @override
  String get languageDialogTitle => 'Select Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSystemDescription => 'Use system language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageEnglishDescription => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageSpanishDescription => 'Español';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get settings => 'Settings';
}
