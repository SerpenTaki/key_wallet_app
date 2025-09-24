import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:key_wallet_app/services/auth.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';
import 'package:provider/provider.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {

  Future<void> signOut() async {
    await Auth().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                Icon(Icons.account_balance_wallet),
                SizedBox(width: 8),
                Text("Key Wallet", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              IconButton(
                onPressed: signOut,
                icon: Icon(Icons.logout, size: 25),
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final wallet = walletProvider.wallets[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.credit_card),
                    title: Text(wallet.name),
                    trailing: Icon(TargetPlatform.android == defaultTargetPlatform ? Icons.arrow_forward : Icons.arrow_forward_ios),
                    onTap: () {
                      print('Tapped on ${wallet.name}');
                    },
                    onLongPress: (){
                       print('Richiesta eliminazione per ${wallet.name}');
                       walletProvider.deleteWallet(context, wallet);
                    },
                  ),
                );
              },
              childCount: walletProvider.wallets.length,
            ),
          ),
        ],
        shrinkWrap: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          walletProvider.generateAndAddWallet();
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
