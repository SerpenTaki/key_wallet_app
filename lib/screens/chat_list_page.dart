import 'package:flutter/material.dart';
import 'package:key_wallet_app/services/chat/chat_service.dart';
import 'package:key_wallet_app/widgets/user_tile.dart';

class ChatListPage extends StatelessWidget {
  final Map<String, dynamic> senderWallet;

  const ChatListPage({super.key, required this.senderWallet});

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getWalletsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Si è verificato un errore.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nessun altro wallet trovato per chattare."));
          }

          return ListView(
            children: snapshot.data!.map<Widget>((receiverWalletData) {
              return UserTile(
                text: receiverWalletData["name"] ?? "Wallet senza nome",
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {
                      'senderWallet': senderWallet,
                      'receiverWallet': receiverWalletData,
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
