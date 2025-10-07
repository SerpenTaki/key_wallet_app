import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  // Adesso riceve l'intera mappa dei dati dei wallet
  final Map<String, dynamic> senderWallet;
  final Map<String, dynamic> receiverWallet;

  const ChatPage({
    super.key,
    required this.senderWallet,
    required this.receiverWallet,
  });

  @override
  Widget build(BuildContext context) {
    // Estrae i nomi per visualizzarli, con un fallback
    final senderName = senderWallet['name'] ?? "Il tuo wallet";
    final receiverName = receiverWallet['name'] ?? "Wallet destinatario";

    // Qui definirai l'ID della chat room in modo univoco
    // ordinando gli ID dei wallet per garantire la coerenza.
    final ids = [senderWallet['id'], receiverWallet['id']]..sort();
    final chatRoomId = ids.join('_');

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con $receiverName'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Chat Room ID: $chatRoomId'),
            Text('Invii da: $senderName'),
          ],
        ),
      ),
    );
  }
}
