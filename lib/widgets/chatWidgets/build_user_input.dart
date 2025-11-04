import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/i_chat_service.dart';
import 'package:provider/provider.dart';

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

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try { //Passo al chat service i 2 wallet e il messaggio da inviare
        final chatService = context.read<IChatService>();

        await chatService.sendMessage(
          widget.receiverWallet,
          widget.senderWallet,
          _messageController.text,
        );
        _messageController.clear();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Errore durante l'invio del messaggio: $e")),
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
              maxLength: 180,
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
