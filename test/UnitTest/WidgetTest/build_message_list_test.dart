import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_message_list.dart';
import 'package:key_wallet_app/services/i_chat_service.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/widgets/chatWidgets/chat_bubble.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// Importa il file che verrà generato
import 'build_message_list_test.mocks.dart';

// 1. ANNOTAZIONE: Specifichiamo quali classi devono essere mockate.
@GenerateMocks([IChatService, QuerySnapshot, QueryDocumentSnapshot, DocumentSnapshot])
void main() {
  // DICHIARAZIONE DELLE VARIABILI GLOBALI (late)
  late MockIChatService mockChatService;
  late Wallet senderWallet;
  late Wallet receiverWallet; // NECESSARIO PER BuildMessageList

  // FUNZIONE HELPER PER COSTRUIRE IL WIDGET
  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        // Usa la variabile 'mockChatService' qui
        Provider<IChatService>.value(value: mockChatService),
      ],
      child: MaterialApp(
        home: Scaffold(
          // Usa le variabili 'senderWallet' e 'receiverWallet' qui
          body: BuildMessageList(senderWallet: senderWallet, receiverWallet: receiverWallet),
        ),
      ),
    );
  }

  setUp(() {
    // INIZIALIZZAZIONE DELLE VARIABILI in setUp
    mockChatService = MockIChatService();

    // Wallet mittente finto
    senderWallet = Wallet(
      id: 'sender_doc_id',
      name: 'Sender',
      email: 'sender@example.com',
      color: Colors.blue,
      localKeyIdentifier: 'sender_local_key',
      userId: 'user-1',
      publicKey: 'pk-sender',
      balance: 0.0,
    );

    // Wallet destinatario finto
    receiverWallet = Wallet( // DEVE ESSERE DEFINITO
      id: 'receiver_doc_id',
      name: 'Receiver',
      email: 'receiver@example.com',
      color: Colors.red,
      localKeyIdentifier: 'receiver_local_key',
      userId: 'user-2',
      publicKey: 'pk-receiver',
      balance: 0.0,
    );
  });

  group('BuildMessageList Widget Tests', () {

    testWidgets('Mostra CircularProgressIndicator quando lo stream è in attesa', (WidgetTester tester) async {
      // Definizione esplicita del tipo di StreamController
      final controller = StreamController<QuerySnapshot<Map<String, dynamic>>>();

      // Mocking: usa il tipo generico esplicito per la risposta
      when(mockChatService.getMessages(any, any))
          .thenAnswer((_) => controller.stream); // Rimuovi il cast 'as Stream<...>' non necessario

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await controller.close();
    });

    testWidgets('Mostra i messaggi quando lo stream ha dati', (WidgetTester tester) async {
      // ARRANGE: Crea un MockQuerySnapshot e i MockDocumentSnapshot
      final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      // Dati per il messaggio INVIATO DALL'UTENTE CORRENTE (isCurrentUser = true)
      when(mockDoc1.data()).thenReturn({
        'senderWalletId': senderWallet.id, // Messaggio inviato da Sender (noi)
        'messageForSender': 'Encrypted_Hello',
        'messageForReceiver': 'Encrypted_Ciao',
        'timestamp': Timestamp.now(),
      });
      // Dati per il messaggio RICEVUTO (isCurrentUser = false)
      when(mockDoc2.data()).thenReturn({
        'senderWalletId': receiverWallet.id, // Messaggio inviato da Receiver
        'messageForSender': 'Encrypted_HowAreYou',
        'messageForReceiver': 'Encrypted_ComeStai',
        'timestamp': Timestamp.now(),
      });

      final mockDocs = [mockDoc1, mockDoc2];
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      when(mockSnapshot.docs).thenReturn(mockDocs);

      // MOCK NECESSARIO per il FutureBuilder interno (_buildMessageItem)
      when(mockChatService.translateMessage(argThat(contains('Hello')), any))
          .thenAnswer((_) => Future.value('Hello!')); // Messaggio di Sender (USA 'messageForSender')
      when(mockChatService.translateMessage(argThat(contains('ComeStai')), any))
          .thenAnswer((_) => Future.value('Come stai?')); // Messaggio di Receiver (USA 'messageForReceiver')


      // Mock dello Stream
      when(mockChatService.getMessages(any, any))
          .thenAnswer((_) => Stream.value(mockSnapshot));

      // ACT:
      await tester.pumpWidget(buildTestWidget());
      // pumpAndSettle attende sia lo StreamBuilder che i FutureBuilder interni.
      await tester.pumpAndSettle();

      // ASSERT:
      // Verifica che ci siano due bolle di chat e che contengano il testo decriptato.
      expect(find.byType(ChatBubble), findsNWidgets(2));
      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('Come stai?'), findsOneWidget);
    });

    // Il resto dei test (empty/error) è cruciale per il coverage

    testWidgets('Mostra un messaggio di errore se lo stream emette un errore', (WidgetTester tester) async {
      // Configura il mock per emettere un errore con un tipo esplicito
      when(mockChatService.getMessages(any, any))
          .thenAnswer((_) => Stream.error(Exception('Errore DB')).cast<QuerySnapshot<Map<String, dynamic>>>());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Se l'errore persiste, verifica l'esatto messaggio di errore prodotto dal tuo widget:
      expect(find.textContaining('Errore: Exception: Errore DB'), findsOneWidget);
    });

  });
}