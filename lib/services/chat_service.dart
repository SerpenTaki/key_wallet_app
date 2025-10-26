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

  // Ottiene un flusso di tutti i wallet con cui l'utente ha una conversazione attiva.
  Stream<List<Map<String, dynamic>>> getConversationsStream(String senderWalletId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chat_rooms')
        .where('participantUids', arrayContains: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return [];
      }

      final List<String> otherWalletIds = [];
      for (var doc in snapshot.docs) {
        final List<dynamic> participants = doc.data()['participants'];
        final otherId = participants.firstWhere((id) => id != senderWalletId, orElse: () => null);
        if (otherId != null && !otherWalletIds.contains(otherId)) {
          otherWalletIds.add(otherId);
        }
      }

      if (otherWalletIds.isEmpty) {
        return [];
      }

      final contactsSnapshot = await _firestore
          .collection('wallets')
          .where(FieldPath.documentId, whereIn: otherWalletIds)
          .get();

      return contactsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Crea il documento della chat room se non esiste già.
  Future<void> createConversationIfNotExists(Wallet wallet1, Wallet wallet2) async {
    List<String> walletIds = [wallet1.id, wallet2.id];
    walletIds.sort();
    String chatRoomId = walletIds.join("_");

    final chatRoomDocRef = _firestore.collection("chat_rooms").doc(chatRoomId);
    final chatRoomDoc = await chatRoomDocRef.get();

    // Se la chat NON esiste ancora, la creiamo
    if (!chatRoomDoc.exists) {
      await chatRoomDocRef.set({
        'participants': walletIds,
        'participantUids': [wallet1.userId, wallet2.userId],
        'last_updated': FieldValue.serverTimestamp(),
      });
      await sendMessage(wallet2, wallet1, "ciao ${wallet2.name}");
    } else {
      // Se esiste già, aggiorno solo il timestamp
      await chatRoomDocRef.set({
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }


  // Invia un messaggio da un wallet a un altro
  Future<void> sendMessage(Wallet receiverWallet, Wallet senderWallet, String message) async{
    // Assicura che la conversazione esista prima di inviare un messaggio
    await createConversationIfNotExists(senderWallet, receiverWallet);

    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    final RSAPublicKey receiverKey = parsePublicKeyFromJsonString(receiverWallet.publicKey);
    final encryptedForReceiver = rsaEncryptBase64(message, receiverKey);
    final RSAPublicKey senderKey = parsePublicKeyFromJsonString(senderWallet.publicKey);
    final encryptedForSender = rsaEncryptBase64(message, senderKey);

    final newMessage = Message(
      senderUserId: currentUserId,
      senderWalletId: senderWallet.id,
      receiverWalletId: receiverWallet.id,
      messageForReceiver: await encryptedForReceiver,
      messageForSender: await encryptedForSender,
      timestamp: timestamp,
    );

    List<String> ids = [senderWallet.id, receiverWallet.id];
    ids.sort();
    String chatRoomId = ids.join("_");
    
    final chatRoomDocRef = _firestore.collection("chat_rooms").doc(chatRoomId);
    await chatRoomDocRef.collection("messages").add(newMessage.toMap());
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
