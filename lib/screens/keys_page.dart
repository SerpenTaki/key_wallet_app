import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/secure_storage.dart';

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
