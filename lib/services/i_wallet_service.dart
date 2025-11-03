import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';

abstract class IWalletService with ChangeNotifier {
  /// Indica se il servizio sta attualmente caricando i dati.
  bool get isLoading;

  /// Restituisce una lista non modificabile dei wallet correnti.
  List<Wallet> get wallets;

  /// Recupera i wallet associati a un dato ID utente.
  Future<void> fetchUserWallets(String userId);

  /// Controlla se un wallet con un dato hBytes esiste già per un utente.
  Future<bool> checkIfWalletExists(String hBytes, String userId);

  /// Genera un nuovo wallet, lo salva su storage sicuro e su Firestore.
  Future<void> generateAndAddWallet(String userId, String email, String walletName, Color selectedColor, String hBytes, String standard, String device);

  /// Cancella un wallet da Firestore e dalla lista locale.
  Future<void> deleteWalletDBandList(Wallet wallet);

  /// Aggiorna il saldo di un wallet specifico.
  Future<void> updateBalance(String walletId, double newBalance);
}
