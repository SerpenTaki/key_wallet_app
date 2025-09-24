import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import per Firestore
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import per Secure Storage

class WalletProvider with ChangeNotifier {
  final List<Wallet> _wallets = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false; // Nuovo stato di caricamento
  bool get isLoading => _isLoading; // Getter per lo stato di caricamento

  List<Wallet> get wallets => List.unmodifiable(_wallets);

  Future<void> fetchUserWallets(String userId) async {
    if (userId.isEmpty) {
      _wallets.clear();
      _isLoading = false; // Assicurati che isLoading sia false anche qui
      notifyListeners();
      print("WalletProvider: Utente sloggato o ID utente vuoto, lista wallet pulita.");
      return;
    }

    print("WalletProvider: Inizio recupero wallets per l'utente: $userId");
    _isLoading = true;
    notifyListeners(); // Notifica che il caricamento è iniziato

    try {
      QuerySnapshot<Map<String, dynamic>> walletSnapshot = await _firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _wallets.clear();
      
      if (walletSnapshot.docs.isEmpty) {
        print("WalletProvider: Nessun wallet trovato in Firestore per l'utente $userId.");
      } else {
        print("WalletProvider: Trovati ${walletSnapshot.docs.length} wallets in Firestore per l'utente $userId.");
      }

      for (var doc in walletSnapshot.docs) {
        print("WalletProvider: Aggiungo wallet da Firestore: ${doc.id}");
        _wallets.add(Wallet.fromFirestore(doc));
      }
      
    } catch (e) {
      print("WalletProvider: Errore durante il recupero dei wallets da Firestore: $e");
      _wallets.clear(); // Pulisci in caso di errore
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifica che il caricamento è finito e i dati (o l'errore) sono pronti
      print("WalletProvider: Lista wallets aggiornata, ${wallets.length} wallets caricati in memoria. Caricamento terminato.");
    }
  }
  
  Future<void> generateAndAddWallet(String userId, String walletName) async {
    if (userId.isEmpty) {
      print("WalletProvider: Impossibile generare wallet, userId vuoto.");
      return;
    }
    if (walletName.isEmpty) {
      print("WalletProvider: Impossibile generare wallet, nome del wallet vuoto.");
      return;
    }
    // Non modifichiamo isLoading qui, perché fetchUserWallets dovrebbe essere richiamato se necessario
    // oppure la UI si aggiornerà aggiungendo direttamente il wallet.
    // Se la creazione fosse molto lunga, potremmo aggiungere uno stato di "isCreating".

    print("WalletProvider: Inizio generazione nuovo wallet per l'utente $userId con nome: $walletName");
    try {
      Wallet tempWallet = await Wallet.generateNew(walletName);

      if (tempWallet.transientRawPrivateKey == null || tempWallet.transientRawPrivateKey!.isEmpty) {
        throw Exception("La chiave privata generata è nulla o vuota.");
      }
      await _secureStorage.write(
        key: tempWallet.localKeyIdentifier,
        value: tempWallet.transientRawPrivateKey,
      );
      print("WalletProvider: Chiave privata salvata in Secure Storage con identificatore: ${tempWallet.localKeyIdentifier}");
      tempWallet.transientRawPrivateKey = null;

      Map<String, dynamic> walletDataForFirestore = {
        'userId': userId,
        'name': tempWallet.name,
        'publicKey': tempWallet.publicKey,
        'localKeyIdentifier': tempWallet.localKeyIdentifier,
        'algorithm': 'RSA',
        'createdAt': FieldValue.serverTimestamp(),
        'backedUp': false,
      };

      DocumentReference docRef = await _firestore.collection('wallets').add(walletDataForFirestore);
      print("WalletProvider: Metadati wallet salvati in Firestore con ID: ${docRef.id}");

      final Wallet finalWallet = Wallet(
        id: docRef.id,
        name: tempWallet.name,
        publicKey: tempWallet.publicKey,
        localKeyIdentifier: tempWallet.localKeyIdentifier,
      );

      _wallets.insert(0, finalWallet);
      notifyListeners();
      print("WalletProvider: Wallet aggiunto con successo. ID: ${finalWallet.id}, Nome: ${finalWallet.name}");

    } catch (e) {
      print("WalletProvider: Errore durante la generazione e salvataggio del wallet: $e");
    }
  }

  Future<void> deleteWallet(BuildContext context, Wallet wallet) async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // ... (codice del dialogo invariato) ...
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return CupertinoAlertDialog(
            title: const Text('Conferma Eliminazione'),
            content: Text('Sei sicuro di voler eliminare il wallet "${wallet.name}"?'),
            actions: <Widget>[
              CupertinoDialogAction(
                child: const Text('Annulla'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              CupertinoDialogAction(
                child: const Text('Elimina'),
                isDestructiveAction: true,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: const Text('Conferma Eliminazione'),
            content: Text('Sei sicuro di voler eliminare il wallet "${wallet.name}"?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Annulla'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                child: const Text('Elimina', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          );
        }
      },
    ) ?? false;

    if (confirmDelete) {
      print("WalletProvider: Inizio eliminazione wallet ID: ${wallet.id}");
      // Potremmo aggiungere uno stato _isDeleting se l'operazione fosse lunga
      try {
        await _secureStorage.delete(key: wallet.localKeyIdentifier);
        print("WalletProvider: Chiave privata eliminata da Secure Storage per localKeyIdentifier: ${wallet.localKeyIdentifier}");

        await _firestore.collection('wallets').doc(wallet.id).delete();
        print("WalletProvider: Documento wallet eliminato da Firestore: ${wallet.id}");

        _wallets.removeWhere((w) => w.id == wallet.id);
        notifyListeners();

        print("WalletProvider: Wallet ID: ${wallet.id} eliminato con successo.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet: "${wallet.name}" eliminato con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print("WalletProvider: Errore durante l'eliminazione del wallet: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'eliminazione del wallet: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
