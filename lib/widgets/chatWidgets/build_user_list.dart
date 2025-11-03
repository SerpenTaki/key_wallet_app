import 'package:flutter/material.dart';
import 'package:key_wallet_app/services/i_chat_service.dart';
import 'package:key_wallet_app/widgets/chatWidgets/user_tile.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:provider/provider.dart';

class BuildUserList extends StatelessWidget {
  final Wallet senderWallet;

  const BuildUserList({super.key, required this.senderWallet});

  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<IChatService>();
    return StreamBuilder(
      stream: chatService.getConversationsStream(senderWallet.id, senderWallet.localKeyIdentifier),
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
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: UserTile(
                text: receiverWallet.name,
                subtext: receiverWallet.email,
                color: receiverWallet.color,
                onTap: () {
                  Navigator.pushNamed(context, "/chat", arguments: {"senderWallet": senderWallet, "receiverWallet": receiverWallet});
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
