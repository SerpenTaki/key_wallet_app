import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/secure_storage.dart';
import 'package:key_wallet_app/ErrorScreens/key_not_found.dart';
import 'package:key_wallet_app/screens/keys_page.dart';
import 'package:key_wallet_app/widgets/delete_apple_wallet_alert.dart';
import 'package:key_wallet_app/widgets/delete_wallet_alert.dart';
import 'package:key_wallet_app/screens/rsa_test_page.dart'; 
import 'package:key_wallet_app/screens/docs_page.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';

class WalletPage extends StatefulWidget {
  WalletPage({super.key, required this.wallet});

  final Wallet wallet;
  final SecureStorage _secureStorage = SecureStorage();

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
            "Errore durante il caricamento della chiave: ${mainSnapshot.error.toString()}",
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
                      context,
                      "Errore interno caricamento chiave: ${innerSnapshot.error.toString()}");
                } else {
                  return _buildWalletDetailsScaffold(
                      context, innerSnapshot.data);
                }
              },
            );
          } else {
            final String? privateKeyValue = dataFromMainFuture as String?;
            return _buildWalletDetailsScaffold(context, privateKeyValue);
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
          child: Text(
            errorMessage, style: TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,),
        ),
      ),
    );
  }

  Widget _buildWalletDetailsScaffold(BuildContext context,
      String? privateKeyValue,) {
    if (privateKeyValue == null || privateKeyValue.isEmpty) {
      return KeyNotFound();
    } else {
      // NOTA: La label per la tab di RsaTestPage era "Chat" nel codice precedente.
      // Potresti volerla cambiare in "Test RSA" o qualcosa di simile.
      // Per ora mantengo le label come erano, ma la lunghezza e i children sono aggiornati.
      return DefaultTabController(length: 3, // Lunghezza rimane 3 se RsaTestPage sostituisce ChatPage
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                widget.wallet.name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.inversePrimary,
              centerTitle: true,
              actions: [
                // IconButton per RSA Test Page rimosso, ora è una tab
                IconButton( // Pulsante Elimina Esistente
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    final bool? confirmDelete = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        if (defaultTargetPlatform == TargetPlatform.iOS) {
                          return DeleteAppleWalletAlert(walletName: widget.wallet.name, dialogContext: dialogContext);
                        } else {
                          return DeleteWalletAlert(walletName: widget.wallet.name, dialogContext: dialogContext);
                        }
                      },
                    );
                    if (confirmDelete == true) {
                      try {
                        await widget._secureStorage.deleteSecureData(
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
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                automaticIndicatorColorAdjustment: true,
                tabs: [
                  // Se RsaTestPage sostituisce ChatPage, la label va aggiornata
                  Tab(text:"Test RSA", icon: Icon(Icons.science_outlined),), // Modificata label e icona
                  Tab(text: 'Lista Documenti', icon: Icon(Icons.contact_mail_outlined),),
                  Tab(text: 'Chiavi', icon: Icon(Icons.key),),
                ],
              )
            ),
            body: TabBarView(
              children: [
                // RsaTestPage ora riceve le chiavi
                RsaTestPage(
                  initialPrivateKeyString: privateKeyValue,
                  initialPublicKeyString: widget.wallet.publicKey,
                ),
                DocsPage(),
                KeysPage(
                  wallet: widget.wallet,
                  privateKeyValue: privateKeyValue,
                  secureStorage: _secureStorage,
                ),
              ],
            ),
          )
      );
    }
  }
}
