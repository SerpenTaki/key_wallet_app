import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import per Firestore
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import per Secure Storage

class WalletProvider with ChangeNotifier {
  final List<Wallet> _wallets = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(); // Istanza di Secure Storage

  List<Wallet> get wallets => List.unmodifiable(_wallets);

  Future<void> fetchUserWallets(String userId) async {
    if (userId.isEmpty) {
      _wallets.clear();
      notifyListeners();
      print("WalletProvider: Utente sloggato o ID utente vuoto, lista wallet pulita.");
      return;
    }

    print("WalletProvider: Inizio recupero wallets per l'utente: $userId");
    try {
      QuerySnapshot<Map<String, dynamic>> walletSnapshot = await _firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true) // Opzionale: ordina per data di creazione
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
      
      notifyListeners();
      print("WalletProvider: Lista wallets aggiornata, ${wallets.length} wallets caricati in memoria.");
    } catch (e) {
      print("WalletProvider: Errore durante il recupero dei wallets da Firestore: $e");
      _wallets.clear();
      notifyListeners();
    }
  }
  
  Future<void> generateAndAddWallet(String userId, String walletName) async {
    if (userId.isEmpty) {
      print("WalletProvider: Impossibile generare wallet, userId vuoto.");
      // Potresti voler lanciare un errore o notificare l'utente in modo appropriato
      return;
    }
    if (walletName.isEmpty) {
      print("WalletProvider: Impossibile generare wallet, nome del wallet vuoto.");
      // Potresti voler lanciare un errore o notificare l'utente
      return;
    }

    print("WalletProvider: Inizio generazione nuovo wallet per l'utente $userId con nome: $walletName");
    try {
      // 1. Chiamare Wallet.generateNew()
      Wallet tempWallet = await Wallet.generateNew(walletName);

      // 2. Salvare la chiave privata in flutter_secure_storage.
      if (tempWallet.transientRawPrivateKey == null || tempWallet.transientRawPrivateKey!.isEmpty) {
        throw Exception("La chiave privata generata è nulla o vuota.");
      }
      await _secureStorage.write(
        key: tempWallet.localKeyIdentifier,
        value: tempWallet.transientRawPrivateKey,
      );
      print("WalletProvider: Chiave privata salvata in Secure Storage con identificatore: ${tempWallet.localKeyIdentifier}");

      // È buona pratica cancellare la chiave privata dalla memoria dell'oggetto
      // una volta salvata in modo sicuro.
      tempWallet.transientRawPrivateKey = null;

      // 3. Salvare i metadati del wallet (SENZA chiave privata) in Firestore.
      Map<String, dynamic> walletDataForFirestore = {
        'userId': userId,
        'name': tempWallet.name,
        'publicKey': tempWallet.publicKey,
        'localKeyIdentifier': tempWallet.localKeyIdentifier,
        'algorithm': 'RSA',
        'createdAt': FieldValue.serverTimestamp(), // Timestamp del server per la creazione
        'backedUp': false, // Inizialmente, il backup non è stato fatto
      };

      DocumentReference docRef = await _firestore.collection('wallets').add(walletDataForFirestore);
      print("WalletProvider: Metadati wallet salvati in Firestore con ID: ${docRef.id}");

      // 4. Creare un'istanza finale di Wallet con l'ID di Firestore e aggiungerla alla lista locale.
      // Usiamo i dati da tempWallet ma con l'ID corretto di Firestore.
      final Wallet finalWallet = Wallet(
        id: docRef.id, // ID del documento Firestore
        name: tempWallet.name,
        publicKey: tempWallet.publicKey,
        localKeyIdentifier: tempWallet.localKeyIdentifier,
        // transientRawPrivateKey è già null
      );

      _wallets.insert(0, finalWallet); // Aggiungi all'inizio della lista per vederlo subito
      notifyListeners();
      print("WalletProvider: Wallet aggiunto con successo. ID: ${finalWallet.id}, Nome: ${finalWallet.name}");

    } catch (e) {
      print("WalletProvider: Errore durante la generazione e salvataggio del wallet: $e");
      // Qui potresti voler informare l'utente dell'errore.
      // Ad esempio, impostando uno stato di errore nel provider e mostrandolo nella UI.
    }
  }

  // Metodo per eliminare un wallet (IMPLEMENTAZIONE FUTURA)
  Future<void> deleteWallet(BuildContext context, Wallet wallet) async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return CupertinoAlertDialog(
            title: const Text('Conferma Eliminazione'),
            content: Text('Sei sicuro di voler eliminare il wallet \"${wallet.name}\"?'),
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
            content: Text('Sei sicuro di voler eliminare il wallet \"${wallet.name}\"?'),
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
      try {
        // 1. Eliminare la chiave privata da flutter_secure_storage
        await _secureStorage.delete(key: wallet.localKeyIdentifier);
        print("WalletProvider: Chiave privata eliminata da Secure Storage per localKeyIdentifier: ${wallet.localKeyIdentifier}");

        // 2. Eliminare il documento del wallet da Firestore
        await _firestore.collection('wallets').doc(wallet.id).delete();
        print("WalletProvider: Documento wallet eliminato da Firestore: ${wallet.id}");

        // Rimuovi dalla lista locale e notifica
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
            content: Text('Errore durante la eliminazione del wallet: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
