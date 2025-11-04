import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/widgets/WalletDialog/delete_apple_wallet_alert.dart';

void main() {
  testWidgets("Mostra titolo, contenuto e pulsanti", (
    WidgetTester tester,
  ) async {
    const walletName = "Test Wallet";

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => DeleteAppleWalletAlert(
            walletName: walletName,
            dialogContext: context,
          ),
        ),
      ),
    );
    
    //expect(find.text('Conferma Eliminazione'), matcher)
    
  });
}
