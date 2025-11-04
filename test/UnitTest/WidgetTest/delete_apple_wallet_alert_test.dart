import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/widgets/WalletDialog/delete_apple_wallet_alert.dart';

void main() {
  testWidgets("Mostra titolo, contenuto e pulsanti", (WidgetTester tester,) async {
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

    expect(find.text('Conferma Eliminazione'), findsOneWidget);
    expect(
      find.text(
        'Sei sicuro di voler eliminare il wallet "$walletName"? Questa azione è irreversibile e la chiave privata verrà rimossa da questo dispositivo.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key("Annulla")), findsOneWidget);
    expect(find.byKey(const Key("Elimina")), findsOneWidget);
  });

  testWidgets("Clic su Annulla chiude il dialog con false", (WidgetTester tester,) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => DeleteAppleWalletAlert(
                  walletName: "Test Wallet",
                  dialogContext: context,
                ),
              );
            },
            child: const Text("Apri Dialog"),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Apri Dialog"));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("Annulla")));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets("Clic su Elimina chiude il dialog con true", (WidgetTester tester,) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => DeleteAppleWalletAlert(
                  walletName: "Test Wallet",
                  dialogContext: context,
                ),
              );
            },
            child: const Text("Apri Dialog"),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Apri Dialog"));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("Elimina")));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
