import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:key_wallet_app/screens/auth_page.dart';
import 'package:key_wallet_app/services/i_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'auth_page_test.mocks.dart';

@GenerateMocks([IAuth])
void main() {
  late MockIAuth mockAuth;

  setUp(() {
    mockAuth = MockIAuth();
  });

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<IAuth>.value(value: mockAuth),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  const String testEmail = 'test@example.com';
  const String testPassword = 'password123';

  group('AuthPage Widget Tests', () {
    testWidgets('La pagina si costruisce correttamente in modalità Login', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AuthPage()));

      // Verifiche specifiche per evitare ambiguità
      expect(find.widgetWithText(AppBar, 'Login'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(TextButton, "Non hai un account? Registrati"), findsOneWidget);
    });

    testWidgets('Passa alla modalita Registrazione quando si tocca il testo apposito', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AuthPage()));

      // Tappa il bottone che cambia modalità
      await tester.tap(find.byType(TextButton));
      await tester.pump(); // Ricostruisce la UI

      // Controlla il testo aggiornato
      expect(find.text("Hai un account? Accedi"), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Registrati'), findsOneWidget);
    });


    testWidgets('Chiama signInWithEmailAndPassword quando si preme Login con dati validi', (WidgetTester tester) async {
      when(mockAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestableWidget(const AuthPage()));
      await tester.enterText(find.byKey(const Key('emailField')), testEmail);
      await tester.enterText(find.byKey(const Key('passwordField')), testPassword);

      // Usa la Key per trovare il pulsante senza ambiguità
      await tester.tap(find.byKey(const Key('actionButton')));
      await tester.pump();

      verify(mockAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).called(1);
    });

    testWidgets('Mostra una SnackBar se il login fallisce', (WidgetTester tester) async {
      when(mockAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenThrow(FirebaseAuthException(code: 'wrong-password', message: 'Credenziali errate'));

      await tester.pumpWidget(buildTestableWidget(const AuthPage()));
      await tester.enterText(find.byKey(const Key('emailField')), testEmail);
      await tester.enterText(find.byKey(const Key('passwordField')), testPassword);

      await tester.tap(find.byKey(const Key('actionButton')));

      // Devi fare due pump(): uno per processare il tap, e un altro per l'animazione della SnackBar
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Credenziali errate'), findsOneWidget);
    });

    testWidgets('Non chiama nessun metodo se il form non valido', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AuthPage()));
      await tester.enterText(find.byKey(const Key('emailField')), 'email-non-valida');
      await tester.enterText(find.byKey(const Key('passwordField')), ''); // Password vuota

      await tester.tap(find.byKey(const Key('actionButton')));

      // *** MODIFICA CHIAVE ***
      // Devi chiamare `pump()` DOPO il tap per dare tempo alla UI di
      // aggiornarsi e mostrare i messaggi di errore della validazione.
      await tester.pump();

      // ASSERT:
      verifyNever(mockAuth.signInWithEmailAndPassword(email: anyNamed('email'), password: anyNamed('password')));
      verifyNever(mockAuth.createUserWithEmailAndPassword(email: anyNamed('email'), password: anyNamed('password')));

      // Ora che la UI è stata aggiornata, i messaggi di errore saranno visibili.
      expect(find.text('Inserisci un\'email valida'), findsOneWidget);
      expect(find.text('Inserisci una password'), findsOneWidget);
    });
  });
}
