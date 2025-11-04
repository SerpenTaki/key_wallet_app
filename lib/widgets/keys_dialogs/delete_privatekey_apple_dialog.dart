import 'package:flutter/cupertino.dart';

class DeletePrivatekeyAppleDialog extends StatelessWidget {
  const DeletePrivatekeyAppleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text("Elimina chiave privata dal dispositivo"),
      content: const Text("Sei sicuro di voler eliminare la chiave privata dal dispositivo? Assicurati di essertela segnata"),
      actions: <Widget>[
        CupertinoDialogAction(key: const Key("Annulla"),child: const Text("Annulla"), onPressed: () => {Navigator.of(context).pop(false)},),
        CupertinoDialogAction( key: const Key("Elimina"), child: const Text("Elimina"), onPressed: () => {Navigator.of(context).pop(true)},)
      ],
    );
  }
}
