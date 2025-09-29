import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_wallet_app/services/secureStorage.dart';
// SecureStorage non è più usato direttamente in questo provider per l'eliminazione
// import 'package:key_wallet_app/services/secureStorage.dart'; 

class WalletProvider with ChangeNotifier {
  final List<Wallet> _wallets = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false; 
  bool get isLoading => _isLoading; 

  List<Wallet> get wallets => List.unmodifiable(_wallets);

  Future<void> fetchUserWallets(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      QuerySnapshot<Map<String, dynamic>> walletSnapshot = await _firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      _wallets.clear(); 
      for (var doc in walletSnapshot.docs) {
        _wallets.add(Wallet.fromFirestore(doc));
      }
    } catch (e) {
      _wallets.clear(); 
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }
  
  Future<void> generateAndAddWallet(String userId, String walletName) async {
    if (userId.isEmpty) {
      return;
    }
    // È buona norma importare SecureStorage solo dove serve.
    // Se generateAndAddWallet è l'unico punto, va bene qui.
    // Altrimenti, potrebbe essere un membro della classe se usato più frequentemente.
    final secureStorage = SecureStorage(); // Istanza locale se usata solo qui
    try {
      Wallet tempWallet = await Wallet.generateNew(walletName);
      // Assicurati che SecureStorage sia importato se questo codice è attivo
      // import 'package:key_wallet_app/services/secureStorage.dart';
      await secureStorage.writeSecureData(tempWallet.localKeyIdentifier, tempWallet.transientRawPrivateKey!);
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
      final Wallet finalWallet = Wallet(
        id: docRef.id,
        name: tempWallet.name,
        publicKey: tempWallet.publicKey,
        localKeyIdentifier: tempWallet.localKeyIdentifier,
      ); 
      _wallets.insert(0, finalWallet);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }


  Future<void> deleteWallet(Wallet wallet) async {
    try {
      // 1. Elimina da Firestore
      await _firestore.collection('wallets').doc(wallet.id).delete();
      // 2. Rimuovi dalla lista locale e notifica
      _wallets.removeWhere((w) => w.id == wallet.id);
      notifyListeners();
    } catch (e) {
      throw e; 
    }
  }
}
