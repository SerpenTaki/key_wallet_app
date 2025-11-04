import 'package:flutter/material.dart';

class DeleteWalletAlert extends StatelessWidget {
  const DeleteWalletAlert({super.key, required this.walletName, required this.dialogContext});

  final String walletName;
  final BuildContext dialogContext;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conferma Eliminazione'),
      content: Text(
        'Sei sicuro di voler eliminare il wallet "$walletName"? Questa azione è irreversibile e la chiave privata verrà rimossa da questo dispositivo.',
      ),
      actions: <Widget>[
        TextButton(
          key: Key("Annulla Bottone"),
          child: const Text('Annulla'),
          onPressed: () =>
              Navigator.of(dialogContext).pop(false),
        ),
        TextButton(
          key: Key("Elimina Bottone"),
          child: const Text('Elimina', style: TextStyle(color: Colors.red),),
          onPressed: () =>
              Navigator.of(dialogContext).pop(true),
        ),
      ],
    );
  }
}
