import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_wallet_app/models/wallet.dart';

abstract class IChatService {
  /// Restituisce un flusso di conversazioni attive per un dato wallet.
  /// Ogni conversazione è rappresentata come una mappa di dati del wallet del contatto.
  Stream<List<Map<String, dynamic>>> getConversationsStream(String senderWalletId, String localKeyIdentifier);

  /// Crea una conversazione tra due wallet se non esiste già.
  /// Se esiste, aggiorna il timestamp dell'ultima interazione.
  Future<void> createConversationIfNotExists(Wallet wallet1, Wallet wallet2);

  /// Invia un messaggio da un wallet mittente a un wallet destinatario.
  /// Il messaggio viene crittografato per entrambi i partecipanti.
  Future<void> sendMessage(Wallet receiverWallet, Wallet senderWallet, String message);

  /// Restituisce il flusso di tutti i messaggi all'interno di una specifica conversazione.
  Stream<QuerySnapshot> getMessages(Wallet senderWallet, Wallet receiverWallet);

  /// Decifra un messaggio crittografato usando la chiave privata associata al wallet.
  /// La chiave privata viene letta dal Secure Storage.
  Future<String?> translateMessage(String message, Wallet wallet);
}
