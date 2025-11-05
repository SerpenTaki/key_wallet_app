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

// 1. ANNOTAZIONE: Mockiamo tutte le dipendenze della pagina.
@GenerateMocks([INfcService, IRecoverService, ISecureStorage, NFCTag])
void main() {
  late MockINfcService mockNfcService;
  late MockIRecoverService mockRecoverService;
  late MockISecureStorage mockSecureStorage;
  late Wallet testWallet;

  setUp(() {
    mockNfcService = MockINfcService();
    mockRecoverService = MockIRecoverService();
    mockSecureStorage = MockISecureStorage();

    testWallet = Wallet(
        id: 'test_id', name: 'Wallet Test', userId: 'user_1',
        email: 'test@example.com', publicKey: 'test_pk',
        localKeyIdentifier: 'test_lk', color: Colors.blue, balance: 0.0,
        hBytes: 'test_hbytes', standard: 'test_standard');

    // Configurazione di base dei mock
    when(mockNfcService.checkAvailability()).thenAnswer((_) async => true);
    when(mockSecureStorage.writeSecureData(any, any)).thenAnswer((_) async {});
  });

  // Funzione helper per costruire il widget di test
  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        Provider<INfcService>.value(value: mockNfcService),
        Provider<IRecoverService>.value(value: mockRecoverService),
        Provider<ISecureStorage>.value(value: mockSecureStorage),
      ],
      child: MaterialApp(
        home: WalletRecoverPage(wallet: testWallet),
      ),
    );
  }

  group('WalletRecoverPage Tests', () {
    testWidgets('La pagina si costruisce e il pulsante di recupero disabilitato', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.widgetWithText(AppBar, "Recupera Wallet"), findsOneWidget);
      final recoverButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Recupera Wallet'));
      expect(recoverButton.onPressed, isNull, reason: "Il pulsante deve essere disabilitato all'inizio.");
    });

  });
}
