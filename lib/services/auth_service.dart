import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Sign in with email & password
  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    final uid = currentUser?.uid;
    if (uid == null) return false;

    final snapshot = await _db.child('admins/$uid').get();
    return snapshot.exists;
  }

  /// Check if current user is driver
  Future<bool> isDriver() async {
    final uid = currentUser?.uid;
    if (uid == null) return false;

    final snapshot = await _db.child('drivers/$uid').get();
    return snapshot.exists;
  }
}
