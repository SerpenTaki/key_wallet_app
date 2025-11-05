import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/screens/wallet_recover_page.dart';
import 'package:key_wallet_app/services/i_nfc_service.dart';
import 'package:key_wallet_app/services/i_recover_service.dart';
import 'package:key_wallet_app/services/i_secure_storage.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'wallet_recover_page_test.mocks.dart';

@GenerateMocks([INfcService, IRecoverService, ISecureStorage, NFCTag])
void main() {
  late MockINfcService mockNfcService;
  late MockIRecoverService mockRecoverService;
  late MockISecureStorage mockSecureStorage;
  late MockNFCTag mockNfcTag;
  late Wallet testWallet;

  setUp(() {
    mockNfcService = MockINfcService();
    mockRecoverService = MockIRecoverService();
    mockSecureStorage = MockISecureStorage();
    mockNfcTag = MockNFCTag();

    testWallet = Wallet(
      id: 'test_id',
      name: 'Wallet Test',
      userId: 'user_1',
      email: 'test@example.com',
      publicKey: 'test_pk',
      localKeyIdentifier: 'test_lk',
      color: Colors.blue,
      balance: 0.0,
      hBytes: 'test_hbytes',
      standard: 'test_standard',
    );

    // Configurazione base dei mock
    when(mockNfcService.checkAvailability()).thenAnswer((_) async => true);
    when(mockSecureStorage.writeSecureData(any, any)).thenAnswer((_) async {});
  });

  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        Provider<INfcService>.value(value: mockNfcService),
        Provider<IRecoverService>.value(value: mockRecoverService),
        Provider<ISecureStorage>.value(value: mockSecureStorage),
      ],
      child: MaterialApp(
        home: Builder(
          // 🔹 il Builder crea un nuovo BuildContext sotto ai Provider
          builder: (context) {
            return WalletRecoverPage(wallet: testWallet);
          },
        ),
      ),
    );
  }

  group('WalletRecoverPage Tests', () {
    testWidgets('La pagina si costruisce e il pulsante di recupero è disabilitato all\'inizio',
            (tester) async {
          await tester.pumpWidget(buildTestableWidget());
          await tester.pumpAndSettle();

          expect(find.widgetWithText(AppBar, "Recupera Wallet"), findsOneWidget);

          final recoverButtonFinder =
          find.widgetWithText(ElevatedButton, 'Recupera Wallet');
          final recoverButton =
          tester.widget<ElevatedButton>(recoverButtonFinder);

          expect(
            recoverButton.onPressed,
            isNull,
            reason: "Il pulsante deve essere disabilitato all'inizio.",
          );
        });

    testWidgets(
        'Il pulsante di recupero si abilita e funziona quando chiave e NFC sono corretti',
            (tester) async {
          // ARRANGE
          when(mockRecoverService.checkIfRight(any, any))
              .thenAnswer((_) async => true);
          when(mockNfcService.fetchNfcData()).thenAnswer((_) async {
            when(mockNfcTag.historicalBytes).thenReturn(testWallet.hBytes);
            when(mockNfcTag.standard).thenReturn(testWallet.standard!);
            return mockNfcTag;
          });

          await tester.pumpWidget(buildTestableWidget());
          await tester.pump();
          await tester.pumpAndSettle();

          // ACT 1: inserisci la chiave privata
          await tester.enterText(
              find.byType(TextField), 'chiave_privata_finta_corretta');

          // ACT 2: premi il bottone NFC
          final scanButtonFinder =
          find.widgetWithText(ElevatedButton, 'Scansiona documento');
          expect(scanButtonFinder, findsOneWidget,
              reason: 'Il bottone NFC deve essere visibile');
          await tester.tap(scanButtonFinder);
          await tester.pumpAndSettle();

          // ACT 3: aspetta la validazione
          await tester.pump(const Duration(milliseconds: 200));

          // ASSERT 1: il pulsante di recupero ora è abilitato
          final recoverButtonFinder =
          find.widgetWithText(ElevatedButton, 'Recupera Wallet');
          final recoverButton =
          tester.widget<ElevatedButton>(recoverButtonFinder);

          expect(recoverButton.onPressed, isNotNull,
              reason: 'Il pulsante deve essere abilitato dopo input validi');

          // ACT 4: premi il pulsante
          await tester.ensureVisible(recoverButtonFinder);
          await tester.tap(recoverButtonFinder);
          await tester.pumpAndSettle();

          // ASSERT 2: verifica scrittura su secure storage
          verify(mockSecureStorage.writeSecureData(
            testWallet.localKeyIdentifier,
            'chiave_privata_finta_corretta',
          )).called(1);
        });

    testWidgets(
        'Il pulsante di recupero rimane disabilitato se la chiave privata è sbagliata',
            (tester) async {
          // ARRANGE
          when(mockRecoverService.checkIfRight(any, any))
              .thenAnswer((_) async => false);
          when(mockNfcService.fetchNfcData()).thenAnswer((_) async {
            when(mockNfcTag.historicalBytes).thenReturn(testWallet.hBytes);
            when(mockNfcTag.standard).thenReturn(testWallet.standard!);
            return mockNfcTag;
          });

          await tester.pumpWidget(buildTestableWidget());
          await tester.pumpAndSettle();

          // ACT
          await tester.enterText(find.byType(TextField), 'chiave_sbagliata');
          await tester.tap(find.widgetWithText(ElevatedButton, 'Scansiona documento'));
          await tester.pumpAndSettle();

          // ASSERT
          final recoverButtonFinder =
          find.widgetWithText(ElevatedButton, 'Recupera Wallet');
          final recoverButton =
          tester.widget<ElevatedButton>(recoverButtonFinder);

          expect(
            recoverButton.onPressed,
            isNull,
            reason: "Il pulsante deve rimanere disabilitato se la chiave non è valida.",
          );
        });
  });
}
