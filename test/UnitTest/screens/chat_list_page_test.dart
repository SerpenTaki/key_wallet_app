import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/screens/chat_list_page.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/i_chat_service.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_user_list.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// Importa il file che verrà generato da build_runner
import 'chat_list_page_test.mocks.dart';

// 1. ANNOTAZIONE: Diciamo a Mockito di creare un mock per il nostro servizio di chat.
@GenerateMocks([IChatService])
void main() {
  late MockIChatService mockChatService;
  late Wallet testWallet;

  setUp(() {
    mockChatService = MockIChatService();
    testWallet = Wallet(
      id: '1',
      name: 'test',
      userId: 'test-id',
      email: 'test@test.it',
      publicKey: 'publickey-test',
      localKeyIdentifier: 'localKey',
      color: Colors.black,
      balance: 0.0,
    );

    // ARRANGE: Configura il mock per restituire uno stream vuoto di default.
    // Questo previene errori nei test che non si concentrano sulla lista.
    when(mockChatService.getConversationsStream(any, any))
        .thenAnswer((_) => Stream.value([]));
  });

  // Funzione helper per costruire l'albero di widget per i test.
  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        // Fornisce il nostro mock del servizio di chat
        Provider<IChatService>.value(value: mockChatService),
      ],
      child: MaterialApp(
        // Il RouteGenerator è necessario per testare la navigazione
        onGenerateRoute: (settings) {
          if (settings.name == "/findContactsPage") {
            // Per questo test, basta che la rotta esista.
            // Possiamo restituire un widget placeholder.
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text("Pagina Contatti")),
            );
          }
          return null;
        },
        home: child,
      ),
    );
  }

  group('ChatListPage Widget Tests', () {
    testWidgets('dovrebbe costruire correttamente i suoi componenti principali', (WidgetTester tester) async {
      // ACT: Costruisci la pagina
      await tester.pumpWidget(
        buildTestableWidget(ChatListPage(senderWallet: testWallet)),
      );

      // ASSERT: Usa finder robusti per verificare la presenza dei widget.

      // 1. Cerca il widget `BuildUserList` per TIPO, non per istanza.
      expect(find.byType(BuildUserList), findsOneWidget,
          reason: "ChatListPage deve contenere il widget BuildUserList");

      // 2. Cerca il FloatingActionButton per TIPO.
      expect(find.byType(FloatingActionButton), findsOneWidget,
          reason: "ChatListPage deve avere un FloatingActionButton");

      // 3. Cerca l'ICONA all'interno del FAB, che è un controllo più specifico e affidabile.
      expect(find.byIcon(Icons.person_add_alt_1_outlined), findsOneWidget,
          reason: "Il FAB deve contenere l'icona per aggiungere contatti");
    });

    testWidgets('dovrebbe navigare a FindContactPage quando il FAB viene premuto', (WidgetTester tester) async {
      // ACT: Costruisci la pagina
      await tester.pumpWidget(
        buildTestableWidget(ChatListPage(senderWallet: testWallet)),
      );

      // Simula il tocco sul FloatingActionButton
      await tester.tap(find.byType(FloatingActionButton));

      // `pumpAndSettle` attende il completamento di tutte le animazioni,
      // inclusa quella della transizione di pagina.
      await tester.pumpAndSettle();

      // ASSERT: Verifica di essere arrivato alla nuova pagina.
      // Cerchiamo un testo o un widget che sappiamo esistere solo su quella pagina.
      expect(find.text("Pagina Contatti"), findsOneWidget,
          reason: "La pressione del FAB deve navigare alla pagina di ricerca contatti");
    });
  });
}
