import 'package:flutter/material.dart';
import 'package:key_wallet_app/services/chat/chat_service.dart';
import 'package:key_wallet_app/widgets/user_tile.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('ERRORE CHAT LIST: ${snapshot.error}');
            return const Center(child: Text('Si è verificato un errore.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nessun altro utente con un wallet trovato."));
          }

          return ListView(
              children: snapshot.data!.map<Widget>((walletData) => _buildUserListItem(walletData, context)).toList(),
          );
        }
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> walletData, BuildContext context) {
    return UserTile(
      text: walletData["name"] ?? "Wallet senza nome",
      onTap: () {
        // Usa la rotta nominativa e passa i dati come mappa
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'receiverId': walletData['userId'],
            'receiverPublicKey': walletData['publicKey'],
            'walletName': walletData['name'],
          },
        );
      },
    );
  }
}
