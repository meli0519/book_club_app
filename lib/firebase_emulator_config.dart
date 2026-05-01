import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Connects the Firebase SDKs to the local Firebase Emulator Suite.
///
/// Call this function in your test setup (or in main() when running in
/// emulator mode) AFTER [Firebase.initializeApp()] has completed.
///
/// Default ports match those defined in firebase.json:
///   - Auth:      localhost:9099
///   - Firestore: localhost:8080
///   - Storage:   localhost:9199
Future<void> connectToFirebaseEmulators({
  String host = 'localhost',
  int authPort = 9099,
  int firestorePort = 8080,
  int storagePort = 9199,
}) async {
  await FirebaseAuth.instance.useAuthEmulator(host, authPort);

  FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);

  await FirebaseStorage.instance.useStorageEmulator(host, storagePort);
}
