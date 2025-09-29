import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DeleteAppleWalletAlert extends StatelessWidget {
  const DeleteAppleWalletAlert({super.key, required this.walletName, required this.dialogContext});
  
  final dynamic walletName; // Considera di tipizzarlo meglio se possibile, es. String

  final BuildContext dialogContext;
  
  @override  
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Conferma Eliminazione'),
      content: Text(
        'Sei sicuro di voler eliminare il wallet "$walletName"? Questa azione è irreversibile e la chiave privata verrà rimossa da questo dispositivo.',
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          child: const Text('Annulla'),
          onPressed: () =>
              Navigator.of(dialogContext).pop(false), // Usa il dialogContext passato
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: const Text('Elimina'),
          onPressed: () =>
              Navigator.of(dialogContext).pop(true), // Usa il dialogContext passato
        ),
      ],
    );
  }
}
