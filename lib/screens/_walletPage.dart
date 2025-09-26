import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/secureStorage.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key, required this.wallet});

  final Wallet wallet;

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final SecureStorage _secureStorage = SecureStorage();

  late bool showPublicKey = false;

  late bool showPrivateKey = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _secureStorage.readSecureData(widget.wallet.localKeyIdentifier),
      builder: (BuildContext context, AsyncSnapshot<dynamic> mainSnapshot) {
        if (mainSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScaffold(context, "Caricamento dati sicuri...");
        } else if (mainSnapshot.hasError) {
          return _buildErrorScaffold(
            context,
            "Errore principale: ${mainSnapshot.error}",
          );
        } else if (mainSnapshot.hasData) {
          final dynamic dataFromMainFuture = mainSnapshot.data;

          if (dataFromMainFuture is Future) {
            return FutureBuilder<String?>(
              future: dataFromMainFuture as Future<String?>,
              builder: (context, innerSnapshot) {
                if (innerSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingScaffold(
                    context, "Caricamento chiave privata (interno)...",);
                } else if (innerSnapshot.hasError) {
                  return _buildErrorScaffold(
                      context, "Errore interno: ${innerSnapshot.error}");
                } else {
                  final String? privateKeyValue = innerSnapshot.data;
                  if (privateKeyValue != null && privateKeyValue.isNotEmpty) {
                    return _buildWalletDetailsScaffold(
                        context, privateKeyValue);
                  } else {
                    return _buildWalletDetailsScaffold(context, null);
                  }
                }
              },
            );
          } else {
            final String? privateKeyValue = dataFromMainFuture as String?;
            if (privateKeyValue != null && privateKeyValue.isNotEmpty) {
              return _buildWalletDetailsScaffold(context, privateKeyValue);
            } else {
              return _buildWalletDetailsScaffold(context, null);
            }
          }
        } else {
          return _buildWalletDetailsScaffold(context, null);
        }
      },
    );
  }

  Widget _buildLoadingScaffold(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.wallet.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(BuildContext context, String errorMessage) {
    return Scaffold(
      appBar: AppBar(title: const Text("Errore")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(errorMessage, style: TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildWalletDetailsScaffold(BuildContext context,
      String? privateKeyValue,) {
    // Logica per determinare il contenuto del body in base a privateKeyValue
    if (privateKeyValue == null) {
      return Scaffold(
        body: Center(
          child: Column(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chiave privata non trovata!', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),),
              const Text("Riprova da un altro dispositivo", textAlign: TextAlign.center,),
              ElevatedButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.inversePrimary,
                ),
                child: const Text("Torna indietro"),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.wallet.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .primary,
            foregroundColor: Theme
                .of(context)
                .colorScheme
                .inversePrimary,
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  try {
                    // 1. Elimina da Secure Storage
                    await _secureStorage.deleteSecureData(
                        widget.wallet.localKeyIdentifier);
                    // 2. Elimina da Firestore (tramite Provider)
                    await Provider
                        .of<WalletProvider>(context, listen: false)
                        .deleteWallet(context, widget.wallet);
                    // 3. Torna alla schermata precedente
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Errore durante l\'eliminazione: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
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
                    const Text("Visualizza qui le tue chiavi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Row(
                      spacing: 20,
                      children: [
                        const Text("Chiave pubblica", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ElevatedButton(onPressed: () {
                          setState(() => showPublicKey = !showPublicKey);
                          if (showPrivateKey == true) {
                            setState(() => showPrivateKey = false);
                          }},
                            child: showPublicKey ? const Text("Nascondi la chiave pubblica") : const Text("Mostra la chiave pubblica"))
                      ],
                    ),
                    SizedBox(height: 8),
                    if (showPublicKey)
                      PrettyQrView.data(
                        data: widget.wallet.publicKey,
                        decoration: const PrettyQrDecoration(
                          image: PrettyQrDecorationImage(
                            image: AssetImage('images/logo.png'),
                          ),
                          quietZone: PrettyQrQuietZone.standart,
                        ),
                      ),
                    Row(
                      spacing: 20,
                      children: [
                        const Text("Chiave privata", style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                        ElevatedButton(onPressed: () {
                          setState(() => showPrivateKey = !showPrivateKey);
                          if (showPublicKey == true) {
                            setState(() => showPublicKey = false);
                          }
                        },
                            child: showPrivateKey ? const Text("Nascondi la chiave privata") : const Text("Mostra la chiave privata"))
                      ],
                    ),
                    SizedBox(height: 8),
                    if (showPrivateKey)
                      SelectableText(privateKeyValue),
                  ],
                ),
              ),
            ),
          )
      );
    }
  }
}