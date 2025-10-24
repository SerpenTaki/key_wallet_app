import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderUserId;
  final String senderWalletId;
  final String receiverWalletId;
  final String? messageForReceiver;
  final String? messageForSender;
  final Timestamp timestamp;

  Message({
    required this.senderUserId,
    required this.senderWalletId,
    required this.receiverWalletId,
    required this.messageForReceiver,
    required this.messageForSender,
    required this.timestamp,
  });

  // Converte l'oggetto Message in una mappa per Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderUserId': senderUserId,
      'senderWalletId': senderWalletId,
      'receiverWalletId': receiverWalletId,
      'messageForReceiver': messageForReceiver,
      'messageForSender': messageForSender,
      'timestamp': timestamp,
    };
  }
}
