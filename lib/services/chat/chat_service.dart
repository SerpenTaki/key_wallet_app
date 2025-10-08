import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:key_wallet_app/models/message.dart';


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

  // Invia un messaggio da un wallet a un altro
  Future<void> sendMessage(String receiverWalletId, String senderWalletId, String message) async{
    // L'ID utente corrente per sapere chi ha inviato il messaggio
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    // Crea il nuovo messaggio
    final newMessage = Message(
      currentUserID: currentUserId,
      senderWalletId: senderWalletId,
      receiverWalletId: receiverWalletId,
      message: message,
      timestamp: timestamp,
    );

    // Costruisce l'ID della chat room (ordinando gli ID dei wallet per coerenza)
    List<String> ids = [senderWalletId, receiverWalletId];
    ids.sort(); //Fa si che l'ID della chat room sia sempre uguale per 2 wallet
    String chatRoomId = ids.join("_");

    // Aggiunge il nuovo messaggio alla sottocollezione 'messages' della chat room
    await _firestore.collection("chat_rooms").doc(chatRoomId).collection("messages").add(newMessage.toMap());
  }

  // Ottiene il flusso di messaggi per una specifica chat room
  Stream<QuerySnapshot> getMessages(String walletId1, String walletId2) {
    // Costruisce l'ID della chat room nello stesso modo per recuperare i messaggi
    List<String> ids = [walletId1, walletId2];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

}
