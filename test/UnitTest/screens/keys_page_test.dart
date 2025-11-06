import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/screens/keys_page.dart';
import 'package:key_wallet_app/services/i_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'keys_page_test.mocks.dart'; // Importa i mock generati

// Annotazione per generare il file .mocks.dart
@GenerateMocks([ISecureStorage])
void main() {
  // Dati di test
  final tWallet = Wallet(
    localKeyIdentifier: 'test_key_id',
    name: 'Test Wallet',
    publicKey: 'my_super_secret_public_key',
    email: '',
    color: Colors.black,
    balance: 0.0,
    userId: 'userId',
    id: 'id',
  );
  const String tPrivateKeyValue = 'my_super_secret_private_key';

  // Oggetto mock per SecureStorage
  late MockISecureStorage mockISecureStorage;

  // Funzione helper per creare il widget sotto test
  Future<void> pumpKeysPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: KeysPage(
          wallet: tWallet,
          privateKeyValue: tPrivateKeyValue,
          secureStorage: mockISecureStorage,
        ),
      ),
    );
  }

  setUp(() {
    // Inizializza il mock prima di ogni test
    mockISecureStorage = MockISecureStorage();
  });

  testWidgets('La pagina KeysPage mostra i widget iniziali correttamente',
          (WidgetTester tester) async {
        await pumpKeysPage(tester);

        // Verifica la presenza dei testi e dei pulsanti iniziali
        expect(find.text('Visualizza qui le tue chiavi'), findsOneWidget);
        expect(find.text('Chiave pubblica'), findsOneWidget);
        expect(find.text('Mostra chiave Pubblica'), findsOneWidget);
        expect(find.text('Chiave privata'), findsOneWidget);
        expect(find.text('Mostra Chiave Privata'), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);

        // Inizialmente le chiavi non devono essere visibili
        expect(find.text(tWallet.publicKey), findsNothing);
        expect(find.text(tPrivateKeyValue), findsNothing);
      });

  testWidgets(
      'Mostra e nasconde la chiave pubblica quando il pulsante viene premuto',
          (WidgetTester tester) async {
        await pumpKeysPage(tester);

        // 1. Mostra la chiave pubblica
        await tester.tap(find.text('Mostra chiave Pubblica'));
        await tester.pump();

        // Verifica che la chiave pubblica sia visibile e il testo del pulsante sia cambiato
        expect(find.text(tWallet.publicKey), findsOneWidget);
        expect(find.text('Nascondi chiave Pubblica'), findsOneWidget);

        // 2. Nasconde la chiave pubblica
        await tester.tap(find.text('Nascondi chiave Pubblica'));
        await tester.pump();

        // Verifica che la chiave pubblica sia di nuovo nascosta
        expect(find.text(tWallet.publicKey), findsNothing);
        expect(find.text('Mostra chiave Pubblica'), findsOneWidget);
      });

  testWidgets(
      'Mostra e nasconde la chiave privata quando il pulsante viene premuto',
          (WidgetTester tester) async {
        await pumpKeysPage(tester);

        // 1. Mostra la chiave privata
        await tester.tap(find.text('Mostra Chiave Privata'));
        await tester.pump();

        // Verifica che la chiave privata sia visibile e il testo del pulsante sia cambiato
        expect(find.text(tPrivateKeyValue), findsOneWidget);
        expect(find.text('Nascondi Chiave Privata'), findsOneWidget);

        // 2. Nasconde la chiave privata
        await tester.tap(find.text('Nascondi Chiave Privata'));
        await tester.pump();

        // Verifica che la chiave privata sia di nuovo nascosta
        expect(find.text(tPrivateKeyValue), findsNothing);
        expect(find.text('Mostra Chiave Privata'), findsOneWidget);
      });

  testWidgets(
      'Nasconde la chiave privata quando quella pubblica viene mostrata e viceversa',
          (WidgetTester tester) async {
        await pumpKeysPage(tester);

        // Mostra la chiave privata
        await tester.tap(find.text('Mostra Chiave Privata'));
        await tester.pump();
        expect(find.text(tPrivateKeyValue), findsOneWidget);

        // Mostra la chiave pubblica
        await tester.tap(find.text('Mostra chiave Pubblica'));
        await tester.pump();

        // Verifica che la chiave privata sia nascosta e quella pubblica visibile
        expect(find.text(tPrivateKeyValue), findsNothing);
        expect(find.text(tWallet.publicKey), findsOneWidget);

        // Mostra di nuovo la chiave privata
        await tester.tap(find.text('Mostra Chiave Privata'));
        await tester.pump();

        // Verifica che la chiave pubblica sia nascosta e quella privata visibile
        expect(find.text(tWallet.publicKey), findsNothing);
        expect(find.text(tPrivateKeyValue), findsOneWidget);
      });

  group('Cancellazione chiave privata', () {

    testWidgets('Mostra SnackBar di errore se la cancellazione fallisce',
            (WidgetTester tester) async {
          final exceptionMessage = 'Errore forzato';
          // Mock della funzione di cancellazione per lanciare un'eccezione
          when(mockISecureStorage.deleteSecureData(tWallet.localKeyIdentifier))
              .thenThrow(Exception(exceptionMessage));

          await pumpKeysPage(tester);

          // Premi l'icona di cancellazione
          await tester.tap(find.byIcon(Icons.delete));
          await tester.pumpAndSettle();

          // Conferma l'eliminazione nel dialogo
          await tester.tap(find.text('Elimina'));
          await tester.pumpAndSettle();

          // Verifica che il metodo sia stato chiamato
          verify(mockISecureStorage.deleteSecureData(tWallet.localKeyIdentifier))
              .called(1);

          // Verifica la comparsa dello SnackBar di errore
          expect(
              find.text(
                  "Errore durante l'eliminazione della chiave: Exception: $exceptionMessage"),
              findsOneWidget);
        });

    testWidgets('Non cancella la chiave se il dialogo viene annullato',
            (WidgetTester tester) async {
          await pumpKeysPage(tester);

          // Premi l'icona di cancellazione
          await tester.tap(find.byIcon(Icons.delete));
          await tester.pumpAndSettle();

          // Verifica che il dialogo sia visibile
          expect(find.byType(AlertDialog), findsOneWidget);

          // Premi il pulsante di annullamento
          await tester.tap(find.text('Annulla'));
          await tester.pumpAndSettle();

          // Verifica che il metodo di cancellazione non sia mai stato chiamato
          verifyNever(
              mockISecureStorage.deleteSecureData(any));

          // Verifica che il dialogo sia scomparso
          expect(find.byType(AlertDialog), findsNothing);
        });
  });
}

