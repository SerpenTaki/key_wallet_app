import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_wallet_app/services/secure_storage.dart';
import 'package:key_wallet_app/services/i_wallet_service.dart';

class WalletService with ChangeNotifier implements IWalletService{
  final List<Wallet> _wallets = [];
  final FirebaseFirestore _firestore;
  final SecureStorage _secureStorage;

  WalletService({FirebaseFirestore? firestore, SecureStorage? secureStorage})
  : _firestore = firestore ?? FirebaseFirestore.instance,
    _secureStorage = secureStorage ?? SecureStorage();


  bool _isLoading = false; 
  @override
  bool get isLoading => _isLoading;

  @override
  List<Wallet> get wallets => List.unmodifiable(_wallets);

  @override
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

  @override
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

  @override
  Future<void> generateAndAddWallet(String userId, String email, String walletName, Color selectedColor, String hBytes, String standard, String device) async {
    if (userId.isEmpty) {
      return;
    }
    try {
      Wallet tempWallet = await Wallet.generateNew(userId, email, walletName, selectedColor, hBytes, standard, device);
      await _secureStorage.writeSecureData(tempWallet.localKeyIdentifier, tempWallet.transientRawPrivateKey!);
      tempWallet.transientRawPrivateKey = null;

      Map<String, dynamic> walletDataForFirestore = {
        'userId': userId,
        'email': email,
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
        userId: userId,
        email: email,
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

  @override
  Future<void> deleteWalletDBandList(Wallet wallet) async {
    try {
      await _firestore.collection('wallets').doc(wallet.id).delete();
      _wallets.removeWhere((w) => w.id == wallet.id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<void> updateBalance(String walletId, double newBalance) async {
    try {
      await _firestore.collection('wallets').doc(walletId).update({
        'balance': newBalance,
      });

      final index = _wallets.indexWhere((wallet) => wallet.id == walletId);
      if (index != -1) { 
        final oldWallet = _wallets[index];
        _wallets[index] = Wallet(
          id: oldWallet.id,
          name: oldWallet.name,
          userId: oldWallet.userId,
          email: oldWallet.email,
          hBytes: oldWallet.hBytes,
          standard: oldWallet.standard,
          device: oldWallet.device,
          color: oldWallet.color,
          publicKey: oldWallet.publicKey,
          localKeyIdentifier: oldWallet.localKeyIdentifier,
          balance: newBalance,
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
}
