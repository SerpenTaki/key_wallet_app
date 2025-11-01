import 'package:firebase_auth/firebase_auth.dart';

abstract class IAuth {
  User? get currentUser;  Stream<User?> get authStateChanges;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
