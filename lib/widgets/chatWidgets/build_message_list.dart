import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:key_wallet_app/services/chat_service.dart';
import 'package:key_wallet_app/widgets/chatWidgets/chat_bubble.dart';
import 'package:key_wallet_app/models/wallet.dart';

class BuildMessageList extends StatelessWidget {
  final Wallet senderWallet;
  final Wallet receiverWallet;

  BuildMessageList({
    super.key,
    required this.senderWallet,
    required this.receiverWallet,
  });

  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _chatService.getMessages(senderWallet, receiverWallet),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          //print("Errore: ${snapshot.error}");
          return Text("Errore: ${snapshot.error}");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: snapshot.data!.docs
              .map((doc) => _buildMessageItem(doc))
              .toList(),
        );
      },
    );
  }


  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderWalletId'] == senderWallet.id;

    return FutureBuilder<String?>(
      future: _chatService.translateMessage(data['message'], senderWallet),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            "Errore: ${snapshot.error}",
            style: const TextStyle(color: Colors.red),
          );
        }

        // Quando il messaggio è decriptato
        final text = snapshot.data ?? "";

        var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

        return Container(
          alignment: alignment,
          child: Column(
            crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              ChatBubble(message: text, isCurrentUser: isCurrentUser),
            ],
          ),
        );
      },
    );
  }
}
