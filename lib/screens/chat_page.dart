import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(receiverName, style: const TextStyle(fontSize: 25)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
