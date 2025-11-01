// test/WidgetTest/landing_page_test.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';
import 'package:key_wallet_app/screens/landing_page.dart';
import 'package:key_wallet_app/services/i_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// Importa il file che verrà generato da build_runner
import 'landing_page_test.mocks.dart';

// ANNOTAZIONE: Specifica quali classi devono essere mockate.
@GenerateMocks([IAuth, WalletProvider, User])
void main() {
  // Dichiarazione dei mock
  late MockIAuth mockAuth;
  late MockWalletProvider mockWalletProvider;
  late MockUser mockUser;

  // Il setUp viene eseguito prima di ogni test per avere mock "puliti".
  setUp(() {
    mockAuth = MockIAuth();
    mockWalletProvider = MockWalletProvider();
    mockUser = MockUser();
  });

  // Funzione helper per costruire l'albero di widget per i test.
  // Inietta i nostri provider mockati.
  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletProvider>.value(value: mockWalletProvider),
        Provider<IAuth>.value(value: mockAuth),
      ],
      child: const MaterialApp(
        home: LandingPage(),
      ),
    );
  }

  testWidgets('Mostra CircularProgressIndicator quando isLoading è true', (tester) async {
    // ARRANGE: Configura il comportamento dei mock per questo scenario.
    // 1. Simula uno stream di autenticazione con un utente loggato.
    when(mockAuth.authStateChanges).thenAnswer((_) => Stream.value(mockUser));
    // 2. Simula lo stato di caricamento del provider dei wallet.
    when(mockWalletProvider.isLoading).thenReturn(true);
    when(mockWalletProvider.wallets).thenReturn([]); // Lista vuota durante il caricamento

    // ACT: Costruisci il widget.
    await tester.pumpWidget(buildTestWidget());
    // Esegui un pump per processare il frame dopo l'emissione dello stream.
    await tester.pump();

    // ASSERT: Verifica che la UI mostri l'indicatore di caricamento.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Verifica anche che `fetchUserWallets` sia stato chiamato dal `initState`
    verify(mockWalletProvider.fetchUserWallets(any)).called(1);
  });

  testWidgets('Mostra messaggio "Nessun wallet" quando la lista è vuota', (tester) async {
    // ARRANGE:
    // 1. Simula utente loggato.
    when(mockAuth.authStateChanges).thenAnswer((_) => Stream.value(mockUser));
    // 2. Simula caricamento completato (isLoading = false) e lista vuota.
    when(mockWalletProvider.isLoading).thenReturn(false);
    when(mockWalletProvider.wallets).thenReturn([]);

    // ACT:
    await tester.pumpWidget(buildTestWidget());
    // pumpAndSettle attende che tutte le animazioni e i frame finiscano.
    await tester.pumpAndSettle();

    // ASSERT:
    expect(find.textContaining('Nessun wallet trovato'), findsOneWidget);
  });
}
