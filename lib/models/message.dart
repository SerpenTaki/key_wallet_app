import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String currentUserID;
  final String senderWalletId;
  final String receiverWalletId;
  final String message;
  final Timestamp timestamp;

  Message({
    required this.currentUserID,
    required this.senderWalletId,
    required this.receiverWalletId,
    required this.message,
    required this.timestamp,
  });

  // Converte l'oggetto Message in una mappa per Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderUserId': currentUserID,
      'senderWalletId': senderWalletId,
      'receiverWalletId': receiverWalletId,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
