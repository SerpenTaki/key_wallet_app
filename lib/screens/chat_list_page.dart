import 'package:flutter/material.dart';
import 'package:key_wallet_app/services/chat/chat_service.dart';
import 'package:key_wallet_app/widgets/user_tile.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/widgets/build_user_list.dart';

class ChatListPage extends StatelessWidget {
  final Wallet senderWallet;

  const ChatListPage({super.key, required this.senderWallet});

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();


    return Scaffold(
      body: BuildUserList(senderWallet: senderWallet),
    );
  }
}
