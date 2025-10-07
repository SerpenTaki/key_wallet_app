import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  final String receiverId;
  final String receiverPublicKey;
  final String? walletName;

  ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverPublicKey,
    this.walletName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(walletName ?? "Chat"),
      ),
      body: Center(
        // Qui andrà la logica per la chat crittografata
        // Usando receiverId per creare la chat room
        // e receiverPublicKey per crittografare i messaggi.
        child: Text('Chat con utente: $receiverId'),
      ),
    );
  }
}
