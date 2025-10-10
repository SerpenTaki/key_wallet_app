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
      /*
        Mi prendo 2 righe per commentarla
        - I messaggi che mi arrivano sono cifrati con la mia chiave pubblica e
          non sono ancora decriptati.l'unico modo che ho per cifrarli è con la mia chiave privata quindi del sender
        - I messaggi che io invio vengono criptati per il destinatario con la sua chiave pubblica, ma per la mia view sono criptati
          con la mia privata quindi del sender.
       */
      future: _chatService.translateMessage(isCurrentUser? data['messageForSender'] : data['messageForReceiver'], senderWallet,),
      builder: (context, snapshot) {
        final text = snapshot.data ?? "[Errore decriptazione]";
        return _buildBubble(text, isCurrentUser);
      },
    );
  }

  Widget _buildBubble(String message, bool isCurrentUser) {
    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ChatBubble(message: message, isCurrentUser: isCurrentUser),
    );
  }
}
