import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:key_wallet_app/services/auth.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  StreamSubscription<User?>? _authSubscription;
  final Auth _authService = Auth(); // Istanza del servizio Auth

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      if (!mounted) return;
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );
      if (user != null) {
        walletProvider.fetchUserWallets(user.uid);
      } else {
        walletProvider.fetchUserWallets("",);
      }
    });
  }

  Future<void> _refreshData() async{
    final user = _authService.currentUser;
    if (user != null) {
      await Provider.of<WalletProvider>(context, listen: false).fetchUserWallets(user.uid);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<String?> _askWalletNameDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return showCupertinoDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          return CupertinoAlertDialog(
            title: const Text('Crea Nuovo Wallet'),
            content: CupertinoTextField(
              controller: controller,
              autofocus: true,
              placeholder: 'Nome del Wallet',
            ),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                child: const Text('Annulla'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    Navigator.of(dialogContext).pop(controller.text.trim());
                  }
                },
                child: const Text('Crea'),
              ),
            ],
          );
        },
      );
    } else {
      return showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Crea Nuovo Wallet'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Nome del Wallet'),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Annulla'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              TextButton(
                child: const Text('Crea'),
                onPressed: () {
                  if (controller.text.trim().isEmpty) {

                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text("Il nome del wallet non può essere vuoto."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text("Wallet creato con successo!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(dialogContext).pop(controller.text.trim());
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildBody(BuildContext context, WalletProvider walletProvider) {
    if (walletProvider.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (walletProvider.wallets.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Nessun wallet trovato.\nPremi il pulsante '+' per crearne uno nuovo.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        final wallet = walletProvider.wallets[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(Icons.wallet_rounded),
            title: Text(wallet.name),
            trailing: Icon(
              defaultTargetPlatform == TargetPlatform.android ? Icons.arrow_forward : Icons.arrow_forward_ios,
            ),
            onTap: () {
              Navigator.pushNamed(context, '/WalletPage', arguments: wallet);
            },
          ),
        );
      }, childCount: walletProvider.wallets.length),
    );
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
                  const Text("Key Wallet", style: TextStyle(fontWeight: FontWeight.bold),),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _refreshData,
                ),
                IconButton(
                  onPressed: signOut,
                  icon: Icon(Icons.logout, size: 25),
                ),
              ],
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),

          _buildBody(context, walletProvider)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final user = _authService.currentUser;
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Devi essere loggato per creare un wallet."),
              ),
            );
            return;
          }

          String? newWalletName = await _askWalletNameDialog(context);
          if (newWalletName != null && newWalletName.isNotEmpty) {
            context.read<WalletProvider>().generateAndAddWallet(user.uid, newWalletName,);
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
