import 'dart:async'; // Import per StreamSubscription
import 'package:key_wallet_app/services/validators.dart';
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
    _authSubscription = _authService.authStateChanges.listen((User? user) {
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
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<String?> _askWalletNameDialog(BuildContext context) async { //Dialog per la creazione del wallet
    TextEditingController controller = TextEditingController();
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
                    const SnackBar(content: Text("Il nome del wallet non può essere vuoto."), backgroundColor: Colors.red,),
                  );
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text("Wallet creato con successo!"), backgroundColor: Colors.green),
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

  Widget _buildBody(BuildContext context, WalletProvider walletProvider) {
    if (walletProvider.isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
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

    // Se non sta caricando e ci sono wallet, mostra la lista
    return SliverList(
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
                // TO DO:
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
          _buildBody(context, walletProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final user = _authService.currentUser; 
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Devi essere loggato per creare un wallet.")),
            );
            return;
          }
          
          String? newWalletName = await _askWalletNameDialog(context);
          if (newWalletName != null && newWalletName.isNotEmpty) {
            context.read<WalletProvider>().generateAndAddWallet(user.uid, newWalletName);
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
