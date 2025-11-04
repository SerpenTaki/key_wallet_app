import 'package:flutter/material.dart';

class DeletePrivatekeyDialog extends StatelessWidget {
  const DeletePrivatekeyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Elimina chiave privata dal dispositivo"),
      content: const Text("Sei sicuro di voler eliminare la chiave privata dal dispositivo? Assicurati di essertela segnata",),
      actions: [
        TextButton(key: const Key("Annulla"), onPressed: () => Navigator.of(context).pop(false), child: const Text("Annulla"),),
        TextButton(key: const Key("Elimina"), onPressed: () => Navigator.of(context).pop(true), child: const Text("Elimina", style: TextStyle(color: Colors.red),),),
      ],
    );
  }
}
