import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/secure_storage.dart';
import 'package:key_wallet_app/ErrorScreens/key_not_found.dart';
import 'package:key_wallet_app/screens/keys_page.dart';
import 'package:key_wallet_app/widgets/delete_apple_wallet_alert.dart';
import 'package:key_wallet_app/widgets/delete_wallet_alert.dart';
import 'package:key_wallet_app/screens/rsa_test_page.dart';
import 'package:key_wallet_app/screens/chat_list_page.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key, required this.wallet});

  final Wallet wallet;

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final SecureStorage _secureStorage = SecureStorage();

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
          return _buildWalletDetailsScaffold(context, mainSnapshot.data);
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
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
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
            errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,),
        ),
      ),
    );
  }

  Widget _buildWalletDetailsScaffold(BuildContext context, String? privateKeyValue,) {
    if (privateKeyValue == null || privateKeyValue.isEmpty) {
      return KeyNotFound();
    } else {
      return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
                title: Text(widget.wallet.name, style: const TextStyle(fontWeight: FontWeight.bold),),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.inversePrimary,
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.science_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RsaTestPage(initialPrivateKeyString: privateKeyValue, initialPublicKeyString: widget.wallet.publicKey,),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
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
                          await _secureStorage.deleteSecureData(widget.wallet.localKeyIdentifier,);
                          if (mounted) {
                             await Provider.of<WalletProvider>(context, listen: false).deleteWalletDBandList(widget.wallet);
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Wallet eliminato con successo!',),
                                backgroundColor: Colors.green,
                              ),
                            );
                            if (Navigator.canPop(context)) {Navigator.pop(context,);}
                          }
                        } catch (e) {
                           if(mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore durante l\'eliminazione: ${e.toString()}',), backgroundColor: Colors.red,),);
                           }
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
                    Tab(text: "Chat", icon: Icon(Icons.chat_outlined),),
                    Tab(text: 'Chiavi', icon: Icon(Icons.key),),
                  ],
                )
            ),
            body: TabBarView(
              children: [
                ChatListPage(
                  senderWallet: widget.wallet,
                ),
                KeysPage(wallet: widget.wallet, privateKeyValue: privateKeyValue, secureStorage: _secureStorage,),
              ],
            ),
          )
      );
    }
  }
}
