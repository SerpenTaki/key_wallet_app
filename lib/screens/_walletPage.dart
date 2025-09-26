import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/secureStorage.dart'; // Assicurati che sia importato

class WalletPage extends StatelessWidget {
  WalletPage({super.key, required this.wallet});

  final Wallet wallet;
  final SecureStorage _secureStorage = SecureStorage(); // Crea un'istanza una sola volta

  @override
  Widget build(BuildContext context) {
    print("Chiave pubblica (console): ${wallet.publicKey}"); // Questo è solo per il debug in console
    print("Chiave privata (console): ${_secureStorage.readSecureData(wallet.localKeyIdentifier)}");
    return Scaffold(
      appBar: AppBar(
        title: Text(wallet.name, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Scrollbar(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column( // Usiamo una Column per una migliore formattazione

            ),
          ),
        ),
      ),
    );
  }
}
