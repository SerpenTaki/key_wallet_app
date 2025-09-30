import 'package:flutter/material.dart';

class AddWalletDialog extends StatelessWidget {
  final dynamic dialogContext;
  final dynamic controller;

  const AddWalletDialog({super.key, required this.controller, required this.dialogContext});

  @override
  Widget build(BuildContext context) {
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
  }
}