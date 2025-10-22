import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';

class KeyNotFound extends StatelessWidget {
  const KeyNotFound({super.key, required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("images/logo.png", width: 100, height: 100),
            const Text('Chiave privata non trovata!', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),),
            const Text("Riprova da un altro dispositivo o recupera il tuo wallet", textAlign: TextAlign.center, style: TextStyle(fontSize: 15),),
            const SizedBox(
              height: 40,
            ),
            ElevatedButton(
                  onPressed: (){
                      Navigator.pushNamed(context, "/WalletRecoverPage", arguments: wallet);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(390, 50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  child: const Text("Recupera Wallet", style: TextStyle(fontWeight: FontWeight.bold),)
            ),
            const SizedBox(
              height: 2,
            ),
            ElevatedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(390, 50),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: const Text("Torna indietro", style: TextStyle(fontWeight: FontWeight.bold),),
            ),
          ],
        ),
      ),
    );
  }
}
