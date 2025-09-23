import 'package:flutter/material.dart';
import 'package:key_wallet_app/screens/_landingPage.dart';
import 'package:key_wallet_app/screens/AuthPage.dart';

//Per mandare dati dinamici
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/LandingPage':
        return MaterialPageRoute(builder: (context) => LandingPage());
      case '/AuthPage':
        return MaterialPageRoute(builder: (context) => AuthPage());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(body: Center(child: Text('Error'))),
    );
  }
}
