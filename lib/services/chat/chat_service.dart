import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ottiene un flusso di wallet appartenenti ad altri utenti.
  // Ogni wallet contiene l'ID dell'utente proprietario e la sua chiave pubblica.
  Stream<List<Map<String, dynamic>>> getUserStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]); // Ritorna un flusso vuoto se l'utente non è loggato.
    }

    // Ascolta la collezione 'wallets'
    return _firestore.collection('wallets').snapshots().map((snapshot) {
      final otherWallets = snapshot.docs
          .map((doc) => doc.data()) // Converte ogni documento in una mappa
          .where((walletData) => walletData['userId'] != currentUser.uid) // Esclude i wallet dell'utente corrente
          .toList();

      // Raggruppa per utente per evitare duplicati nella lista.
      // Se un utente ha più wallet, ne mostriamo solo uno.
      final Map<String, Map<String, dynamic>> uniqueUsers = {};
      for (final wallet in otherWallets) {
        final userId = wallet['userId'];
        if (!uniqueUsers.containsKey(userId)) {
          uniqueUsers[userId] = wallet;
        }
      }
      
      return uniqueUsers.values.toList();
    });
  }
}
