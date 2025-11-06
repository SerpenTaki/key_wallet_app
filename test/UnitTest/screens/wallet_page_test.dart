import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/screens/wallet_page.dart';
import 'package:key_wallet_app/services/i_chat_service.dart';
import 'package:key_wallet_app/services/i_secure_storage.dart';
import 'package:key_wallet_app/services/i_wallet_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'wallet_page_test.mocks.dart';

@GenerateMocks([ISecureStorage, IWalletService, IChatService])
void main() {
  late MockISecureStorage mockSecureStorage;
  late MockIWalletService mockWalletService;
  late MockIChatService mockChatService;

  final tWallet = Wallet(
    localKeyIdentifier: 'test_key',
    name: 'Test Wallet',
    publicKey: 'test_pk',
    id: '1518',
    userId: 'userId',
    email: 'test@test.it',
    color: Colors.black,
    balance: 0.0,
  );
  const tPrivateKey = 'super_secret_private_key';

  Future<void> pumpWalletPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ISecureStorage>.value(value: mockSecureStorage),
          ChangeNotifierProvider<IWalletService>.value(value: mockWalletService),
          Provider<IChatService>.value(value: mockChatService),
        ],
        child: MaterialApp(
          home: WalletPage(wallet: tWallet),
        ),
      ),
    );
  }

  setUp(() {
    mockSecureStorage = MockISecureStorage();
    mockWalletService = MockIWalletService();
    mockChatService = MockIChatService();
    when(mockWalletService.deleteWalletDBandList(any)).thenAnswer((_) async => {});
    when(mockChatService.getConversationsStream(any, any)).thenAnswer((_) => Stream.value(<Map<String, dynamic>>[]));
  });

  group('Cancellazione Wallet', () {
    setUp(() {
      when(mockSecureStorage.readSecureData(any)).thenAnswer((_) async => tPrivateKey);
      when(mockSecureStorage.deleteSecureData(any)).thenAnswer((_) async => {});
      when(mockWalletService.deleteWalletDBandList(any)).thenAnswer((_) async {});
    });

    testWidgets('mostra il dialogo di conferma e cancella il wallet se confermato', (tester) async {
      await pumpWalletPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      final dialogFinder = find.byType(AlertDialog);
      expect(dialogFinder, findsOneWidget);
      expect(find.descendant(of: dialogFinder, matching: find.textContaining(tWallet.name)), findsOneWidget);

      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      verify(mockSecureStorage.deleteSecureData(tWallet.localKeyIdentifier)).called(1);
      verify(mockWalletService.deleteWalletDBandList(tWallet)).called(1);

      expect(find.text('Wallet eliminato con successo!'), findsOneWidget);
    });

    testWidgets('mostra SnackBar di errore se la cancellazione fallisce', (tester) async {
      final exception = Exception('DB error');
      when(mockWalletService.deleteWalletDBandList(any)).thenThrow(exception);

      await pumpWalletPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Errore durante l\'eliminazione:'), findsOneWidget);
      expect(find.text('Wallet eliminato con successo!'), findsNothing);
    });
  });
}
