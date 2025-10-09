import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_message_list.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_user_input.dart';

class ChatPage extends StatefulWidget {
  final Wallet senderWallet;
  final Wallet receiverWallet;

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverWallet.name, style: const TextStyle(fontSize: 25)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        elevation: 20,
      ),
      body: Column(
        children: [
          Expanded(
            child: BuildMessageList(
              senderWallet: widget.senderWallet,
              receiverWallet: widget.receiverWallet,
            ),
          ),
          BuildUserInput(
            senderWallet: widget.senderWallet,
            receiverWallet: widget.receiverWallet,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
