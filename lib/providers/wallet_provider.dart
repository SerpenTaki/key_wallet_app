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

  Future<bool> checkIfWalletExists(String hBytes, String userId) async {
    if (hBytes.isEmpty) return false;
    try {
      final querySnapshot = await _firestore
          .collection('wallets')
          .where('hBytes', isEqualTo: hBytes)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return true;
    }
  }

  Future<void> generateAndAddWallet(String userId, String walletName, Color selectedColor, String hBytes, String standard, String device) async {
    if (userId.isEmpty) {
      return;
    }
    final secureStorage = SecureStorage();
    try {
      Wallet tempWallet = await Wallet.generateNew(walletName, selectedColor, hBytes, standard, device);
      await secureStorage.writeSecureData(tempWallet.localKeyIdentifier, tempWallet.transientRawPrivateKey!); 
      tempWallet.transientRawPrivateKey = null;

      Map<String, dynamic> walletDataForFirestore = {
        'userId': userId,
        'name': tempWallet.name,
        'hBytes': hBytes,
        'standard': standard,
        'device': device,
        'color': selectedColor.toString(),
        'publicKey': tempWallet.publicKey,
        'localKeyIdentifier': tempWallet.localKeyIdentifier,
        'algorithm': 'RSA',
        'createdAt': FieldValue.serverTimestamp(),
        'backedUp': false,
        'balance' : tempWallet.balance,
      };

      DocumentReference docRef = await _firestore.collection('wallets').add(walletDataForFirestore);
      final Wallet finalWallet = Wallet(
        id: docRef.id,
        name: tempWallet.name,
        hBytes: hBytes,
        standard: standard,
        device: device,
        color: selectedColor,
        publicKey: tempWallet.publicKey,
        localKeyIdentifier: tempWallet.localKeyIdentifier,
        balance: tempWallet.balance,
      ); 
      _wallets.insert(0, finalWallet);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteWalletDBandList(Wallet wallet) async {
    try {
      await _firestore.collection('wallets').doc(wallet.id).delete();
      _wallets.removeWhere((w) => w.id == wallet.id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateBalance(String walletId, double newBalance) async {
    try {
      await _firestore.collection('wallets').doc(walletId).update({
        'balance': newBalance,
      });

      final index = _wallets.indexWhere((wallet) => wallet.id == walletId);
      if (index != -1) { // indexWhere restituisce -1 se non ci sono portafogli che soddisfano wallet.id == walletId
        final oldWallet = _wallets[index];
        _wallets[index] = Wallet( // Costruisco un nuovo wallet per il principio di immutabilità di flutter
          id: oldWallet.id,
          name: oldWallet.name,
          hBytes: oldWallet.hBytes,
          standard: oldWallet.standard,
          device: oldWallet.device,
          color: oldWallet.color,
          publicKey: oldWallet.publicKey,
          localKeyIdentifier: oldWallet.localKeyIdentifier,
          balance: newBalance,
        );
        notifyListeners(); // Notifica Flutter che i dati sono stati aggiornati
      }
    } catch (e) {
      rethrow;
    }
  }
}
