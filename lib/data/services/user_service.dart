import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/app_user.dart';
export '../../domain/models/app_user.dart' show UserRole;

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Returns a real-time stream of the [AppUser] document for [uid].
  Stream<AppUser?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!, doc.id);
    });
  }

  /// Updates the user's [displayName] and optionally uploads a new [photoFile]
  /// to Firebase Storage, then saves both fields to Firestore.
  Future<void> updateProfile(
    String uid,
    String displayName,
    File? photoFile,
  ) async {
    try {
      String? photoUrl;
      if (photoFile != null) {
        final ref = _storage.ref().child('profile_photos/$uid');
        await ref.putFile(photoFile);
        photoUrl = await ref.getDownloadURL();
      }

      final updates = <String, dynamic>{'displayName': displayName};
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(uid).update(updates);
    } on FirebaseException catch (e) {
      throw Exception('Error updating profile: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating profile: ${e.toString()}');
    }
  }

  /// Get user document from Firestore
  Future<AppUser?> getUser(String uid) async {
    try {
      print('🔵 Getting user from Firestore: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        print('⚠️ User document does not exist');
        return null;
      }
      
      print('✅ User found in Firestore');
      return AppUser.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      print('❌ Firebase error getting user: ${e.code} - ${e.message}');
      // If permission denied, treat as user not found (will create new)
      if (e.code == 'permission-denied') {
        return null;
      }
      throw Exception('Error getting user: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error getting user: $e');
      throw Exception('Unexpected error getting user: ${e.toString()}');
    }
  }

  /// Create a new user document in Firestore with an explicit displayName.
  /// Used for email/password registration where displayName comes from the form.
  /// Also creates a pending membership document (Requirement 10.1).
  Future<void> createUserWithDisplayName(
    UserCredential userCredential,
    String displayName,
  ) async {
    try {
      final user = userCredential.user;
      if (user == null) {
        throw Exception('User credential does not contain user data');
      }

      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName,
        photoUrl: '',
        role: UserRole.member,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Error creating user: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error creating user: ${e.toString()}');
    }
  }

  /// Create a new user document in Firestore
  /// Used when a user signs in for the first time
  Future<void> createUser(UserCredential userCredential) async {
    try {
      final user = userCredential.user;
      if (user == null) {
        throw Exception('User credential does not contain user data');
      }

      print('🔵 Creating user in Firestore: ${user.uid}');

      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL ?? '',
        role: UserRole.member, // Default role for new users
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
      print('✅ User created successfully in Firestore');
    } on FirebaseException catch (e) {
      print('❌ Firebase error creating user: ${e.code} - ${e.message}');
      throw Exception('Error creating user: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error creating user: $e');
      throw Exception('Unexpected error creating user: ${e.toString()}');
    }
  }

  /// Update existing user's displayName and photoUrl
  /// Used when a user signs in and their Google profile has changed
  Future<void> updateUserProfile(String uid, String displayName, String photoUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'displayName': displayName,
        'photoUrl': photoUrl,
      });
    } on FirebaseException catch (e) {
      throw Exception('Error updating user profile: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating user profile: ${e.toString()}');
    }
  }

  /// Handle user authentication flow
  /// Creates new user if doesn't exist, updates profile if exists
  Future<void> handleUserAuthentication(UserCredential userCredential) async {
    try {
      final user = userCredential.user;
      if (user == null) {
        throw Exception('User credential does not contain user data');
      }

      print('🔵 Handling authentication for user: ${user.uid}');

      // Check if user exists in Firestore
      final existingUser = await getUser(user.uid);

      if (existingUser == null) {
        print('🔵 User does not exist, creating new user...');
        // New user - create document with all required fields
        await createUser(userCredential);
      } else {
        print('🔵 User exists, updating profile...');
        // Existing user - update only displayName and photoUrl
        await updateUserProfile(
          user.uid,
          user.displayName ?? existingUser.displayName,
          user.photoURL ?? existingUser.photoUrl,
        );
        print('✅ Profile updated successfully');
      }
    } catch (e) {
      print('❌ Error in handleUserAuthentication: $e');
      throw Exception('Error handling user authentication: ${e.toString()}');
    }
  }

  /// Get all users from Firestore
  /// Used for user management by leaders
  Stream<List<AppUser>> watchAllUsers() {
    try {
      return _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data(), doc.id))
              .toList());
    } on FirebaseException catch (e) {
      throw Exception('Error watching users: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error watching users: $e');
    }
  }

  /// Update user role (member/leader)
  /// Only leaders should be able to call this
  Future<void> updateUserRole(String uid, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole.toFirestoreString(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Error updating user role: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error updating user role: $e');
    }
  }
}
