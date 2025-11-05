import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/screens/find_contact_page.dart';
import 'package:key_wallet_app/services/i_chat_service.dart';
import 'package:key_wallet_app/services/i_contact_service.dart';
import 'package:key_wallet_app/services/i_nfc_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// Importa il file che verrà generato
import 'find_contact_page_test.mocks.dart';

// 1. ANNOTAZIONE: Mockiamo TUTTE le dipendenze esterne della pagina.
@GenerateMocks([IContactService, IChatService, INfcService])
void main() {
  // Dichiarazione dei mock e dei dati di test
  late MockIContactService mockContactService;
  late MockIChatService mockChatService;
  late MockINfcService mockNfcService;
  late Wallet senderWallet;

  setUp(() {
    // Crea istanze pulite per ogni test
    mockContactService = MockIContactService();
    mockChatService = MockIChatService();
    mockNfcService = MockINfcService();

    senderWallet = Wallet(
        id: 'sender_id',
        name: 'Mio Wallet',
        userId: 'user-1',
        email: 'sender@example.com',
        publicKey: 'pk-sender',
        localKeyIdentifier: 'sender_local_key',
        color: Colors.blue,
        balance: 0.0);

    // Configurazione di base per i mock
    // Simula che l'NFC sia sempre disponibile per non bloccare la UI
    when(mockNfcService.checkAvailability()).thenAnswer((_) async => true);
  });

  // Funzione helper per costruire il widget con i suoi provider
  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        Provider<IContactService>.value(value: mockContactService),
        Provider<IChatService>.value(value: mockChatService),
        Provider<INfcService>.value(value: mockNfcService),
      ],
      child: MaterialApp(
        // Il RouteGenerator è necessario per testare la navigazione alla chat
        onGenerateRoute: (settings) {
          if (settings.name == "/chat") {
            return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text("Pagina Chat")));
          }
          return null;
        },
        home: FindContactPage(senderWallet: senderWallet),
      ),
    );
  }

  group('FindContactPage Widget Tests', () {
    testWidgets('La pagina si costruisce correttamente e mostra lo stato iniziale', (WidgetTester tester) async {
        // ACT: Costruisci la pagina.
        await tester.pumpWidget(buildTestableWidget());

        // ASSERT: Verifica che i componenti iniziali siano presenti.
        expect(find.widgetWithText(AppBar, 'Cerca/Aggiungi Contatto'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byKey(const Key("searchButtonEmail")), findsOneWidget);
        expect(find.text("Nessun wallet trovato"), findsOneWidget, reason: "Allo stato iniziale, non ci devono essere risultati",);
      },
    );


    testWidgets('Mostra i risultati della ricerca dopo aver cercato via email',
            (WidgetTester tester) async {
          // ARRANGE
          const searchEmail = 'contact@example.com';
          final mockResults = [
            {
              'id': 'contact_id',
              'name': 'Contatto Trovato',
              'email': searchEmail,
              'userId': 'user-2',
              'publicKey': 'pk-contact',
              'localKeyIdentifier': 'contact_local_key',
              'color': Colors.red.toString(),
              'balance': 0.0,
            }
          ];

          // Configura il mock per restituire i risultati finti
          when(mockContactService.searchWalletsByEmail(searchEmail))
              .thenAnswer((_) async => mockResults);

          // ACT
          await tester.pumpWidget(buildTestableWidget());

          await tester.enterText(find.byType(TextFormField), searchEmail);
          await tester.pump();
          await tester.tap(find.byKey(Key("searchButtonEmail")));
          await tester.pumpAndSettle();

          // ASSERT
          expect(find.text("Nessun wallet trovato"), findsNothing, reason: "Il messaggio di 'nessun risultato' deve scomparire");
          expect(find.text('Contatto Trovato'), findsOneWidget, reason: "Il nome del contatto trovato deve essere visibile");
          expect(find.text(searchEmail), findsNWidgets(2));
    });

    testWidgets('Chiama createConversation e naviga quando si tocca un risultato',
            (WidgetTester tester) async {
          // ARRANGE
          const searchEmail = 'contact@example.com';
          final mockResults = [
            {
              'id': 'contact_id_1',
              'name': 'Contatto Cliccabile',
              'email': searchEmail,
              'userId': 'user-2',
              'publicKey': 'pk-contact-1',
              'localKeyIdentifier': 'contact_local_key_1',
              'color': Colors.red.toString(),
              'balance': 0.0,
            }
          ];
          when(mockContactService.searchWalletsByEmail(searchEmail))
              .thenAnswer((_) async => mockResults);
          // Configura il mock del chat service
          when(mockChatService.createConversationIfNotExists(any, any))
              .thenAnswer((_) async {});

          // ACT
          await tester.pumpWidget(buildTestableWidget());

          // Simula la ricerca per far apparire il risultato
          await tester.enterText(find.byType(TextFormField), searchEmail);
          await tester.pump();
          await tester.tap(find.byKey(const Key("searchButtonEmail")));
          await tester.pumpAndSettle();

          // Trova il risultato e toccalo
          await tester.tap(find.text('Contatto Cliccabile'));
          await tester.pumpAndSettle(); // Attendi la navigazione

          // ASSERT
          // 1. Verifica che `createConversationIfNotExists` sia stato chiamato.
          // Usiamo `captureAny` per "catturare" gli argomenti passati al metodo
          // e poterli ispezionare.
          final captured = verify(mockChatService.createConversationIfNotExists(
              captureAny, captureAny))
              .captured;
          expect(captured[0].id, senderWallet.id, reason: "Il primo argomento deve essere il senderWallet");
          expect(captured[1].name, 'Contatto Cliccabile', reason: "Il secondo argomento deve essere il receiverWallet cliccato");

          // 2. Verifica di essere arrivato alla pagina della chat
          expect(find.text("Pagina Chat"), findsOneWidget,
              reason: "Deve navigare alla pagina della chat dopo il tap");
        });
  });
}
