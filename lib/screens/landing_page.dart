import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:key_wallet_app/services/auth.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:key_wallet_app/widgets/add_apple_wallet_dialog.dart';
import 'package:key_wallet_app/widgets/add_wallet_dialog.dart';

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
        walletProvider.fetchUserWallets("");
      }
    });
  }

  Future<void> _refreshData() async {
    final user = _authService.currentUser;
    if (user != null) {
      await Provider.of<WalletProvider>(
        context,
        listen: false,
      ).fetchUserWallets(user.uid);
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
          return AddAppleWalletDialog(
            controller: controller,
            dialogContext: dialogContext,
          );
        },
      );
    } else {
      return showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AddWalletDialog(
            controller: controller,
            dialogContext: dialogContext,
          );
        },
      );
    }
  }

  //Il body cambia in base a 3 condizioni, se si sta aspettando il caricamento, se il database per l'utente è vuoto
  // e se invece ci sono wallet da mostrare
  Widget _buildBody(BuildContext context, WalletProvider walletProvider) {
    if (walletProvider.isLoading) {
      // se il caricamento è in corso
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (walletProvider.wallets.isEmpty) {
      //se il caricamento è completato ma non ci sono wallet
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
      //se ci sono wallet da mostrare
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        final wallet = walletProvider.wallets[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.wallet_rounded),
            title: Text(wallet.name),
            trailing: Icon(
              defaultTargetPlatform == TargetPlatform.android
                  ? Icons.arrow_forward
                  : Icons.arrow_forward_ios,
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
            title: const Row(
              children: [
                Icon(Icons.account_balance_wallet),
                SizedBox(width: 8),
                Text("Key Wallet", style: TextStyle(fontWeight: FontWeight.bold),),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh, size: 25),
              ),
              IconButton(
                onPressed: signOut,
                icon: const Icon(Icons.logout, size: 25),
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          _buildBody(context, walletProvider), //CHIAMATA AL BUILDER DEL BODY
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addWalletButton',
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
                context.read<WalletProvider>().generateAndAddWallet(
                  user.uid,
                  newWalletName,
                );
              }
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),


          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'nfcButton',
            onPressed: () { Navigator.pushNamed(context, '/NewWalletCreation'); },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.nfc_sharp),
          ),
        ],
      ),
    );
  }
}
