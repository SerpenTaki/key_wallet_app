import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/secureStorage.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';
import 'package:provider/provider.dart';

class WalletPage extends StatelessWidget {
  WalletPage({super.key, required this.wallet});

  final Wallet wallet;
  final SecureStorage _secureStorage = SecureStorage();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _secureStorage.readSecureData(wallet.localKeyIdentifier),
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
                  return _buildLoadingScaffold(context, "Caricamento chiave privata (interno)...",);
                } else if (innerSnapshot.hasError) {
                  return _buildErrorScaffold(context, "Errore interno: ${innerSnapshot.error}");
                } else {
                  final String? privateKeyValue = innerSnapshot.data;
                  if (privateKeyValue != null && privateKeyValue.isNotEmpty) {
                    return _buildWalletDetailsScaffold(context,privateKeyValue);
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
      appBar: AppBar(title: Text(wallet.name)),
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
      appBar: AppBar(title: Text("Errore")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(errorMessage, style: TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildWalletDetailsScaffold(
    BuildContext context,
    String? privateKeyValue,
  ) {
    // Logica per determinare il contenuto del body in base a privateKeyValue
    if (privateKeyValue == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chiave privata non presente nel dispositivo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Riprova dal dispositivo dove hai creato il wallet",
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Torna indietro"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            wallet.name,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                try {
                  // 1. Elimina da Secure Storage
                  await _secureStorage.deleteSecureData(wallet.localKeyIdentifier);
                  // 2. Elimina da Firestore (tramite Provider)
                  await Provider.of<WalletProvider>(context, listen: false).deleteWallet(context, wallet);
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
        body: Column(

        )
      );
    }
  }
}
