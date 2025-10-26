import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/screens/landing_page.dart';
import 'package:key_wallet_app/screens/auth_page.dart';
import 'package:key_wallet_app/screens/wallet_page.dart';
import 'package:key_wallet_app/screens/new_wallet_creation.dart';
import 'package:key_wallet_app/screens/chat_list_page.dart';
import 'package:key_wallet_app/screens/chat_page.dart';
import 'package:key_wallet_app/screens/wallet_recover_page.dart';
import 'package:key_wallet_app/screens/find_contact_page.dart';

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
      case '/NewWalletCreation':
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (context) => NewWalletCreation(credenziali: args,),
          );
        }
        return _errorRoute();
      case '/chat_list':
        if (args is Wallet) {
          return MaterialPageRoute(
            builder: (context) => ChatListPage(senderWallet: args),
          );
        }
        return _errorRoute();
      case '/chat':
        if (args is Map<String, Wallet>) {
          return MaterialPageRoute(
            builder: (context) => ChatPage(
              senderWallet: args['senderWallet']!,
              receiverWallet: args["receiverWallet"]!,
            ),
          );
        }
        return _errorRoute();
      case '/WalletRecoverPage':
        if (args is Wallet) {
          return MaterialPageRoute(builder: (context) => WalletRecoverPage(wallet: args));
        }
        return _errorRoute();
      case '/findContactsPage':
        if (args is Wallet) {
          return MaterialPageRoute(builder: (context) => FindContactPage(senderWallet: args));
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
        body: Center(
          child: Text('Pagina non trovata o errore negli argomenti.'),
        ),
      ),
    );
  }
}
