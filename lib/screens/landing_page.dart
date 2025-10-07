import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: Icon(Icons.wallet_rounded, color: wallet.color, size: 40),
            title: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('HBytes: ${wallet.hBytes}', style: const TextStyle(fontSize: 12)),
                Text('Standard: ${wallet.standard}', style: const TextStyle(fontSize: 12)),
                Text('Creato su: ${wallet.device}', style: const TextStyle(fontSize: 12)),
              ],
            ),
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
                Text(
                  "Key Wallet",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'addWallet',
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
            Navigator.pushNamed(context, '/NewWalletCreation', arguments: user.uid,);
          },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add_card_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
