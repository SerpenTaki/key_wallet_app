import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/secure_storage.dart';
import 'package:key_wallet_app/services/cryptography_gen.dart';
import 'package:key_wallet_app/widgets/KeysDialogs/delete_privatekey_dialog.dart';
import 'package:key_wallet_app/widgets/KeysDialogs/delete_privatekey_apple_dialog.dart';

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
      body: Scrollbar(
        trackVisibility: true,
        scrollbarOrientation: ScrollbarOrientation.right,
        child: SingleChildScrollView(
          primary: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Visualizza qui le tue chiavi",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
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
                      child: showPublicKey
                          ? const Text("Nascondi chiave Pubblica")
                          : const Text("Mostra chiave Pubblica"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                    IconButton(
                      onPressed: () async {
                        final bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              if (defaultTargetPlatform == TargetPlatform.iOS) {
                                return DeletePrivatekeyAppleDialog(dialogContext: dialogContext);
                              }
                              else {
                                return DeletePrivatekeyDialog(dialogContext: dialogContext);
                              }
                            }
                        );
                        if (confirmDelete == true) {
                          try {
                            await widget.secureStorage.deleteSecureData(
                                widget.wallet.localKeyIdentifier);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Chiave privata eliminata con successo"),
                                backgroundColor: Colors.green,
                              ),);
                            if(Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if(mounted){
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Errore durante l'eliminazione della chiave: ${e.toString()}"),
                                  backgroundColor: Colors.red,
                                )
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => showPrivateKey = !showPrivateKey);
                        if (showPublicKey == true) {
                          setState(() => showPublicKey = false);
                        }
                      },
                      child: showPrivateKey
                          ? const Text("Nascondi Chiave Privata")
                          : const Text("Mostra Chiave Privata"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (showPublicKey)
                  SelectableText(
                    convertPublicKeyToBase64String(widget.wallet.publicKey),
                  ),
                const SizedBox(height: 8),
                if (showPrivateKey)
                  SelectableText(
                    convertPrivateKeyToBase64String(widget.privateKeyValue),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
