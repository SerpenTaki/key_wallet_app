import 'package:flutter/material.dart';
import 'package:key_wallet_app/services/chat_service.dart';
import 'package:key_wallet_app/widgets/chatWidgets/user_tile.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/screens/chat_page.dart';

class BuildUserList extends StatelessWidget {
  final Wallet senderWallet;

  BuildUserList({super.key, required this.senderWallet});

  final ChatService chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: chatService.getContactsStream(senderWallet.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Si è verificato un errore nel caricamento dei contatti.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("Nessun contatto trovato. Aggiungine uno!"),
          );
        }

        return ListView(
          children: snapshot.data!.map<Widget>((receiverWalletData) {
            return UserTile(
              text: receiverWalletData["name"],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      senderWallet: senderWallet,
                      receiverWallet: Wallet.fromMap(receiverWalletData),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
