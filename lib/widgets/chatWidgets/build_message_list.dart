import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:key_wallet_app/services/chat_service.dart';

class BuildMessageList extends StatelessWidget {
  final String senderWalletId;
  final String receiverWalletId;

  BuildMessageList({
    super.key,
    required this.senderWalletId,
    required this.receiverWalletId,
  });

  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _chatService.getMessages(senderWalletId, receiverWalletId),
      builder: (context, snapshot){
        if(snapshot.hasError){
          //print("Errore: ${snapshot.error}");
          return Text("Errore: ${snapshot.error}");
        }
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc){
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Text(data['message']);
  }
}
