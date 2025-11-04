import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:key_wallet_app/models/message.dart';
import 'package:key_wallet_app/services/crypto_utils.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:key_wallet_app/services/secure_storage.dart';
import 'package:key_wallet_app/services/i_chat_service.dart';

class ChatService implements IChatService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SecureStorage _secureStorage;

  ChatService(
      {FirebaseFirestore? firestore,
      FirebaseAuth? auth,
      SecureStorage? secureStorage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _secureStorage = secureStorage ?? SecureStorage();


  // Ottiene le conversazioni per uno specifico wallet.
  @override
  Stream<List<Map<String, dynamic>>> getConversationsStream(
    String senderWalletId,
    String senderWalletLocalKey,
  ) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: senderWalletLocalKey)
        .snapshots()
        .asyncMap((chatRoomsSnapshot) async {
          if (chatRoomsSnapshot.docs.isEmpty) {
            return [];
          }

          // Estrae id dei partecipanti per id intendiamo gli le local key
          final List<String> otherParticipantLocalKeys = [];
          for (var doc in chatRoomsSnapshot.docs) {
            final List<dynamic> participants = doc.data()['participants'];
            final otherId = participants.firstWhere(
              (id) => id != senderWalletLocalKey,
              orElse: () => null,
            );

            if (otherId != null && !otherParticipantLocalKeys.contains(otherId)) {
              otherParticipantLocalKeys.add(otherId);
            }
          }

          if (otherParticipantLocalKeys.isEmpty) {
            return [];
          }

          final contactsSnapshot = await _firestore
              .collection('wallets')
              .where('localKeyIdentifier', whereIn: otherParticipantLocalKeys)
              .get();

          return contactsSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Crea una conversazione se non esiste.
  @override
  Future<void> createConversationIfNotExists(Wallet wallet1, Wallet wallet2,) async {
    List<String> chatID = [
      wallet1.localKeyIdentifier,
      wallet2.localKeyIdentifier,
    ];
    chatID.sort();
    String chatRoomId = chatID.join("_");

    final chatRoomDocRef = _firestore.collection("chat_rooms").doc(chatRoomId);
    final chatRoomDoc = await chatRoomDocRef.get();

    if (!chatRoomDoc.exists) {
      await chatRoomDocRef.set({
        'participants': chatID,
        'participantUids': [wallet1.userId, wallet2.userId],
        'last_updated': FieldValue.serverTimestamp(),
      });
      // await sendMessage(wallet2, wallet1, "ciao ${wallet2.name}");
    } else {
      await chatRoomDocRef.update({
        'last_updated': FieldValue.serverTimestamp(),
      });
    }
  }

  // Invia un messaggio.
  @override
  Future<void> sendMessage(Wallet receiverWallet, Wallet senderWallet, String message,) async {
    if (message.trim().isEmpty) {
      return;
    }

    final cryptoUtils = CryptoUtils();
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    final RSAPublicKey receiverKey = cryptoUtils.parsePublicKeyFromJsonString(receiverWallet.publicKey,);
    final encryptedForReceiver = await cryptoUtils.rsaEncryptBase64(message, receiverKey,);
    final RSAPublicKey senderKey = cryptoUtils.parsePublicKeyFromJsonString(senderWallet.publicKey,);
    final encryptedForSender = await cryptoUtils.rsaEncryptBase64(message, senderKey,);

    final newMessage = Message(
      senderUserId: currentUserId,
      senderWalletId: senderWallet.id,
      receiverWalletId: receiverWallet.id,
      messageForReceiver: encryptedForReceiver!,
      messageForSender: encryptedForSender!,
      timestamp: timestamp,
    );

    List<String> chatId = [
      senderWallet.localKeyIdentifier,
      receiverWallet.localKeyIdentifier,
    ];
    chatId.sort();
    String chatRoomId = chatId.join("_");

    final chatRoomDocRef = _firestore.collection("chat_rooms").doc(chatRoomId);

    // Esegui la scrittura del messaggio e l'aggiornamento della chat room in un batch per atomicità
    final batch = _firestore.batch();
    final messageRef = chatRoomDocRef.collection("messages").doc();
    batch.set(messageRef, newMessage.toMap());
    batch.update(chatRoomDocRef, {'last_updated': timestamp});
    await batch.commit();
  }

  // Ottiene i messaggi di una conversazione.
  @override
  Stream<QuerySnapshot> getMessages(Wallet senderWallet, Wallet receiverWallet,) {
    List<String> ids = [
      senderWallet.localKeyIdentifier,
      receiverWallet.localKeyIdentifier,
    ];
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
  @override
  Future<String?> translateMessage(String message, Wallet wallet) async {
    final CryptoUtils cryptoUtils = CryptoUtils();
    final walletPrivateKeyJson = await _secureStorage.readSecureData(
      wallet.localKeyIdentifier,
    );
    if (walletPrivateKeyJson == null) return "[ERRORE: nessuna chiave trovata]";

    final RSAPrivateKey receiverKey = cryptoUtils.parsePrivateKeyFromJsonString(
      walletPrivateKeyJson,
    );

    try {
      final decryptedMessage = await cryptoUtils.rsaDecryptBase64(
        message,
        receiverKey,
      );

      if (decryptedMessage == null || decryptedMessage.isEmpty) {
        return "[Vuoto dopo decriptazione]";
      }
      return decryptedMessage;
    } catch (e) {
      return "[Errore decriptazione: $e]";
    }
  }
}
