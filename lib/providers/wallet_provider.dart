import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_wallet_app/services/secureStorage.dart';

class WalletProvider with ChangeNotifier {
  final List<Wallet> _wallets = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false; // Nuovo stato di caricamento
  bool get isLoading => _isLoading; // Getter per lo stato di caricamento

  List<Wallet> get wallets => List.unmodifiable(_wallets);

  Future<void> fetchUserWallets(String userId) async {
    //print("WalletProvider: Inizio recupero wallets per l'utente: $userId");
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot<Map<String, dynamic>> walletSnapshot = await _firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _wallets.clear(); // Aggiornamento della precedente lista wallet nel caso vengano creati nuovi wallet
      
      //if (walletSnapshot.docs.isEmpty) {
      //  print("WalletProvider: Nessun wallet trovato in Firestore per l'utente $userId.");
      //} else {
      //  print("WalletProvider: Trovati ${walletSnapshot.docs.length} wallets in Firestore per l'utente $userId.");
      //}

      for (var doc in walletSnapshot.docs) {
        //print("WalletProvider: Aggiungo wallet da Firestore: ${doc.id}");
        _wallets.add(Wallet.fromFirestore(doc));
      }
      
    } catch (e) {
      //print("WalletProvider: Errore durante il recupero dei wallets da Firestore: $e");
      _wallets.clear(); // Pulizia della lista in caso di errore
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifica che il caricamento è finito e i dati (o l'errore) sono pronti
     // print("WalletProvider: Lista wallets aggiornata, ${wallets.length} wallets caricati in memoria. Caricamento terminato.");
    }
  }
  
  Future<void> generateAndAddWallet(String userId, String walletName) async {
    if (userId.isEmpty) {
      //print("WalletProvider: Impossibile generare wallet, userId vuoto.");
      return;
    }

   // print("WalletProvider: Inizio generazione nuovo wallet per l'utente $userId con nome: $walletName");
    try {
      Wallet tempWallet = await Wallet.generateNew(walletName);

      await SecureStorage().writeSecureData(tempWallet.localKeyIdentifier, tempWallet.transientRawPrivateKey!);


     // print("WalletProvider: Chiave privata salvata in Secure Storage con identificatore: ${tempWallet.localKeyIdentifier}");
      tempWallet.transientRawPrivateKey = null; // Eliminazione della chiave privata temporanea
      // Qui salviamo la chiave privata sul dispositivo

      //Dati da mandare a firebase
      Map<String, dynamic> walletDataForFirestore = {
        'userId': userId,
        'name': tempWallet.name,
        'publicKey': tempWallet.publicKey,
        'localKeyIdentifier': tempWallet.localKeyIdentifier,
        'algorithm': 'RSA',
        'createdAt': FieldValue.serverTimestamp(),
        'backedUp': false,
      };

      DocumentReference docRef = await _firestore.collection('wallets').add(walletDataForFirestore); // Aggiunta a Firestore
      //print("WalletProvider: Metadati wallet salvati in Firestore con ID: ${docRef.id}");

      final Wallet finalWallet = Wallet(
        id: docRef.id,
        name: tempWallet.name,
        publicKey: tempWallet.publicKey,
        localKeyIdentifier: tempWallet.localKeyIdentifier,
      ); //Creo un wallet per mandarlo alla lista da mostrare in _landingPage

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
        if (defaultTargetPlatform == TargetPlatform.iOS){
          return CupertinoAlertDialog(
            title: const Text('Conferma Eliminazione'),
            content: Text('Sei sicuro di voler eliminare il wallet "${wallet.name}"?'),
            actions: <Widget>[
              CupertinoDialogAction(
                child: const Text('Annulla'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Elimina'),
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
    ) ?? false; //Se nullo esco dal dialog torna false

    if (confirmDelete) {
      //print("WalletProvider: Inizio eliminazione wallet ID: ${wallet.id}");
      try {

        await SecureStorage().deleteSecureData(wallet.localKeyIdentifier);
        //print("WalletProvider: Chiave privata eliminata da Secure Storage per localKeyIdentifier: ${wallet.localKeyIdentifier}");

        await _firestore.collection('wallets').doc(wallet.id).delete();
        //print("WalletProvider: Documento wallet eliminato da Firestore: ${wallet.id}");

        _wallets.removeWhere((w) => w.id == wallet.id); // Rimuoviamo dalla lista locale mostrata in _landingPage
        notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar( // Avviso all'utente
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
