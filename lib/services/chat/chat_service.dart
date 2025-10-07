import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ottiene un flusso dei wallet, esclusi quelli dell'utente corrente.
  Stream<List<Map<String, dynamic>>> getWalletsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore.collection('wallets').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['userId'] != currentUser.uid) // Esclude i wallet dell'utente corrente
          .map((doc) {
            // Aggiunge l'ID del documento alla mappa dei dati del wallet
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();
    });
  }

  // Ottiene un flusso di tutti i wallet appartenenti all'utente loggato.
  Stream<List<Map<String, dynamic>>> getCurrentUserWalletsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('wallets')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
