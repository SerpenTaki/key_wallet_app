import 'package:flutter/cupertino.dart';

class AddAppleWalletDialog extends StatelessWidget {
  final dynamic dialogContext;

  final dynamic controller;

  const AddAppleWalletDialog(
      {super.key, required this.controller, required this.dialogContext});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Crea Nuovo Wallet'),
      content: CupertinoTextField(
        controller: controller,
        autofocus: true,
        placeholder: 'Nome del Wallet',
      ),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          child: const Text('Annulla'),
          onPressed: () {
            Navigator.of(dialogContext).pop();
          },
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            if (controller.text
                .trim()
                .isNotEmpty) {
              Navigator.of(dialogContext).pop(controller.text.trim());
            }
          },
          child: const Text('Crea'),
        ),
      ],
    );
  }
}