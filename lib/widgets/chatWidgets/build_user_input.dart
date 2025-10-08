import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/chat_service.dart';

class BuildUserInput extends StatefulWidget {
  final Wallet senderWallet;
  final Wallet receiverWallet;

  const BuildUserInput({
    super.key,
    required this.senderWallet,
    required this.receiverWallet,
  });

  @override
  State<BuildUserInput> createState() => _BuildUserInputState();
}

class _BuildUserInputState extends State<BuildUserInput> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try {
        await _chatService.sendMessage(
          widget.receiverWallet,
          widget.senderWallet,
          _messageController.text,
          widget.receiverWallet.publicKey,
        );
        _messageController.clear();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Errore durante l'invio: ${e.toString()}")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Scrivi un messaggio...",
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: sendMessage,
          ),
        ],
      ),
    );
  }
}
