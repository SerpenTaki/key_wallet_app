import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/screens/key_not_found.dart';

void main() {
  late Wallet testWallet;

  setUp(() {
    testWallet = Wallet(
      id: 'wallet_test_id',
      name: 'Wallet di Prova',
      userId: 'user_test_id',
      email: 'test@example.com',
      publicKey: 'pk-test',
      localKeyIdentifier: 'lk-test',
      color: Colors.red,
      balance: 10.0,
    );
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == "/WalletRecoverPage") {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text("Pagina Recupero Wallet")),
          );
        }
        if (settings.name == '/') {
          return MaterialPageRoute(
              builder: (_) =>
              const Scaffold(body: Text("Pagina Precedente")));
        }
        return null;
      },
      home: child,
    );
  }

  group('KeyNotFound Widget Tests', () {
    testWidgets('La pagina si costruisce correttamente e mostra tutti i componenti UI', (WidgetTester tester) async {
          await tester.pumpWidget(buildTestableWidget(KeyNotFound(wallet: testWallet)));
          expect(find.byType(Image), findsOneWidget, reason: "Deve essere presente l'immagine del logo.");
          expect(find.text('Chiave privata non trovata!'), findsOneWidget, reason: "Deve essere presente il titolo dell'errore.");
          expect(find.text("Riprova da un altro dispositivo o recupera il tuo wallet"), findsOneWidget, reason: "Deve essere presente il sottotitolo esplicativo.");
          expect(find.widgetWithText(ElevatedButton, "Recupera Wallet"), findsOneWidget, reason: "Deve esserci il pulsante 'Recupera Wallet'.");
          expect(find.widgetWithText(ElevatedButton, "Torna indietro"), findsOneWidget, reason: "Deve esserci il pulsante 'Torna indietro'.");
    });

    testWidgets('Naviga alla pagina di recupero quando si preme "Recupera Wallet"', (WidgetTester tester) async {
          await tester.pumpWidget(buildTestableWidget(KeyNotFound(wallet: testWallet)));
          await tester.tap(find.widgetWithText(ElevatedButton, "Recupera Wallet"));
          await tester.pumpAndSettle();
          expect(find.text("Pagina Recupero Wallet"), findsOneWidget, reason: "La pressione del pulsante deve navigare a WalletRecoverPage.");
    });

    testWidgets('Esegue il pop della pagina quando si preme "Torna indietro"', (WidgetTester tester) async {
          await tester.pumpWidget(buildTestableWidget(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KeyNotFound(wallet: testWallet),
                    ),
                  ),
                  child: const Text('Vai a KeyNotFound'),
                ),
              ),
            ),
          ));
          await tester.tap(find.text('Vai a KeyNotFound'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ElevatedButton, "Torna indietro"));
          await tester.pumpAndSettle();
          expect(find.byType(KeyNotFound), findsNothing, reason: "La pagina KeyNotFound avrebbe dovuto essere chiusa.");
          expect(find.text('Vai a KeyNotFound'), findsOneWidget, reason: "Dovremmo essere tornati alla pagina iniziale.");
    });
  });
}

