import 'package:flutter/cupertino.dart';

class DeletePrivatekeyAppleDialog extends StatelessWidget {
  const DeletePrivatekeyAppleDialog({super.key, required this.dialogContext});

  final BuildContext dialogContext;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text("Elimina chiave privata dal dispositivo"),
      content: const Text("Sei sicuro di voler eliminare la chiave privata dal dispositivo? Assicurati di essertela segnata"),
      actions: <Widget>[
        CupertinoDialogAction(
          child: const Text("Annulla"),
          onPressed: () => {Navigator.of(dialogContext).pop(false)},
        ),
        CupertinoDialogAction(
          child: const Text("Elimina"),
          onPressed: () => {Navigator.of(dialogContext).pop(true)},
        )
      ],
    );
  }
}
