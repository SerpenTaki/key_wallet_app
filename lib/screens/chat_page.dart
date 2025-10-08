import 'package:flutter/material.dart';
import 'package:key_wallet_app/services/chat/chat_service.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_message_list.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverWallet['id'],
        widget.senderWallet['id'],
        _messageController.text,
      );
    }

    _messageController.clear();
  }

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
          _buildUserInput(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildUserInput(){
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Scrivi un messaggio...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(left: 10),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
