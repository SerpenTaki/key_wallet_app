import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/widgets/wallets_dialogs/delete_wallet_alert.dart';

void main() {
  testWidgets('Mostra titolo, contenuto e pulsanti', (WidgetTester tester) async {
    // Arrange
    const walletName = 'Test Wallet';

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => DeleteWalletAlert(
            walletName: walletName,
            dialogContext: context,
          ),
        ),
      ),
    );

    // Assert: controlla che ci siano titolo, testo e pulsanti
    expect(find.text('Conferma Eliminazione'), findsOneWidget);
    expect(
      find.text(
        'Sei sicuro di voler eliminare il wallet "$walletName"? Questa azione è irreversibile e la chiave privata verrà rimossa da questo dispositivo.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key("Annulla Bottone")), findsOneWidget);
    expect(find.byKey(const Key("Elimina Bottone")), findsOneWidget);
  });

  testWidgets('Clic su Annulla chiude il dialog con false', (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => DeleteWalletAlert(
                  walletName: 'Test Wallet',
                  dialogContext: context,
                ),
              );
            },
            child: const Text('Apri Dialog'),
          ),
        ),
      ),
    );

    // Apri il dialog
    await tester.tap(find.text('Apri Dialog'));
    await tester.pumpAndSettle();

    // Premi "Annulla"
    await tester.tap(find.byKey(const Key("Annulla Bottone")));
    await tester.pumpAndSettle();

    // Il dialog dovrebbe restituire false
    expect(result, isFalse);
  });

  testWidgets('Clic su Elimina chiude il dialog con true', (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => DeleteWalletAlert(
                  walletName: 'Test Wallet',
                  dialogContext: context,
                ),
              );
            },
            child: const Text('Apri Dialog'),
          ),
        ),
      ),
    );

    // Apri il dialog
    await tester.tap(find.text('Apri Dialog'));
    await tester.pumpAndSettle();

    // Premi "Elimina"
    await tester.tap(find.byKey(const Key("Elimina Bottone")));
    await tester.pumpAndSettle();

    // Il dialog dovrebbe restituire true
    expect(result, isTrue);
  });
}
