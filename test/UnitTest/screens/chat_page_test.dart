import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/screens/chat_page.dart';
import 'package:key_wallet_app/services/i_chat_service.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_message_list.dart';
import 'package:key_wallet_app/widgets/chatWidgets/build_user_input.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// Import del file generato da build_runner
import 'chat_page_test.mocks.dart';

// Genera mock per il servizio di chat
@GenerateMocks([IChatService])
void main() {
  late MockIChatService mockChatService;
  late Wallet senderWallet;
  late Wallet receiverWallet;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockChatService = MockIChatService();
    fakeFirestore = FakeFirebaseFirestore();

    senderWallet = Wallet(
      id: 'sender_id',
      name: 'Mio Wallet',
      email: 'sender@example.com',
      color: Colors.blue,
      localKeyIdentifier: 'sender_local_key',
      userId: 'user-1',
      publicKey: 'pk-sender',
      balance: 0.0,
    );

    receiverWallet = Wallet(
      id: 'receiver_id',
      name: 'Alice',
      email: 'alice@example.com',
      color: Colors.red,
      localKeyIdentifier: 'receiver_local_key',
      userId: 'user-2',
      publicKey: 'pk-receiver',
      balance: 0.0,
    );

    // stream reale da FakeFirestore, invece di null
    when(mockChatService.getMessages(any, any))
        .thenAnswer((_) => fakeFirestore.collection('messages').snapshots());
  });

  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        Provider<IChatService>.value(value: mockChatService),
      ],
      child: MaterialApp(
        home: ChatPage(
          senderWallet: senderWallet,
          receiverWallet: receiverWallet,
        ),
      ),
    );
  }

  group('ChatPage Widget Tests', () {
    testWidgets('La pagina si costruisce correttamente e mostra i componenti principali',
            (WidgetTester tester) async {
          await tester.pumpWidget(buildTestableWidget());

          expect(find.widgetWithText(AppBar, 'Alice'), findsOneWidget);
          expect(find.byType(BuildMessageList), findsOneWidget);
          expect(find.byType(BuildUserInput), findsOneWidget);
        });

    testWidgets('I widget figli ricevono i parametri corretti', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      final messageListWidget = tester.widget<BuildMessageList>(find.byType(BuildMessageList));
      expect(messageListWidget.senderWallet.id, senderWallet.id);
      expect(messageListWidget.receiverWallet.id, receiverWallet.id);

      final userInputWidget = tester.widget<BuildUserInput>(find.byType(BuildUserInput));
      expect(userInputWidget.senderWallet.id, senderWallet.id);
      expect(userInputWidget.receiverWallet.id, receiverWallet.id);

      verify(mockChatService.getMessages(senderWallet, receiverWallet)).called(1);
    });
  });
}
