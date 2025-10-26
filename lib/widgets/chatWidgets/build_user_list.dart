import 'package:flutter/material.dart';
import 'package:key_wallet_app/services/chat_service.dart';
import 'package:key_wallet_app/widgets/chatWidgets/user_tile.dart';
import 'package:key_wallet_app/models/wallet.dart';

class BuildUserList extends StatelessWidget {
  final Wallet senderWallet;

  BuildUserList({super.key, required this.senderWallet});

  final ChatService chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: chatService.getConversationsStream(senderWallet.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          //print(snapshot.error);
          return const Center(child: Text('Si è verificato un errore nel caricamento delle conversazioni.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("Nessuna conversazione trovata. Iniziane una!"),
          );
        }

        return ListView(
          children: snapshot.data!.map<Widget>((receiverWalletData) {
            final receiverWallet = Wallet.fromMap(receiverWalletData);
            return UserTile(
              text: receiverWallet.name,
              onTap: () {
                Navigator.pushNamed(context, "/chat", arguments: {"senderWallet": senderWallet, "receiverWallet": receiverWallet});
              },
            );
          }).toList(),
        );
      },
    );
  }
}
