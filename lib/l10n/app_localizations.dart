import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Book Club'**
  String get appTitle;

  /// Google sign-in button label
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Generic sign-in error message
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get signInError;

  /// Email/password sign-in button label
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get emailPasswordSignIn;

  /// Label for email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Hint for email field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// Label for password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Hint for password field
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Validation error for invalid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get invalidEmail;

  /// Validation error for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordTooShort;

  /// Sign in button label
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// Tooltip for password visibility toggle
  ///
  /// In en, this message translates to:
  /// **'Show/hide password'**
  String get togglePasswordVisibility;

  /// Text prompting user to create account
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Link to create account screen
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Title for pending access screen
  ///
  /// In en, this message translates to:
  /// **'Access Pending'**
  String get pendingAccessTitle;

  /// Message shown when membership request was just created
  ///
  /// In en, this message translates to:
  /// **'Your membership request has been submitted. A club leader will review it shortly.'**
  String get pendingAccessMessage;

  /// Title for waiting screen
  ///
  /// In en, this message translates to:
  /// **'Request Under Review'**
  String get waitingTitle;

  /// Message shown while membership is pending
  ///
  /// In en, this message translates to:
  /// **'Your membership request is being reviewed. You will gain access once a leader approves it.'**
  String get waitingMessage;

  /// Title shown when membership is rejected
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get rejectedTitle;

  /// Message shown when membership is rejected
  ///
  /// In en, this message translates to:
  /// **'Your membership request was not approved. Please contact a club leader for more information.'**
  String get rejectedMessage;

  /// Sign out button label
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Generic loading label
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Greeting shown at the top of the navigation drawer
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get drawerWelcome;

  /// Drawer menu item for books list
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get drawerBooks;

  /// Drawer menu item for member management (leaders only)
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get drawerMembers;

  /// Drawer menu item for user profile
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get drawerProfile;

  /// Title for member management screen
  ///
  /// In en, this message translates to:
  /// **'Member Management'**
  String get memberManagementTitle;

  /// Section header for pending membership requests
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// Empty state for pending requests list
  ///
  /// In en, this message translates to:
  /// **'No pending membership requests.'**
  String get noPendingRequests;

  /// Approve membership button label
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// Reject membership button label
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// Snackbar shown after approving a member
  ///
  /// In en, this message translates to:
  /// **'Membership approved.'**
  String get memberApprovedSuccess;

  /// Snackbar shown after rejecting a member
  ///
  /// In en, this message translates to:
  /// **'Membership rejected.'**
  String get memberRejectedSuccess;

  /// Snackbar shown when approve/reject fails
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get memberActionError;

  /// Label showing when membership was requested
  ///
  /// In en, this message translates to:
  /// **'Requested: {date}'**
  String requestedAt(String date);

  /// Tooltip/label for add book button (leaders only)
  ///
  /// In en, this message translates to:
  /// **'Add Book'**
  String get addBook;

  /// Tooltip/label for edit book button (leaders only)
  ///
  /// In en, this message translates to:
  /// **'Edit Book'**
  String get editBook;

  /// Tooltip/label for delete book button (leaders only)
  ///
  /// In en, this message translates to:
  /// **'Delete Book'**
  String get deleteBook;

  /// Tooltip/label for add meeting button (leaders only)
  ///
  /// In en, this message translates to:
  /// **'Add Meeting'**
  String get addMeeting;

  /// Tooltip/label for edit meeting button (leaders only)
  ///
  /// In en, this message translates to:
  /// **'Edit Meeting'**
  String get editMeeting;

  /// Tooltip/label for delete meeting button (leaders only)
  ///
  /// In en, this message translates to:
  /// **'Delete Meeting'**
  String get deleteMeeting;

  /// Title for create book screen
  ///
  /// In en, this message translates to:
  /// **'Create Book'**
  String get createBook;

  /// Label for book title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get bookTitle;

  /// Hint for book title field
  ///
  /// In en, this message translates to:
  /// **'Enter book title'**
  String get bookTitleHint;

  /// Label for book author field
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get bookAuthor;

  /// Hint for book author field
  ///
  /// In en, this message translates to:
  /// **'Enter author name'**
  String get bookAuthorHint;

  /// Label for book description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get bookDescription;

  /// Hint for book description field
  ///
  /// In en, this message translates to:
  /// **'Enter book description'**
  String get bookDescriptionHint;

  /// Label for book cover image section
  ///
  /// In en, this message translates to:
  /// **'Cover Image'**
  String get bookCover;

  /// Hint for book cover image picker
  ///
  /// In en, this message translates to:
  /// **'Tap to select a cover image'**
  String get bookCoverHint;

  /// Validation message for required fields
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Snackbar shown after creating a book
  ///
  /// In en, this message translates to:
  /// **'Book created successfully'**
  String get bookCreatedSuccess;

  /// Snackbar shown after updating a book
  ///
  /// In en, this message translates to:
  /// **'Book updated successfully'**
  String get bookUpdatedSuccess;

  /// Snackbar shown when saving a book fails
  ///
  /// In en, this message translates to:
  /// **'Error saving book. Please try again.'**
  String get bookSaveError;

  /// Button label to select a cover image
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// Button label to change the cover image
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// Empty state message for book list
  ///
  /// In en, this message translates to:
  /// **'No books yet. A leader can add the first one.'**
  String get bookListEmpty;

  /// Error message for book list
  ///
  /// In en, this message translates to:
  /// **'Error loading books. Please try again.'**
  String get bookListError;

  /// Label for books with status reading
  ///
  /// In en, this message translates to:
  /// **'Currently Reading'**
  String get statusReading;

  /// Label for books with status read
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get statusRead;

  /// Error message for book detail screen
  ///
  /// In en, this message translates to:
  /// **'Error loading book details.'**
  String get bookDetailError;

  /// Message when book is not found
  ///
  /// In en, this message translates to:
  /// **'Book not found.'**
  String get bookNotFound;

  /// Section header for meetings
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get meetings;

  /// Empty state for meetings list
  ///
  /// In en, this message translates to:
  /// **'No meetings yet.'**
  String get noMeetings;

  /// Section header for comments
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// Empty state for comments list
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noComments;

  /// Label for average rating
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get averageRating;

  /// Empty state for ratings
  ///
  /// In en, this message translates to:
  /// **'No ratings yet.'**
  String get noRatings;

  /// Label showing when book was finished
  ///
  /// In en, this message translates to:
  /// **'Finished: {date}'**
  String finishedAt(String date);

  /// Button to mark a book as read
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// Confirmation dialog title for marking book as read
  ///
  /// In en, this message translates to:
  /// **'Mark this book as read?'**
  String get markAsReadConfirm;

  /// Confirm button label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Confirmation dialog for deleting a book
  ///
  /// In en, this message translates to:
  /// **'Delete this book? This will also delete all associated meetings.'**
  String get deleteBookConfirm;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Snackbar shown after deleting a book
  ///
  /// In en, this message translates to:
  /// **'Book deleted successfully.'**
  String get bookDeletedSuccess;

  /// Snackbar shown when deleting a book fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting book. Please try again.'**
  String get bookDeleteError;

  /// Snackbar shown after marking book as read
  ///
  /// In en, this message translates to:
  /// **'Book marked as read.'**
  String get bookMarkedAsRead;

  /// Snackbar shown when marking as read fails
  ///
  /// In en, this message translates to:
  /// **'Error updating book status. Please try again.'**
  String get bookMarkAsReadError;

  /// Title for create meeting screen
  ///
  /// In en, this message translates to:
  /// **'Create Meeting'**
  String get createMeeting;

  /// Label for meeting date field
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get meetingDate;

  /// Label for meeting notes field
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get meetingNotes;

  /// Hint for meeting notes field
  ///
  /// In en, this message translates to:
  /// **'Enter meeting notes'**
  String get meetingNotesHint;

  /// Label for meeting partial rating field
  ///
  /// In en, this message translates to:
  /// **'Partial Rating (1–5)'**
  String get meetingPartialRating;

  /// Hint for meeting partial rating field
  ///
  /// In en, this message translates to:
  /// **'Enter a rating between 1 and 5'**
  String get meetingPartialRatingHint;

  /// Validation error for meeting partial rating
  ///
  /// In en, this message translates to:
  /// **'Rating must be a number between 1 and 5'**
  String get meetingRatingInvalid;

  /// Snackbar shown after creating a meeting
  ///
  /// In en, this message translates to:
  /// **'Meeting created successfully'**
  String get meetingCreatedSuccess;

  /// Snackbar shown after updating a meeting
  ///
  /// In en, this message translates to:
  /// **'Meeting updated successfully'**
  String get meetingUpdatedSuccess;

  /// Snackbar shown when saving a meeting fails
  ///
  /// In en, this message translates to:
  /// **'Error saving meeting. Please try again.'**
  String get meetingSaveError;

  /// Snackbar shown after deleting a meeting
  ///
  /// In en, this message translates to:
  /// **'Meeting deleted successfully.'**
  String get meetingDeletedSuccess;

  /// Snackbar shown when deleting a meeting fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting meeting. Please try again.'**
  String get meetingDeleteError;

  /// Confirmation dialog for deleting a meeting
  ///
  /// In en, this message translates to:
  /// **'Delete this meeting?'**
  String get deleteMeetingConfirm;

  /// Title for meeting screen
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get meetingScreenTitle;

  /// Label showing partial rating of a meeting
  ///
  /// In en, this message translates to:
  /// **'Rating: {rating}★'**
  String partialRating(int rating);

  /// Button label to select a date
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Button label to add a comment
  ///
  /// In en, this message translates to:
  /// **'Add Comment'**
  String get addComment;

  /// Hint text for comment input field
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get commentHint;

  /// Label for comment input field
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentLabel;

  /// Validation error when comment is empty
  ///
  /// In en, this message translates to:
  /// **'Comment must be at least 1 character.'**
  String get commentTooShort;

  /// Validation error when comment exceeds 1000 chars
  ///
  /// In en, this message translates to:
  /// **'Comment must not exceed 1000 characters.'**
  String get commentTooLong;

  /// Snackbar shown when sending a comment fails
  ///
  /// In en, this message translates to:
  /// **'Error sending comment. Please try again.'**
  String get commentSendError;

  /// Send button label
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Character counter for comment field
  ///
  /// In en, this message translates to:
  /// **'{count}/1000'**
  String commentCharCount(int count);

  /// Message shown when trying to rate a book that is still being read
  ///
  /// In en, this message translates to:
  /// **'Rating is only available when the book has been marked as read'**
  String get ratingOnlyForReadBooks;

  /// Shown when there are no ratings for a book or meeting
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// Label above the star rating selector for a book
  ///
  /// In en, this message translates to:
  /// **'Rate this book'**
  String get rateThisBook;

  /// Label above the star rating selector for a meeting
  ///
  /// In en, this message translates to:
  /// **'Rate this meeting'**
  String get rateThisMeeting;

  /// Title for review questions management screen
  ///
  /// In en, this message translates to:
  /// **'Review Questions'**
  String get reviewQuestionsManagementTitle;

  /// Button label to add a review question
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get addReviewQuestion;

  /// Button label to edit a review question
  ///
  /// In en, this message translates to:
  /// **'Edit Question'**
  String get editReviewQuestion;

  /// Button label to delete a review question
  ///
  /// In en, this message translates to:
  /// **'Delete Question'**
  String get deleteReviewQuestion;

  /// Label for review question text field
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get reviewQuestionLabel;

  /// Hint for review question text field
  ///
  /// In en, this message translates to:
  /// **'Enter the review question'**
  String get reviewQuestionHint;

  /// Label for review question order field
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get reviewQuestionOrderLabel;

  /// Hint for review question order field
  ///
  /// In en, this message translates to:
  /// **'Enter display order (number)'**
  String get reviewQuestionOrderHint;

  /// Validation error for review question order
  ///
  /// In en, this message translates to:
  /// **'Order must be a valid number'**
  String get reviewQuestionOrderInvalid;

  /// Snackbar after creating a review question
  ///
  /// In en, this message translates to:
  /// **'Question created successfully'**
  String get reviewQuestionCreatedSuccess;

  /// Snackbar after updating a review question
  ///
  /// In en, this message translates to:
  /// **'Question updated successfully'**
  String get reviewQuestionUpdatedSuccess;

  /// Snackbar after deleting a review question
  ///
  /// In en, this message translates to:
  /// **'Question deleted successfully'**
  String get reviewQuestionDeletedSuccess;

  /// Snackbar when saving a review question fails
  ///
  /// In en, this message translates to:
  /// **'Error saving question. Please try again.'**
  String get reviewQuestionSaveError;

  /// Snackbar when deleting a review question fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting question. Please try again.'**
  String get reviewQuestionDeleteError;

  /// Confirmation dialog for deleting a review question
  ///
  /// In en, this message translates to:
  /// **'Delete this review question?'**
  String get deleteReviewQuestionConfirm;

  /// Empty state for review questions list
  ///
  /// In en, this message translates to:
  /// **'No review questions yet.'**
  String get noReviewQuestions;

  /// Section label for selecting review questions in book form
  ///
  /// In en, this message translates to:
  /// **'Review Questions'**
  String get reviewQuestionsForBook;

  /// Section title for the final review form
  ///
  /// In en, this message translates to:
  /// **'Final Review'**
  String get finalReviewTitle;

  /// Label for favorite phrases field in final review
  ///
  /// In en, this message translates to:
  /// **'Favorite Phrases'**
  String get favoritePhrases;

  /// Hint below favorite phrases label indicating it is required
  ///
  /// In en, this message translates to:
  /// **'Add at least one favorite phrase from the book.'**
  String get favoritePhraseRequired;

  /// Validation error when no favorite phrase has been added
  ///
  /// In en, this message translates to:
  /// **'Add at least one favorite phrase before submitting.'**
  String get favoritePhraseRequiredError;

  /// Hint for favorite phrases input
  ///
  /// In en, this message translates to:
  /// **'Enter a favorite phrase and press Add'**
  String get favoritePhrasesHint;

  /// Button label to add a phrase
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addPhrase;

  /// Button label to submit the final review
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// Snackbar after submitting a final review
  ///
  /// In en, this message translates to:
  /// **'Review submitted successfully'**
  String get reviewSubmittedSuccess;

  /// Message when a book has no review questions assigned
  ///
  /// In en, this message translates to:
  /// **'This book has no review questions configured yet. A leader must add questions before reviews can be submitted.'**
  String get noReviewQuestionsConfigured;

  /// Snackbar when submitting a final review fails
  ///
  /// In en, this message translates to:
  /// **'Error submitting review. Please try again.'**
  String get reviewSubmitError;

  /// Section title for all member reviews in book detail
  ///
  /// In en, this message translates to:
  /// **'Member Reviews'**
  String get allReviewsTitle;

  /// Empty state for reviews list
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get noReviewsYet;

  /// Label showing who wrote a review
  ///
  /// In en, this message translates to:
  /// **'Review by {authorId}'**
  String reviewByAuthor(String authorId);

  /// Label showing an answer to a review question
  ///
  /// In en, this message translates to:
  /// **'Answer: {answer}'**
  String answerLabel(String answer);

  /// Navigation label for review questions management
  ///
  /// In en, this message translates to:
  /// **'Review Questions Management'**
  String get reviewQuestionsManagementRoute;

  /// Generic network error message shown in SnackBar
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection and try again.'**
  String get networkError;

  /// Error message when Firestore permission is denied
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get permissionDenied;

  /// Link to password recovery screen
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Title for password recovery screen
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get passwordRecoveryTitle;

  /// Description on password recovery screen
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get passwordRecoveryDescription;

  /// Button label to send password reset email
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// Success message after sending password reset email
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent successfully. Please check your email.'**
  String get passwordResetSent;

  /// Error message when password reset email fails
  ///
  /// In en, this message translates to:
  /// **'Error sending password reset email. Please try again.'**
  String get passwordResetError;

  /// Button label to return to sign in screen
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// Title for registration screen
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// Label for name field in registration form
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Hint for name field in registration form
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameHint;

  /// Label for email field in registration form
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Label for password field in registration form
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Label for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// Hint for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// Submit button label for registration form
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// Link back to login from registration screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// Validation error when name is empty
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// Validation error for weak password in registration
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters with uppercase, lowercase and number'**
  String get weakPassword;

  /// Validation error when passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Snackbar shown after successful registration
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get registrationSuccess;

  /// Error shown when email is already in use
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get emailAlreadyInUse;

  /// Title for the home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeScreenTitle;

  /// Title for the profile screen
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// Button label to edit profile
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Label showing user registration date
  ///
  /// In en, this message translates to:
  /// **'Member since: {date}'**
  String registrationDate(String date);

  /// Accessibility label when no profile photo is available
  ///
  /// In en, this message translates to:
  /// **'No photo available'**
  String get noPhotoAvailable;

  /// Title for sign out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutConfirmTitle;

  /// Message for sign out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmMessage;

  /// Title for edit profile screen
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// Label for display name field in edit profile
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get displayNameLabel;

  /// Hint for display name field in edit profile
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get displayNameHint;

  /// Validation error when display name is empty
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get displayNameRequired;

  /// Label for profile photo section in edit profile
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhotoLabel;

  /// Button label to change profile photo
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// Button label to select a profile photo
  ///
  /// In en, this message translates to:
  /// **'Select Photo'**
  String get selectPhoto;

  /// Snackbar shown after updating profile
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// Snackbar shown when updating profile fails
  ///
  /// In en, this message translates to:
  /// **'Error updating profile. Please try again.'**
  String get profileUpdateError;

  /// Title for the personal library screen
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get libraryTitle;

  /// Tab label for books the user wants to read
  ///
  /// In en, this message translates to:
  /// **'Want to Read'**
  String get libraryTabWantToRead;

  /// Tab label for books currently being read
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get libraryTabReading;

  /// Tab label for books already read
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get libraryTabRead;

  /// Empty state for want-to-read tab
  ///
  /// In en, this message translates to:
  /// **'No books in your want-to-read list yet.'**
  String get libraryEmptyWantToRead;

  /// Empty state for reading tab
  ///
  /// In en, this message translates to:
  /// **'You are not currently reading any books.'**
  String get libraryEmptyReading;

  /// Empty state for read tab
  ///
  /// In en, this message translates to:
  /// **'You have not marked any books as read yet.'**
  String get libraryEmptyRead;

  /// Error message for library screen
  ///
  /// In en, this message translates to:
  /// **'Error loading your library. Please try again.'**
  String get libraryErrorLoading;

  /// Popup menu label to change a book's category
  ///
  /// In en, this message translates to:
  /// **'Change category'**
  String get libraryChangeCategory;

  /// Popup menu label to remove a book from the library
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get libraryRemoveFromLibrary;

  /// Category label: want to read
  ///
  /// In en, this message translates to:
  /// **'Want to read'**
  String get libraryCategoryWantToRead;

  /// Category label: reading
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get libraryCategoryReading;

  /// Category label: read
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get libraryCategoryRead;

  /// Snackbar after changing a book's category
  ///
  /// In en, this message translates to:
  /// **'Category updated'**
  String get libraryCategoryChangedSuccess;

  /// Snackbar after removing a book from the library
  ///
  /// In en, this message translates to:
  /// **'Book removed from library'**
  String get libraryRemovedSuccess;

  /// Snackbar when changing category fails
  ///
  /// In en, this message translates to:
  /// **'Error updating category. Please try again.'**
  String get libraryCategoryChangeError;

  /// Snackbar when removing a book fails
  ///
  /// In en, this message translates to:
  /// **'Error removing book. Please try again.'**
  String get libraryRemoveError;

  /// Label for the optional comment field in the meeting rating widget
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get ratingCommentLabel;

  /// Hint text for the optional comment field in the meeting rating widget
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts about this meeting...'**
  String get ratingCommentHint;

  /// Button label to save the rating with its optional comment
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveRatingComment;

  /// Label shown before the user's current rating summary
  ///
  /// In en, this message translates to:
  /// **'Your rating:'**
  String get yourRating;

  /// Shows the numeric value of the user's rating
  ///
  /// In en, this message translates to:
  /// **'{value}/5'**
  String yourRatingValue(int value);

  /// Label shown before the user's existing rating comment
  ///
  /// In en, this message translates to:
  /// **'Your comment:'**
  String get yourRatingComment;

  /// Button label to expand the rating edit controls
  ///
  /// In en, this message translates to:
  /// **'Edit rating'**
  String get editRating;

  /// Title for the ratings screen showing all member ratings
  ///
  /// In en, this message translates to:
  /// **'Member Ratings'**
  String get ratingsScreenTitle;

  /// Empty state for ratings screen
  ///
  /// In en, this message translates to:
  /// **'No ratings yet for this meeting.'**
  String get noRatingsForMeeting;

  /// Sort option: by score
  ///
  /// In en, this message translates to:
  /// **'Sort by score'**
  String get sortByScore;

  /// Sort option: by name
  ///
  /// In en, this message translates to:
  /// **'Sort by name'**
  String get sortByName;

  /// Shows the numeric value of a rating
  ///
  /// In en, this message translates to:
  /// **'{value}/5'**
  String ratingValue(int value);

  /// Button/link to open the ratings screen
  ///
  /// In en, this message translates to:
  /// **'View all ratings'**
  String get viewAllRatings;

  /// Title for the personal books screen
  ///
  /// In en, this message translates to:
  /// **'My Personal Books'**
  String get personalBooksTitle;

  /// Status label for want to read
  ///
  /// In en, this message translates to:
  /// **'Want to Read'**
  String get personalBookStatusWantToRead;

  /// Status label for currently reading
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get personalBookStatusReading;

  /// Status label for read books
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get personalBookStatusRead;

  /// Empty state title for personal books list
  ///
  /// In en, this message translates to:
  /// **'No personal books yet'**
  String get personalBookEmptyTitle;

  /// Empty state message for personal books list
  ///
  /// In en, this message translates to:
  /// **'Add your first book to start tracking your personal reading.'**
  String get personalBookEmptyMessage;

  /// Button label to add a personal book
  ///
  /// In en, this message translates to:
  /// **'Add Book'**
  String get addPersonalBook;

  /// Label for title field in personal book form
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get personalBookTitleLabel;

  /// Hint for title field in personal book form
  ///
  /// In en, this message translates to:
  /// **'Enter book title'**
  String get personalBookTitleHint;

  /// Label for author field in personal book form
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get personalBookAuthorLabel;

  /// Hint for author field in personal book form
  ///
  /// In en, this message translates to:
  /// **'Enter author name'**
  String get personalBookAuthorHint;

  /// Label for description field in personal book form
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get personalBookDescriptionLabel;

  /// Hint for description field in personal book form
  ///
  /// In en, this message translates to:
  /// **'Enter book description (optional)'**
  String get personalBookDescriptionHint;

  /// Label for cover image in personal book form
  ///
  /// In en, this message translates to:
  /// **'Cover Image'**
  String get personalBookCoverLabel;

  /// Hint for cover image picker in personal book form
  ///
  /// In en, this message translates to:
  /// **'Tap to select a cover image'**
  String get personalBookCoverHint;

  /// Label for status dropdown in personal book form
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get personalBookStatusLabel;

  /// Label for comments field in personal book detail
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get personalBookNotesLabel;

  /// Hint for comments field in personal book detail
  ///
  /// In en, this message translates to:
  /// **'Write your personal comments about this book...'**
  String get personalBookNotesHint;

  /// Label for rating widget in personal book detail
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get personalBookRatingLabel;

  /// Shows the numeric value of the rating
  ///
  /// In en, this message translates to:
  /// **'{value}/5'**
  String personalBookRatingValue(int value);

  /// Message shown when trying to rate a book that is not read
  ///
  /// In en, this message translates to:
  /// **'You can only rate books that have been marked as read'**
  String get personalBookRatingOnlyForRead;

  /// Error message when comment exceeds maximum length
  ///
  /// In en, this message translates to:
  /// **'Comment must not exceed {max} characters (current: {current})'**
  String personalBookNoteTooLong(int max, int current);

  /// Snackbar shown after creating a personal book
  ///
  /// In en, this message translates to:
  /// **'Book added to your personal library'**
  String get personalBookCreatedSuccess;

  /// Snackbar shown after updating a personal book
  ///
  /// In en, this message translates to:
  /// **'Book updated successfully'**
  String get personalBookUpdatedSuccess;

  /// Snackbar shown after deleting a personal book
  ///
  /// In en, this message translates to:
  /// **'Book removed from your personal library'**
  String get personalBookDeletedSuccess;

  /// Snackbar shown when saving a personal book fails
  ///
  /// In en, this message translates to:
  /// **'Error saving book. Please try again.'**
  String get personalBookSaveError;

  /// Snackbar shown when deleting a personal book fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting book. Please try again.'**
  String get personalBookDeleteError;

  /// Confirmation dialog for deleting a personal book
  ///
  /// In en, this message translates to:
  /// **'Delete this book from your personal library?'**
  String get personalBookDeleteConfirm;

  /// Error message for personal books screen
  ///
  /// In en, this message translates to:
  /// **'Error loading your books. Please try again.'**
  String get personalBookErrorLoading;

  /// Filter option to show all books
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get personalBookFilterAll;

  /// Label for started reading date
  ///
  /// In en, this message translates to:
  /// **'Started reading'**
  String get personalBookStartedAt;

  /// Label for finished reading date
  ///
  /// In en, this message translates to:
  /// **'Finished reading'**
  String get personalBookFinishedAt;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Title for personal book review section
  ///
  /// In en, this message translates to:
  /// **'Book Review'**
  String get personalBookReviewTitle;

  /// Label for thoughts field in personal book review
  ///
  /// In en, this message translates to:
  /// **'Your Thoughts'**
  String get personalBookReviewThoughtsLabel;

  /// Hint for thoughts field in personal book review
  ///
  /// In en, this message translates to:
  /// **'Share your overall thoughts about this book...'**
  String get personalBookReviewThoughtsHint;

  /// Snackbar shown after submitting a personal book review
  ///
  /// In en, this message translates to:
  /// **'Review submitted successfully'**
  String get personalBookReviewSubmittedSuccess;

  /// Snackbar shown when submitting a personal book review fails
  ///
  /// In en, this message translates to:
  /// **'Error submitting review. Please try again.'**
  String get personalBookReviewSubmitError;

  /// Title for question selection section
  ///
  /// In en, this message translates to:
  /// **'Select Review Questions'**
  String get selectReviewQuestions;

  /// Hint text for question selection
  ///
  /// In en, this message translates to:
  /// **'Choose which questions you want to answer about this book'**
  String get selectReviewQuestionsHint;

  /// Label showing number of selected questions
  ///
  /// In en, this message translates to:
  /// **'questions selected'**
  String get questionsSelected;

  /// Title for question answers section
  ///
  /// In en, this message translates to:
  /// **'Answer Selected Questions'**
  String get answerSelectedQuestions;

  /// Message when no questions are selected
  ///
  /// In en, this message translates to:
  /// **'No questions selected. Please select at least one question above.'**
  String get noQuestionsSelected;

  /// Label for question field
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// Hint for answer field
  ///
  /// In en, this message translates to:
  /// **'Your answer...'**
  String get answerPlaceholder;

  /// Label for selected questions section in summary
  ///
  /// In en, this message translates to:
  /// **'Selected Questions'**
  String get selectedQuestions;

  /// Label for question answers section in summary
  ///
  /// In en, this message translates to:
  /// **'Question Answers'**
  String get questionAnswers;

  /// Button label to continue to next step
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// Label for question with number
  ///
  /// In en, this message translates to:
  /// **'Question {number}:'**
  String questionWithNumber(int number);

  /// Title for user management screen
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagementTitle;

  /// Error message when loading users fails
  ///
  /// In en, this message translates to:
  /// **'Error loading users. Please try again.'**
  String get errorLoadingUsers;

  /// Message when no users are found
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get noUsersFound;

  /// Placeholder when user has no display name
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get noName;

  /// Label to indicate current user
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Label for leader role
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get leader;

  /// Label for member role
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// Label for active membership status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Label for pending membership status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Label for inactive/rejected membership status
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Label for unknown status
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Button label to change user role to member
  ///
  /// In en, this message translates to:
  /// **'Make member'**
  String get makeAMember;

  /// Button label to change user role to leader
  ///
  /// In en, this message translates to:
  /// **'Make leader'**
  String get makeALeader;

  /// Button label to deactivate a user
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// Button label to reactivate a user
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivate;

  /// Snackbar shown after successfully updating user role
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully'**
  String get roleUpdatedSuccess;

  /// Snackbar shown when updating user role fails
  ///
  /// In en, this message translates to:
  /// **'Error updating role. Please try again.'**
  String get roleUpdateError;

  /// Title for deactivation confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm Deactivation'**
  String get confirmDeactivation;

  /// Warning message in deactivation confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this user? The user will lose access to the application.'**
  String get deactivationWarning;

  /// Snackbar shown after successfully deactivating a user
  ///
  /// In en, this message translates to:
  /// **'User deactivated successfully'**
  String get userDeactivatedSuccess;

  /// Snackbar shown after successfully reactivating a user
  ///
  /// In en, this message translates to:
  /// **'User reactivated successfully'**
  String get userReactivatedSuccess;

  /// Snackbar shown when a user action fails
  ///
  /// In en, this message translates to:
  /// **'Error performing action. Please try again.'**
  String get userActionError;

  /// Tab label for all users in member management screen
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// Title for theme selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get themeDialogTitle;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Description for system theme option
  ///
  /// In en, this message translates to:
  /// **'Use system theme'**
  String get themeSystemDescription;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Description for light theme option
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get themeLightDescription;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Description for dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get themeDarkDescription;

  /// Title for language selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get languageDialogTitle;

  /// System language option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Description for system language option
  ///
  /// In en, this message translates to:
  /// **'Use system language'**
  String get languageSystemDescription;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Description for English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishDescription;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// Description for Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanishDescription;

  /// Label for language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Label for theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Label for settings section
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
