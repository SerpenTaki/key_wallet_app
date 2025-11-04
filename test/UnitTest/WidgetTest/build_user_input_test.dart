// test/UnitTest/WidgetTest/build_user_input_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/i_chat_service.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_user_input.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// Importa il file che verrà generato da build_runner
import 'build_user_input_test.mocks.dart';

// 1. ANNOTAZIONE: Diciamo a Mockito di creare una classe finta basata sull'interfaccia IChatService.
@GenerateMocks([IChatService])
void main() {
  // Dichiarazione delle variabili di test
  late MockIChatService mockChatService;
  late Wallet senderWallet;
  late Wallet receiverWallet;

  // Il blocco `setUp` viene eseguito prima di ogni singolo test.
  setUp(() {
    // Crea istanze "pulite" dei mock e dei dati per ogni test, garantendo l'isolamento.
    mockChatService = MockIChatService();

    senderWallet = Wallet(
      id: 'sender_doc_id',
      name: 'Mio Wallet',
      email: 'sender@example.com',
      color: Colors.blue,
      localKeyIdentifier: 'sender_local_key',
      userId: 'user-1',
      publicKey: 'pk-sender',
      balance: 0.0,
    );

    receiverWallet = Wallet(
      id: 'receiver_doc_id',
      name: 'Contatto Amico',
      email: 'receiver@example.com',
      color: Colors.red,
      localKeyIdentifier: 'receiver_local_key',
      userId: 'user-2',
      publicKey: 'pk-receiver',
      balance: 0.0,
    );
  });

  // Funzione helper per costruire il widget sotto test.
  // Avvolge il widget con un MultiProvider per "iniettare" il nostro mock.
  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        // Usiamo .value per fornire l'istanza del mock che abbiamo già creato.
        Provider<IChatService>.value(value: mockChatService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: BuildUserInput(
            senderWallet: senderWallet,
            receiverWallet: receiverWallet,
          ),
        ),
      ),
    );
  }

  group('BuildUserInput Widget Tests', () {

    testWidgets('L\'interfaccia utente si costruisce correttamente', (WidgetTester tester) async {
      // ACT: Costruisci il widget.
      await tester.pumpWidget(buildTestWidget());

      // ASSERT: Verifica che i componenti principali siano presenti.
      expect(find.byType(TextField), findsOneWidget, reason: "Deve essere presente un campo di testo.");
      expect(find.byIcon(Icons.send), findsOneWidget, reason: "Deve essere presente un pulsante di invio.");
    });

    testWidgets('Chiama sendMessage quando si invia un messaggio valido', (WidgetTester tester) async {
      // ARRANGE: Configura il mock per non fare nulla quando `sendMessage` viene chiamato.
      // Usiamo `any` perché non stiamo testando la logica di `sendMessage` qui,
      // ma solo se viene chiamato.
      when(mockChatService.sendMessage(any, any, any)).thenAnswer((_) async {});

      // ACT: Costruisci il widget.
      await tester.pumpWidget(buildTestWidget());

      // 1. Simula l'inserimento del testo da parte dell'utente.
      await tester.enterText(find.byType(TextField), 'Ciao, mondo!');

      // 2. Simula il tocco sul pulsante di invio.
      await tester.tap(find.byIcon(Icons.send));

      // `pump()` è necessario per processare il frame dopo il tap.
      await tester.pump();

      // ASSERT: Verifica che il metodo `sendMessage` sul nostro mock sia stato chiamato
      // esattamente una volta, con gli argomenti corretti.
      verify(mockChatService.sendMessage(
        receiverWallet,
        senderWallet,
        'Ciao, mondo!',
      )).called(1);

      // Verifica anche che il campo di testo sia stato pulito dopo l'invio.
      expect(find.text('Ciao, mondo!'), findsNothing);
    });

    testWidgets('Non chiama sendMessage se il campo di testo è vuoto', (WidgetTester tester) async {
      // ARRANGE: Non è necessario configurare `when` perché non ci aspettiamo chiamate.

      // ACT: Costruisci il widget e tocca il pulsante di invio senza inserire testo.
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // ASSERT: Verifica che il metodo `sendMessage` non sia MAI stato chiamato.
      verifyNever(mockChatService.sendMessage(any, any, any));
    });

    testWidgets('Mostra una SnackBar se sendMessage lancia un\'eccezione', (WidgetTester tester) async {
      // ARRANGE: Configura il mock per lanciare un'eccezione quando `sendMessage` viene chiamato.
      // Questo simula un errore, come un messaggio troppo lungo.
      when(mockChatService.sendMessage(any, any, any))
          .thenThrow(Exception('Messaggio troppo lungo'));

      // ACT: Costruisci il widget.
      await tester.pumpWidget(buildTestWidget());

      // Inserisci testo e prova a inviare.
      await tester.enterText(find.byType(TextField), 'Questo è un messaggio molto, molto lungo...');
      await tester.tap(find.byIcon(Icons.send));

      // `pump()` è necessario per dare tempo alla UI di reagire all'errore e mostrare la SnackBar.
      await tester.pump();

      // ASSERT: Verifica che una SnackBar sia apparsa e che contenga il messaggio di errore.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Errore durante l\'invio del messaggio:'), findsOneWidget);
    });
  });
}
