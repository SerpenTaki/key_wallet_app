import 'package:flutter/material.dart';

class DeletePrivatekeyDialog extends StatelessWidget {
  const DeletePrivatekeyDialog({super.key, required this.dialogContext});

  final BuildContext dialogContext;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Elimina chiave privata dal dispositivo"),
      content: const Text("Sei sicuro di voler eliminare la chiave privata dal dispositivo? Assicurati di essertela segnata"),
      actions: [
        TextButton(onPressed: () => { Navigator.of(dialogContext).pop(false)}, child: const Text("Annulla")),
        TextButton(onPressed: () => { Navigator.of(dialogContext).pop(true)}, child: const Text("Elimina", style: TextStyle(color: Colors.red)))
      ],
    );
  }
}
