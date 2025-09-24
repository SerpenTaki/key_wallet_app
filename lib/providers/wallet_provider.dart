import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:key_wallet_app/models/wallet.dart';

class WalletProvider with ChangeNotifier {
  final List<Wallet> _wallets = [];
  int _walletCounter = 0;

  List<Wallet> get wallets => List.unmodifiable(_wallets);

  // Metodo per generare un nuovo wallet e aggiungerlo alla lista
  Future<void> generateAndAddWallet() async {
    



    _walletCounter++;
    final newWallet = await Wallet.generateNew("Wallet $_walletCounter");
    _wallets.add(newWallet);
    notifyListeners(); // Notifica i listener (come la UI) che i dati sono cambiati
  }

  // Metodo per eliminare un wallet
  // Richiede il BuildContext per mostrare il dialogo di conferma
  Future<void> deleteWallet(BuildContext context, Wallet wallet) async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return CupertinoAlertDialog(
            title: const Text('Conferma Eliminazione'),
            content: Text('Sei sicuro di voler eliminare il wallet "${wallet.name}"?'),
            actions: <Widget>[
              CupertinoDialogAction(
                child: const Text('Annulla'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              CupertinoDialogAction(
                child: const Text('Elimina'),
                isDestructiveAction: true,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: const Text('Conferma Eliminazione'),
            content: Text('Sei sicuro di voler eliminare il wallet "${wallet.name}"?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Annulla'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                child: const Text('Elimina', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          );
        }
      },
    ) ?? false;

    if (confirmDelete) {
      _wallets.remove(wallet);
      _walletCounter--;
      notifyListeners(); // Notifica i listener del cambiamento
    }
  }
}
