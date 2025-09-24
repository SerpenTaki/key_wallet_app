import 'dart:async'; // Import per StreamSubscription
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:key_wallet_app/services/auth.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import per User

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
    // Sottoscrivi ai cambiamenti dello stato di autenticazione
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      // È importante usare mounted per verificare che il widget sia ancora nell'albero
      if (!mounted) return;

      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      if (user != null) {
        print("LandingPage: Utente autenticato con UID: ${user.uid}. Recupero wallets...");
        walletProvider.fetchUserWallets(user.uid);
      } else {
        print("LandingPage: Utente non autenticato. Pulizia wallets...");
        walletProvider.fetchUserWallets(""); // Passa una stringa vuota per pulire i wallets
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // Annulla la sottoscrizione per evitare memory leak
    super.dispose();
  }

  Future<void> signOut() async {
    await _authService.signOut();
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
                if (walletProvider.wallets.isEmpty) {
                  return const SizedBox.shrink(); // Non mostrare nulla se la lista è vuota
                }
                final wallet = walletProvider.wallets[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.credit_card),
                    title: Text(wallet.name),
                    trailing: Icon(TargetPlatform.android == defaultTargetPlatform ? Icons.arrow_forward : Icons.arrow_forward_ios),
                    onTap: () {
                      print('Tapped on ${wallet.name}');
                      // Qui potresti navigare a una pagina di dettaglio del wallet
                    },
                    onLongPress: (){
                       print('Richiesta eliminazione per ${wallet.name}');
                       // Assicurati che deleteWallet sia aggiornato per Firestore e Secure Storage
                       walletProvider.deleteWallet(context, wallet);
                    },
                  ),
                );
              },
              childCount: walletProvider.wallets.isEmpty ? 0 : walletProvider.wallets.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          walletProvider.generateAndAddWallet(Auth().currentUser!.uid, "Nuovo Wallet");
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
