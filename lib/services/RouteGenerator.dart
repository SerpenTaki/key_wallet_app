import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart'; // Importa il modello Wallet
import 'package:key_wallet_app/screens/_landingPage.dart';
import 'package:key_wallet_app/screens/_authPage.dart';
import 'package:key_wallet_app/screens/_walletPage.dart'; // Assicurati che WalletPage sia importata

//Per mandare dati dinamici
class RouteGenerator {

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/LandingPage':
        return MaterialPageRoute(builder: (context) => LandingPage());
      case '/AuthPage':
        return MaterialPageRoute(builder: (context) => AuthPage());
      case '/WalletPage':
        if (args is Wallet) {
          return MaterialPageRoute(
            builder: (context) => WalletPage(wallet: args),
          );
        }
        return _errorRoute();
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text('Errore')),
        body: Center(child: Text('Pagina non trovata o errore negli argomenti.')),
      ),
    );
  }
}
