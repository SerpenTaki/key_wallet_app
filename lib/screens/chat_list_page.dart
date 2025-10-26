import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_user_list.dart';

class ChatListPage extends StatelessWidget {
  final Wallet senderWallet;

  const ChatListPage({super.key, required this.senderWallet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BuildUserList(senderWallet: senderWallet),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.pushNamed(context, "/findContactsPage", arguments: senderWallet);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      )
    );
  }
}
