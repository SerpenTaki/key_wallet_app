// test/UnitTest/WidgetTest/build_user_list_test.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_user_list.dart';
import 'package:key_wallet_app/services/i_chat_service.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/widgets/chatWidgets/user_tile.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// Importa il file che verrà generato
import 'build_user_list_test.mocks.dart';

// 1. ANNOTAZIONE: Specifichiamo quali classi devono essere mockate.
@GenerateMocks([IChatService])
void main() {
  late MockIChatService mockChatService;
  late Wallet senderWallet;

  setUp(() {
    mockChatService = MockIChatService();
    // Creiamo un wallet finto per i test.
    senderWallet = Wallet(
      id: 'sender_doc_id',
      name: 'Sender',
      email: 'sender@example.com',
      color: Colors.blue,
      localKeyIdentifier: 'sender_local_key', // ID stabile e univoco
      userId: 'user-1',
      publicKey: 'pk-sender',
      balance: 0.0,
    );
  });

  // Funzione helper per costruire l'albero di widget per i test.
  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        Provider<IChatService>.value(value: mockChatService),
      ],
      child: MaterialApp(
        home: Scaffold( // Aggiungiamo uno Scaffold per un contesto migliore
          body: BuildUserList(senderWallet: senderWallet),
        ),
      ),
    );
  }

  group('BuildUserList Widget Tests', () {

    testWidgets('Mostra CircularProgressIndicator quando lo stream è in attesa', (WidgetTester tester) async {
      final controller = StreamController<List<Map<String, dynamic>>>();

      // *** SINTASSI MOCKITO CORRETTA ***
      // Specifichiamo i parametri esatti che il widget userà.
      when(mockChatService.getConversationsStream(
        senderWallet.id,
        senderWallet.localKeyIdentifier,
      )).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(buildTestWidget());

      // VERIFICA: L'indicatore di caricamento è visibile mentre lo stream attende.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await controller.close();
    });

    testWidgets('Mostra messaggio "Nessuna conversazione" quando lo stream restituisce una lista vuota', (WidgetTester tester) async {
      // ARRANGE: Configura il mock per restituire uno stream con una lista vuota.
      when(mockChatService.getConversationsStream(
        senderWallet.id,
        senderWallet.localKeyIdentifier,
      )).thenAnswer((_)=> Stream.value([]));

      // ACT: Costruisci il widget.
      await tester.pumpWidget(buildTestWidget());
      // `pumpAndSettle` attende il completamento dello stream.
      await tester.pumpAndSettle();

      // ASSERT: Verifica che il messaggio corretto sia visibile.
      expect(find.text("Nessuna conversazione trovata. Iniziane una!"), findsOneWidget);
    });

    testWidgets('Mostra una lista di conversazioni (UserTile) quando lo stream ha dati', (WidgetTester tester) async {
      // ARRANGE: Prepara una lista di dati finti.
      final mockData = [
        {'id': '2', 'name': 'Alice', /* ... altri campi ... */ 'userId':'u2', 'email':'e2', 'publicKey':'pk2', 'localKeyIdentifier':'lk2', 'color':'Color(0xfff44336)', 'balance':0.0},
        {'id': '3', 'name': 'Bob', /* ... altri campi ... */ 'userId':'u3', 'email':'e3', 'publicKey':'pk3', 'localKeyIdentifier':'lk3', 'color':'Color(0x4caf50)', 'balance':0.0},
      ];

      // Configura il mock per restituire lo stream con i dati.
      when(mockChatService.getConversationsStream(
        senderWallet.id,
        senderWallet.localKeyIdentifier,
      )).thenAnswer((_)=>Stream.value(mockData));

      // ACT:
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // ASSERT:
      // Verifica che ci siano due widget UserTile.
      expect(find.byType(UserTile), findsNWidgets(2));
      // Verifica che i nomi dei contatti siano visibili.
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('Mostra un messaggio di errore se lo stream emette un errore', (WidgetTester tester) async {
      // ARRANGE: Configura il mock per emettere un errore.
      when(mockChatService.getConversationsStream(
        senderWallet.id,
        senderWallet.localKeyIdentifier,
      )).thenAnswer((_)=>Stream.error('Si è verificato un errore nel caricamento delle conversazioni.'));

      // ACT:
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // ASSERT: Verifica che il messaggio di errore sia visibile.
      expect(find.text('Si è verificato un errore nel caricamento delle conversazioni.'), findsOneWidget);
    });
  });
}
