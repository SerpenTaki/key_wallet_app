import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/screens/landing_page.dart';
import 'package:key_wallet_app/services/i_auth.dart';
import 'package:key_wallet_app/services/i_wallet_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'landing_page_test.mocks.dart';


@GenerateNiceMocks([
  MockSpec<IAuth>(),
  MockSpec<IWalletService>(),
  MockSpec<firebase.User>(),
  MockSpec<NavigatorObserver>(),
])
void main() {
  late MockIAuth mockAuth;
  late MockIWalletService mockWalletService;
  late MockUser mockUser;
  late MockNavigatorObserver mockNavigatorObserver;
  late StreamController<firebase.User?> authStateController;

  // Usa l'istanza mockata generata da @GenerateNiceMocks.
  final tUser = MockUser();
  when(tUser.uid).thenReturn('test_uid');
  when(tUser.email).thenReturn('test@test.com');

  final tWallets = [
    Wallet(id: '1', name: 'Wallet 1', hBytes: 'HB1', standard: 'S1', userId: 'test_uid', email: 'test@test.com', localKeyIdentifier: 'lk1', publicKey: 'pk1', color: Colors.blue, balance: 1.0, device: 'Android'),
    Wallet(id: '2', name: 'Wallet 2', hBytes: 'HB2', standard: 'S2', userId: 'test_uid', email: 'test@test.com', localKeyIdentifier: 'lk2', publicKey: 'pk2', color: Colors.red, balance: 2.0, device: 'iOS'),
  ];

  Future<void> pumpLandingPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<IAuth>.value(value: mockAuth),
          // Usiamo il nostro mockWalletService che è un ChangeNotifier
          ChangeNotifierProvider<IWalletService>.value(value: mockWalletService),
        ],
        child: MaterialApp(
          home: const LandingPage(),
          routes: {
            '/NewWalletCreation': (_) => const Scaffold(body: Text('New Wallet Page')),
            '/WalletPage': (_) => const Scaffold(body: Text('Wallet Details Page')),
          },
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );
  }

  setUp(() {
    mockAuth = MockIAuth();
    mockWalletService = MockIWalletService();
    mockUser = tUser;
    mockNavigatorObserver = MockNavigatorObserver();
    authStateController = StreamController<firebase.User?>();

    // Impostazioni di default
    when(mockAuth.authStateChanges).thenAnswer((_) => authStateController.stream);
    when(mockWalletService.isLoading).thenReturn(false);
    when(mockWalletService.wallets).thenReturn([]);
    when(mockAuth.signOut()).thenAnswer((_) async {});
    when(mockAuth.currentUser).thenReturn(null);
    when(mockWalletService.fetchUserWallets(any)).thenAnswer((_) async {});
  });

  tearDown(() {
    authStateController.close();
  });

  group('Inizializzazione e Stato di Autenticazione', () {

    testWidgets('chiama fetchUserWallets con stringa vuota quando l\'utente fa logout', (tester) async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      await pumpLandingPage(tester);
      // Simula l'evento di logout
      authStateController.add(null);
      await tester.pump();
      verify(mockWalletService.fetchUserWallets("")).called(1);
    });
  });

  group('Visualizzazione della UI (_buildBody)', () {
    testWidgets('mostra CircularProgressIndicator quando isLoading è true', (tester) async {
      // ARRANGE
      when(mockWalletService.isLoading).thenReturn(true);

      // ACT
      await pumpLandingPage(tester);
      // 2. CORREZIONE: Notifichiamo esplicitamente i listener e ricostruiamo la UI
      mockWalletService.notifyListeners();
      await tester.pump();

      // ASSERT
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('mostra "Nessun wallet trovato" quando la lista è vuota', (tester) async {
      // ARRANGE
      when(mockWalletService.isLoading).thenReturn(false);
      when(mockWalletService.wallets).thenReturn([]);

      // ACT
      await pumpLandingPage(tester);
      mockWalletService.notifyListeners();
      await tester.pump();

      // ASSERT
      expect(find.textContaining('Nessun wallet trovato'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('mostra la lista di wallet quando ci sono dati', (tester) async {
      // ARRANGE
      when(mockWalletService.isLoading).thenReturn(false);
      when(mockWalletService.wallets).thenReturn(tWallets);

      // ACT
      await pumpLandingPage(tester);
      mockWalletService.notifyListeners();
      await tester.pump();

      // ASSERT
      expect(find.byType(Card), findsNWidgets(2));
      expect(find.text('Wallet 1'), findsOneWidget);
      expect(find.text('Wallet 2'), findsOneWidget);
    });
  });

  group('Interazioni dell\'Utente', () {
    testWidgets('chiama signOut quando il pulsante di logout viene premuto', (tester) async {
      await pumpLandingPage(tester);
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();
      verify(mockAuth.signOut()).called(1);
    });



    testWidgets('mostra SnackBar quando il FAB viene premuto (utente non loggato)', (tester) async {
      await pumpLandingPage(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(find.text("Devi essere loggato per creare un wallet."), findsOneWidget);
    });

  });
}
