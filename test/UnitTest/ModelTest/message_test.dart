import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_wallet_app/models/message.dart';

void main() {
  group('Message Model Test', () {
    test('Message object should be created with correct properties', () {
      final timestamp = Timestamp.now();
      final message = Message(
        senderUserId: 'user123',
        senderWalletId: 'walletSender456',
        receiverWalletId: 'walletReceiver789',
        messageForReceiver: 'Hello Receiver!',
        messageForSender: 'Hello Sender!',
        timestamp: timestamp,
      );


      expect(message.senderUserId, 'user123');
      expect(message.senderWalletId, 'walletSender456');
      expect(message.receiverWalletId, 'walletReceiver789');
      expect(message.messageForReceiver, 'Hello Receiver!');
      expect(message.messageForSender, 'Hello Sender!');
      expect(message.timestamp, timestamp);
    });

    test('toMap() method should return a valid map', () {
      final timestamp = Timestamp.now();
      final message = Message(
        senderUserId: 'user123',
        senderWalletId: 'walletSender456',
        receiverWalletId: 'walletReceiver789',
        messageForReceiver: 'EncryptedForReceiver',
        messageForSender: 'EncryptedForSender',
        timestamp: timestamp,
      );

      final messageMap = message.toMap();

      expect(messageMap, isA<Map<String, dynamic>>());
      expect(messageMap['senderUserId'], 'user123');
      expect(messageMap['senderWalletId'], 'walletSender456');
      expect(messageMap['receiverWalletId'], 'walletReceiver789');
      expect(messageMap['messageForReceiver'], 'EncryptedForReceiver');
      expect(messageMap['messageForSender'], 'EncryptedForSender');
      expect(messageMap['timestamp'], timestamp);
    });
  });
}
