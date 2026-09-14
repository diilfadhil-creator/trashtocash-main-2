import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trashtocash/models/user_model_firebase.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? get currentUserId => _auth.currentUser?.uid;

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  // Step 4: Register with Email and Password
  Future<UserCredential> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      await _saveUserData(user: user, name: name, email: email.trim());
    }

    return userCredential;
  }

  // Step 5: Save User Data to Firestore
  Future<void> _saveUserData({
    required User user,
    required String name,
    required String email,
  }) async {
    final userModelFirebase = UserModelFirebase(
      uid: user.uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );

    await _usersRef.doc(user.uid).set(userModelFirebase.toMap());
  }

  // Step 6: Login with Email and Password
  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Step 6: Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final doc = await _usersRef.doc(user.uid).get();
      if (!doc.exists) {
        await _saveUserData(
          user: user,
          name: user.displayName ?? 'Google User',
          email: user.email ?? '',
        );
      }
    }

    return userCredential;
  }

  // Step 9: Get User Details from Firestore
  Future<UserModelFirebase?> getUserDetails(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModelFirebase.fromMap(doc.data()!);
    }
    return null;
  }

  // Step 9: Sign Out from Firebase and Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
