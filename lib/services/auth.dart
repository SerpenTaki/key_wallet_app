import 'package:firebase_auth/firebase_auth.dart';

class Auth{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; //abbiamo aperto un istanza di firebaseauth che si occupa dell' autenticazione
  User? get currentUser => _firebaseAuth.currentUser; //prendiamo il nostro utente
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges(); //prendiamo lo stato dell'utente


  Future<void> signInWithEmailAndPassword({required String email, required String password}) async{ //gli passo una mappa con email e password
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> createUserWithEmailAndPassword({required String email, required String password}) async{ //gli passo una mappa con email e password
    await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async{
    await _firebaseAuth.signOut();
  }

}