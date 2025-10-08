import 'package:flutter/material.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_message_list.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_user_input.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> senderWallet;
  final Map<String, dynamic> receiverWallet;

  const ChatPage({
    super.key,
    required this.senderWallet,
    required this.receiverWallet,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  @override
  Widget build(BuildContext context) {
    final receiverName = widget.receiverWallet['name'] ?? "Wallet destinatario";

    return Scaffold(
      appBar: AppBar(
        title: Text(receiverName, style: const TextStyle(fontSize: 25)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // mostra tutti i messaggi
          Expanded(
            child: BuildMessageList(
              senderWalletId: widget.senderWallet['id'],
              receiverWalletId: widget.receiverWallet['id'],
            ),
          ),
          //mostra il campo per inviare messaggi
          BuildUserInput(receiverWalletId: widget.receiverWallet['id'], senderWalletId: widget.senderWallet['id'],),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
