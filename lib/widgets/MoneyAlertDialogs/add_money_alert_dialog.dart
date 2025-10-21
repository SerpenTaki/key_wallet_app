import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AddMoneyAlertDialog extends StatefulWidget {
  const AddMoneyAlertDialog({
    super.key,
  });

  @override
  State<AddMoneyAlertDialog> createState() => _AddMoneyAlertDialogState();
}

class _AddMoneyAlertDialogState extends State<AddMoneyAlertDialog> {
  final TextEditingController _amountController = TextEditingController();

  void _handleAdd() {
    final String text = _amountController.text.replaceAll(',', '.'); //toglie virgole e punti
    final double amount = double.tryParse(text) ?? 0.0; // converte a double
    Navigator.of(context).pop(amount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoAlertDialog(
        title: const Text('Aggiungi Denaro'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            placeholder: 'Inserisci l\'importo',
            prefix: const Text('€ '),
            autofocus: true,
          ),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            child: const Text('Annulla'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            onPressed: _handleAdd,
            isDefaultAction: true,
            child: const Text('Aggiungi'),
          ),
        ],
      );
    } else {
      return AlertDialog(
        title: const Text('Aggiungi Denaro'),
        content: TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Inserisci l\'importo',
            prefixText: '€ ',
          ),
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Annulla'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            onPressed: _handleAdd,
            child: const Text('Aggiungi'),
          ),
        ],
      );
    }
  }
}
