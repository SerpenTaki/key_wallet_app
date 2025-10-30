import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/screens/auth_page.dart';
import 'package:key_wallet_app/screens/chat_list_page.dart';
import 'package:key_wallet_app/screens/chat_page.dart';
import 'package:key_wallet_app/screens/find_contact_page.dart';
import 'package:key_wallet_app/screens/landing_page.dart';
import 'package:key_wallet_app/screens/new_wallet_creation.dart';
import 'package:key_wallet_app/screens/wallet_page.dart';
import 'package:key_wallet_app/screens/wallet_recover_page.dart';
import 'package:key_wallet_app/services/route_generator.dart';
import "package:mockito/mockito.dart";

Wallet createMockWallet(String id) {
  return Wallet(
    id: id,
    name: 'Mock Wallet $id',
    userId: 'mock_user_id',
    email: 'mock@test.com',
    publicKey: 'mock_public_key',
    localKeyIdentifier: 'mock_local_id',
    color: Colors.blue,
    balance: 0.0,
  );
}

class MockBuildContext extends Mock implements BuildContext {}

void main(){
  group("RouteGenerator", () {
    group("Rotte senza argomenti", (){
      test("restituire LandingPage per /LandingPage", (){
        //genero la rotta
        final route = RouteGenerator.generateRoute(const RouteSettings(name: '/LandingPage'));
        //controlla che sia un MaterialPageRoute
        expect(route, isA<MaterialPageRoute>());
        //controlla che sia una pagina di tipo LandingPage
        expect((route as MaterialPageRoute).builder(MockBuildContext()), isA<LandingPage>());
      });
      test("restituire AuthPage per /AuthPage", (){
        final route = RouteGenerator.generateRoute(const RouteSettings(name: '/AuthPage'));
        expect(route, isA<MaterialPageRoute>());
        expect((route as MaterialPageRoute).builder(MockBuildContext()), isA<AuthPage>());
      });
    });

    group("/WalletPage", () {
      test("dovrebbe restituire WalletPage con argomenti Wallet validi", (){
        final mockWallet = createMockWallet("1");
        final route = RouteGenerator.generateRoute(RouteSettings(name: '/WalletPage', arguments: mockWallet));

        expect(route, isA<MaterialPageRoute>());
        expect((route as MaterialPageRoute).builder(MockBuildContext()), isA<WalletPage>());
      });

      test("Wallet Page con argomenti non validi", (){
        final route = RouteGenerator.generateRoute(const RouteSettings(name: '/WalletPage'));
        final page = (route as MaterialPageRoute).builder(MockBuildContext()) as Scaffold;

        expect(page.appBar, isNotNull);
        expect((page.appBar as AppBar).title, isA<Text>());
        expect(((page.appBar as AppBar).title as Text).data, 'Errore');
      });
    });
  });

  group("/NewWalletCreation", (){
    test("dovrebbe restituire NewWalletCreation con argomenti Map<String, String> validi", (){
      final credenziali = {"uid": "test_uid", "mail" : "test@mail.com"};
      final route = RouteGenerator.generateRoute(RouteSettings(name: '/NewWalletCreation', arguments: credenziali));

      expect(route, isA<MaterialPageRoute>());
      expect((route as MaterialPageRoute).builder(MockBuildContext()), isA<NewWalletCreation>());
    });

    test("NewWalletCreation con argomenti non validi", (){
      final route = RouteGenerator.generateRoute(const RouteSettings(name: "/NewWalletCreation", arguments: 123));
      final page = (route as MaterialPageRoute).builder(MockBuildContext()) as Scaffold;

      expect(((page.appBar as AppBar).title as Text).data, "Errore");
    });
  });

  group("/chat_list", (){
    test("dovrebbe restituire ChatListPage con argomenti Wallet validi", (){
      final mockWallet = createMockWallet("1");
      final route = RouteGenerator.generateRoute(RouteSettings(name: '/chat_list', arguments: mockWallet));

      expect(route, isA<MaterialPageRoute>());
      expect((route as MaterialPageRoute).builder(MockBuildContext()), isA<ChatListPage>());
    });
    test("ChatListPage con argomenti non validi", (){
      final route = RouteGenerator.generateRoute(const RouteSettings(name: '/chat_list'));
      final page = (route as MaterialPageRoute).builder(MockBuildContext()) as Scaffold;

      expect(page.appBar, isNotNull);
      expect((page.appBar as AppBar).title, isA<Text>());
      expect(((page.appBar as AppBar).title as Text).data, 'Errore');
    });
  });

  group("/chat", (){
    test("dovrebbe restituire ChatPage con argomenti Map<String, Wallet> validi", (){
      final arguments = {
        "senderWallet": createMockWallet("sender"),
        "receiverWallet": createMockWallet("receiver"),
      };
      final route = RouteGenerator.generateRoute(RouteSettings(name: '/chat', arguments: arguments));

      expect(route, isA<MaterialPageRoute>());
      expect((route as MaterialPageRoute).builder(MockBuildContext()), isA<ChatPage>());
    });

    test("ChatPage con argomenti non validi", (){
      final route = RouteGenerator.generateRoute(const RouteSettings(name: '/chat', arguments: "non valido"));
      final page = (route as MaterialPageRoute).builder(MockBuildContext()) as Scaffold;

      expect(((page.appBar as AppBar).title as Text).data, "Errore");
    });
  });

  group("/WalletRecoverPage", (){
    test("dovrebbe restituire WalletRecoverPage con argomenti Wallet validi", (){
      final mockWallet = createMockWallet("1");
      final route = RouteGenerator.generateRoute(RouteSettings(name: '/WalletRecoverPage', arguments: mockWallet));

      expect(route, isA<MaterialPageRoute>());
      expect((route as MaterialPageRoute).builder(MockBuildContext()), isA<WalletRecoverPage>());
    });

    test("WalletRecoverPage con argomenti non validi", (){
      final route = RouteGenerator.generateRoute(const RouteSettings(name: '/WalletRecoverPage'));
      final page = (route as MaterialPageRoute).builder(MockBuildContext()) as Scaffold;

      expect(page.appBar, isNotNull);
      expect((page.appBar as AppBar).title, isA<Text>());
      expect(((page.appBar as AppBar).title as Text).data, 'Errore');
    });
  });

  group("/findContactPage", () {
    test("dovrebbe restituire FindContactPage con argomenti Wallet validi", () {
      final mockWallet = createMockWallet("1");
      final route = RouteGenerator.generateRoute(RouteSettings(name: '/findContactsPage', arguments: mockWallet));
      expect(route, isA<MaterialPageRoute>());
      expect((route as MaterialPageRoute).builder(MockBuildContext()), isA<FindContactPage>());
    });

    test("dovrebbe restituire una rotta di errore per argomenti non validi", () {
      final route = RouteGenerator.generateRoute(const RouteSettings(name: '/findContactsPage'));
      final page = (route as MaterialPageRoute).builder(MockBuildContext()) as Scaffold;
      expect(((page.appBar as AppBar).title as Text).data, "Errore");
    });
  });

  test("rotta sconosciuta", (){
    final route = RouteGenerator.generateRoute(const RouteSettings(name: '/non_esistente'));
    final page = (route as MaterialPageRoute).builder(MockBuildContext()) as Scaffold;

    expect(page.appBar, isNotNull);
    expect((page.appBar as AppBar).title, isA<Text>());
    expect(((page.appBar as AppBar).title as Text).data, "Errore");
  });
}
