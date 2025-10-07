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
    return StreamBuilder(
        stream: _chatService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('ERROOR ERROROR ROROROROR: ${snapshot.error}');
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // controllo per lista vuota
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nessun altro utente trovato."));
          }

          return ListView(
              children: snapshot.data!.map<Widget>((userData) => _buildUserListItem(userData, context)).toList(),
          );
        }
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
    //mostra tutti gli utenti tranne il corrente
    return UserTile(text: userData["email"],
      onTap: () {
      Navigator.pushNamed(context, '/chat', arguments: userData['email']);
      },);
  }



}
