import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_wallet_app/services/secure_storage.dart';

class WalletProvider with ChangeNotifier {
  final List<Wallet> _wallets = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false; 
  bool get isLoading => _isLoading; 

  List<Wallet> get wallets => List.unmodifiable(_wallets);

  //La funzione cerca nel database firestore i wallet dell'utente tramite userId che
  //deve essere passato come argomento
  Future<void> fetchUserWallets(String userId) async {
    _isLoading = true; // Operazione molto lunga meglio non annoiare l'utente
    notifyListeners();
    try {
      QuerySnapshot<Map<String, dynamic>> walletSnapshot = await _firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get(); //Qui viene chiamata la query per ottenere i documenti
      _wallets.clear();
      for (var doc in walletSnapshot.docs) { //Il metodo docs restituisce una lista in questo caso di walletSnapshot
        _wallets.add(Wallet.fromFirestore(doc));
      }
    } catch (e) {
      _wallets.clear();
    } finally {
      _isLoading = false;
      notifyListeners(); //Provider aggiorna i widget interessati
    }
  }

  //Funzione per aggiungere un nuovo wallet alla lista locale e alla lista di firestore, di conseguenza generando
  //le 2 chiavi da salvare
  Future<void> generateAndAddWallet(String userId, String walletName) async {
    if (userId.isEmpty) {
      return;
    }
    final secureStorage = SecureStorage(); // Istanza di Secure Storage per gestire la chiave privata da salvare sul dispositivo
    try {
      Wallet tempWallet = await Wallet.generateNew(walletName); //creo un wallet temporaneo tramite la classe Wallet
      await secureStorage.writeSecureData(tempWallet.localKeyIdentifier, tempWallet.transientRawPrivateKey!); //con secure storage salvo la chiave privata
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

      DocumentReference docRef = await _firestore.collection('wallets').add(walletDataForFirestore); //aggiungo il wallet alla lista di firestore
      final Wallet finalWallet = Wallet(
        id: docRef.id,
        name: tempWallet.name,
        publicKey: tempWallet.publicKey,
        localKeyIdentifier: tempWallet.localKeyIdentifier,
      ); 
      _wallets.insert(0, finalWallet);
      notifyListeners(); //aggiungo il wallet finale alla lista locale
    } catch (e) {
      throw e;
    }
  }

  //Elimina solo dalla lista aggiornando il provider e dal Database, l'eliminazione da secure storage è gestita in wallet_page.dart
  Future<void> deleteWalletDBandList(Wallet wallet) async {
    try {
      await _firestore.collection('wallets').doc(wallet.id).delete();
      _wallets.removeWhere((w) => w.id == wallet.id);
      notifyListeners();
    } catch (e) {
      throw e; 
    }
  }
}
