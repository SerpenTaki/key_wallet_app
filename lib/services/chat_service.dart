import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:key_wallet_app/models/message.dart';
import 'package:key_wallet_app/services/cryptography_gen.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:key_wallet_app/services/secure_storage.dart';


class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Ottiene un flusso dei soli wallet presenti nella lista 'contacts' del mittente.
  Stream<List<Map<String, dynamic>>> getContactsStream(String senderWalletId) {
    // Ritorna un flusso che ascolta le modifiche al documento del wallet mittente
    return _firestore.collection('wallets').doc(senderWalletId).snapshots().asyncMap((senderDoc) async {
      if (!senderDoc.exists) {
        return <Map<String, dynamic>>[];
      }
      
      final senderData = senderDoc.data();
      // Controlla se il campo 'contacts' esiste e se è una lista.
      if (senderData == null || senderData['contacts'] == null || senderData['contacts'] is! List) {
          return <Map<String, dynamic>>[];
      }

      final List<dynamic> contactIds = senderData['contacts'];
      if (contactIds.isEmpty) {
        return <Map<String, dynamic>>[];
      }

      // Recupera i documenti completi per gli ID dei contatti.
      final contactsSnapshot = await _firestore
          .collection('wallets')
          .where(FieldPath.documentId, whereIn: contactIds)
          .get();

      // Mappa i documenti in una lista di dati per la UI.
      return contactsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Assicura che l'ID del documento sia incluso
        return data;
      }).toList();
    });
  }

  // Invia un messaggio da un wallet a un altro
  Future<void> sendMessage(Wallet receiverWallet, Wallet senderWallet, String message) async{
    // L'ID utente corrente per sapere chi ha inviato il messaggio
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    final RSAPublicKey receiverKey = parsePublicKeyFromJsonString(receiverWallet.publicKey);
    final encryptedForReceiver = rsaEncryptBase64(message, receiverKey);
    final RSAPublicKey senderKey = parsePublicKeyFromJsonString(senderWallet.publicKey);
    final encryptedForSender = rsaEncryptBase64(message, senderKey);

    // Crea il nuovo messaggio
    final newMessage = Message(
      currentUserID: currentUserId,
      senderWalletId: senderWallet.id,
      receiverWalletId: receiverWallet.id,
      messageForReceiver: await encryptedForReceiver,
      messageForSender: await encryptedForSender,
      timestamp: timestamp,
    );

    // Costruisce l'ID della chat room (ordinando gli ID dei wallet per coerenza)
    List<String> ids = [senderWallet.id, receiverWallet.id];
    ids.sort();
    String chatRoomId = ids.join("_");

    // Aggiunge il nuovo messaggio alla sottocollezione 'messages' della chat room
    await _firestore.collection("chat_rooms").doc(chatRoomId).collection("messages").add(newMessage.toMap());
  }

  // Ottiene il flusso di messaggi per una specifica chat room
  Stream<QuerySnapshot> getMessages(Wallet senderWallet, Wallet receiverWallet) {
    List<String> ids = [senderWallet.id, receiverWallet.id];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Funzione per decifrare un messaggio
  Future<String?> translateMessage(String message, Wallet wallet) async {
    final secureStorage = SecureStorage();
    final walletPrivateKeyJson = await secureStorage.readSecureData(wallet.localKeyIdentifier);
    if (walletPrivateKeyJson == null) return "[ERRORE: nessuna chiave trovata]";

    final RSAPrivateKey receiverKey = parsePrivateKeyFromJsonString(walletPrivateKeyJson);

    try {
      final decryptedMessage = await rsaDecryptBase64(message, receiverKey);

      if (decryptedMessage == null || decryptedMessage.isEmpty) {
        return "[Vuoto dopo decriptazione]";
      }
      return decryptedMessage;
    } catch (e) {
      return "[Errore decriptazione: $e]";
    }
  }
}
