import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Sign in with Google
  /// Returns UserCredential on success
  /// Throws FirebaseAuthException on authentication failure
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Google Sign-In was cancelled by the user',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // Re-throw Firebase auth exceptions with descriptive messages
      throw FirebaseAuthException(
        code: e.code,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      // Handle any other errors
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred during sign-in: ${e.toString()}',
      );
    }
  }

  /// Sign in with email and password
  /// Returns UserCredential on success
  /// Throws FirebaseAuthException on authentication failure
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred during sign-in: ${e.toString()}',
      );
    }
  }

  /// Sign out from both Firebase and Google
  /// Revokes the active session token
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: ${e.toString()}');
    }
  }

  /// Register a new user with email, password and display name.
  /// Returns UserCredential on success.
  /// Throws FirebaseAuthException on failure.
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update the Firebase Auth profile with the display name
      await credential.user?.updateDisplayName(displayName);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred during registration: ${e.toString()}',
      );
    }
  }

  /// Send password reset email to the provided email address
  /// Throws FirebaseAuthException on failure
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get descriptive error message for Firebase Auth error codes
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'invalid-credential':
        return 'The credential is malformed or has expired.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled for this project.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'sign-in-cancelled':
        return 'Sign-in was cancelled. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
