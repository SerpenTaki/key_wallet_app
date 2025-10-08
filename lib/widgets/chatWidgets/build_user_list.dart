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
      stream: chatService.getWalletsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Si è verificato un errore.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("Nessun altro wallet trovato per chattare."),
          );
        }

        return ListView(
          children: snapshot.data!.map<Widget>((receiverWalletData) {
            // Evita di mostrare il wallet dell'utente corrente nella lista
            if (receiverWalletData['id'] == senderWallet.id) {
              return const SizedBox.shrink(); 
            }
            
            return UserTile(
              text: receiverWalletData["name"] ?? "Wallet senza nome",
              onTap: () {
                // Correzione: Uso Navigator.push per passare direttamente i due wallet.
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
