import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Per CupertinoAlertDialog
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/secure_storage.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';
import 'package:provider/provider.dart';

class KeysPage extends StatefulWidget {
  final Wallet wallet;
  final String privateKeyValue;
  final SecureStorage secureStorage;

  const KeysPage({
    super.key,
    required this.wallet,
    required this.privateKeyValue,
    required this.secureStorage,
  });

  @override
  State<KeysPage> createState() => _KeysPageState();
}

class _KeysPageState extends State<KeysPage>
    with SingleTickerProviderStateMixin {
  late bool showPublicKey;
  late bool showPrivateKey;

  @override
  void initState() {
    super.initState();
    showPublicKey = false;
    showPrivateKey = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.wallet.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              final bool? confirmDelete = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  if (defaultTargetPlatform == TargetPlatform.iOS) {
                    return CupertinoAlertDialog(
                      title: const Text('Conferma Eliminazione'),
                      content: Text(
                        'Sei sicuro di voler eliminare il wallet "${widget.wallet.name}"? Questa azione è irreversibile e la chiave privata verrà rimossa da questo dispositivo.',
                      ),
                      actions: <Widget>[
                        CupertinoDialogAction(
                          child: const Text('Annulla'),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('Elimina'),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                        ),
                      ],
                    );
                  } else {
                    return AlertDialog(
                      title: const Text('Conferma Eliminazione'),
                      content: Text(
                        'Sei sicuro di voler eliminare il wallet "${widget.wallet.name}"? Questa azione è irreversibile e la chiave privata verrà rimossa da questo dispositivo.',
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Annulla'),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                        ),
                        TextButton(
                          child: const Text(
                            'Elimina',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                        ),
                      ],
                    );
                  }
                },
              );

              if (confirmDelete == true) {
                try {
                  await widget.secureStorage.deleteSecureData(
                    widget.wallet.localKeyIdentifier,
                  );
                  await Provider.of<WalletProvider>(
                    context,
                    listen: false,
                  ).deleteWallet(widget.wallet);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Wallet "${widget.wallet.name}" eliminato con successo!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  if (Navigator.canPop(context)) {
                    Navigator.pop(
                      context,
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Errore durante l\'eliminazione: ${e.toString()}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 10,
        interactive: true,
        scrollbarOrientation: ScrollbarOrientation.right,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Visualizza qui le tue chiavi",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Chiave pubblica",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => showPublicKey = !showPublicKey);
                        if (showPrivateKey == true) {
                          setState(() => showPrivateKey = false);
                        }
                      },
                      child: showPublicKey ? const Text("Nascondi chiave Pubblica") : const Text("Mostra chiave Pubblica"),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Chiave privata",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => showPrivateKey = !showPrivateKey);
                        if (showPublicKey == true) {
                          setState(() => showPublicKey = false);
                        }
                      },
                      child: showPrivateKey ? const Text("Nascondi Chiave Privata") : const Text("Mostra Chiave Privata"),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (showPublicKey) SelectableText(widget.wallet.publicKey),
                SizedBox(height: 8),
                if (showPrivateKey) SelectableText(widget.privateKeyValue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
