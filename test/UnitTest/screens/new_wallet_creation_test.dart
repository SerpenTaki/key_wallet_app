import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/screens/new_wallet_creation.dart';
import 'package:key_wallet_app/services/i_nfc_service.dart';
import 'package:key_wallet_app/services/i_wallet_service.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'new_wallet_creation_test.mocks.dart';

// Definizione del TagData per il mock, dato che non è un modello importabile
class MockTagData {
  final String? historicalBytes;
  final String? standard;
  MockTagData({this.historicalBytes, this.standard});
}

@GenerateMocks([INfcService, IWalletService, NFCTag])
void main() {
  late MockINfcService mockNfcService;
  late MockIWalletService mockWalletService;
  late MockNFCTag mockNfcTag;

  final Map<String, String> tCredentials = {'uid': 'test_uid', 'mail': 'test@mail.com'};

  // Funzione helper per creare il widget sotto test
  Future<void> pumpNewWalletCreation(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<INfcService>.value(value: mockNfcService),
          ChangeNotifierProvider<IWalletService>.value(value: mockWalletService),
        ],
        child: MaterialApp(
          home: NewWalletCreation(credenziali: tCredentials),
        ),
      ),
    );
  }

  // Setup di base per tutti i test
  setUp(() {
    mockNfcService = MockINfcService();
    mockWalletService = MockIWalletService();
    mockNfcTag = MockNFCTag();
    when(mockNfcService.checkAvailability()).thenAnswer((_) async => true);
  });

  group('Visualizzazione Iniziale e Disponibilità NFC', () {
    testWidgets('mostra il pulsante di scansione se NFC è disponibile', (tester) async {
      await pumpNewWalletCreation(tester);
      await tester.pumpAndSettle(); // Attende la risoluzione del future checkAvailability

      expect(find.text('Scansiona documento'), findsOneWidget);
      expect(find.text('NFC non disponibile su questo dispositivo.'), findsNothing);
      // Il pulsante Crea Wallet deve essere disabilitato
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed, isNull);
    });

    testWidgets('mostra il messaggio di avviso se NFC non è disponibile', (tester) async {
      when(mockNfcService.checkAvailability()).thenAnswer((_) async => false);

      await pumpNewWalletCreation(tester);
      await tester.pumpAndSettle();

      expect(find.text('Scansiona documento'), findsNothing);
      expect(find.text('NFC non disponibile su questo dispositivo.'), findsOneWidget);
    });
  });

  group('Scansione NFC', () {
    testWidgets('mostra indicatore di caricamento durante la scansione', (tester) async {
      when(mockNfcService.fetchNfcData()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        when(mockNfcTag.historicalBytes).thenReturn('bytes');
        when(mockNfcTag.standard).thenReturn('standard');
        return mockNfcTag;
      });

      await pumpNewWalletCreation(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scansiona documento'));
      await tester.pump(); // Inizia l'animazione di caricamento

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Scansione in corso...'), findsOneWidget);
    });

    testWidgets('mostra SnackBar di successo e abilita il pulsante se la scansione ha dati validi', (tester) async {
      final tHbytes = 'VALID_HBYTES';
      final tStandard = 'VALID_STANDARD';
      when(mockNfcService.fetchNfcData()).thenAnswer((_) async {
        when(mockNfcTag.historicalBytes).thenReturn('bytes');
        when(mockNfcTag.standard).thenReturn('standard');
        return mockNfcTag;
      });

      await pumpNewWalletCreation(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scansiona documento'));
      await tester.pumpAndSettle(); // Completa la scansione

      expect(find.text('Documento scansionato con successo!'), findsOneWidget);
      expect(find.text('HBytes: $tHbytes'), findsOneWidget);
      expect(find.text('Standard: $tStandard'), findsOneWidget);

      // Ora il pulsante "Crea Wallet" deve essere abilitato
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed, isNotNull);
    });

    testWidgets('mostra SnackBar di errore se la scansione ha dati non validi', (tester) async {
      when(mockNfcService.fetchNfcData()).thenAnswer((_) async {
        when(mockNfcTag.historicalBytes).thenReturn('bytes');
        when(mockNfcTag.standard).thenReturn('standard');
        return mockNfcTag;
      });

      await pumpNewWalletCreation(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scansiona documento'));
      await tester.pumpAndSettle();

      expect(find.text("Documento non valido per l'operazione"), findsOneWidget);
      // Il pulsante "Crea Wallet" deve rimanere disabilitato
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed, isNull);
    });

    testWidgets('mostra SnackBar di errore se la scansione lancia un\'eccezione', (tester) async {
      final error = 'NFC Error';
      when(mockNfcService.fetchNfcData()).thenThrow(Exception(error));

      await pumpNewWalletCreation(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scansiona documento'));
      await tester.pumpAndSettle();

      expect(find.text('Errore durante la scansione: Exception: $error'), findsOneWidget);
      expect(find.text('Scansione in corso...'), findsNothing);
    });
  });

  group('Creazione Wallet', () {
    setUp(() {
      // Per questi test, simuliamo una scansione già avvenuta con successo
      when(mockNfcService.fetchNfcData()).thenAnswer((_) async {
        when(mockNfcTag.historicalBytes).thenReturn('bytes');
        when(mockNfcTag.standard).thenReturn('standard');
        return mockNfcTag;
      });
    });

    testWidgets('mostra errore di validazione se il nome è vuoto', (tester) async {
      await pumpNewWalletCreation(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scansiona documento'));
      await tester.pumpAndSettle(); // Abilita il pulsante Crea

      // Non inserire il nome e premi "Crea Wallet"
      await tester.tap(find.text('Crea Wallet'));
      await tester.pumpAndSettle();

      expect(find.text('Inserisci un nome'), findsOneWidget);
      verifyNever(mockWalletService.generateAndAddWallet(any, any, any, any, any, any, any));
    });

    testWidgets('chiama generateAndAddWallet se il wallet non esiste', (tester) async {
      final tWalletName = 'My New Wallet';
      final tHbytes = 'VALID_HBYTES';
      final tStandard = 'VALID_STANDARD';

      // Mock: il wallet non esiste
      when(mockWalletService.checkIfWalletExists(tHbytes, tCredentials['uid']!)).thenAnswer((_) async => false);
      when(mockWalletService.generateAndAddWallet(any, any, any, any, any, any, any)).thenAnswer((_) async => {});

      await pumpNewWalletCreation(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scansiona documento'));
      await tester.pumpAndSettle();

      // Inserisci il nome
      await tester.enterText(find.byType(TextFormField), tWalletName);

      // Premi "Crea Wallet"
      await tester.tap(find.text('Crea Wallet'));
      await tester.pumpAndSettle();

      // Verifica che il metodo sia stato chiamato
      verify(mockWalletService.generateAndAddWallet(
        tCredentials['uid']!,
        tCredentials['mail']!,
        tWalletName,
        any, // selectedColor
        tHbytes,
        tStandard,
        any, // device
      )).called(1);

      // Poiché il test non gestisce la navigazione, la pagina sarà ancora lì
      // ma possiamo verificare che non ci siano SnackBar di errore
      expect(find.text("Documento già usato per un altro wallet"), findsNothing);
    });

    testWidgets('mostra SnackBar di errore se il wallet esiste già', (tester) async {
      final tHbytes = 'VALID_HBYTES';
      // Mock: il wallet esiste già
      when(mockWalletService.checkIfWalletExists(tHbytes, tCredentials['uid']!)).thenAnswer((_) async => true);
      when(mockNfcService.fetchNfcData()).thenAnswer((_) async {
        when(mockNfcTag.historicalBytes).thenReturn('bytes');
        when(mockNfcTag.standard).thenReturn('standard');
        return mockNfcTag;
      });


      await pumpNewWalletCreation(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scansiona documento'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Wallet Name');
      await tester.tap(find.text('Crea Wallet'));
      await tester.pumpAndSettle();

      expect(find.text("Documento già usato per un altro wallet"), findsOneWidget);
      verifyNever(mockWalletService.generateAndAddWallet(any, any, any, any, any, any, any));
    });
  });
}

