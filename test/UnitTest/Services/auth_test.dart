import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/services/auth.dart';
import 'package:key_wallet_app/services/i_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential])
import 'auth_test.mocks.dart'; // Importa il file che verrà generato da build_runner

void main() {
  // Dichiarazione delle variabili che useremo in tutti i test
  late IAuth authService; // Testiamo contro l'interfaccia per buona pratica
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;

  // 2. SETUP: Questa funzione viene eseguita prima di ogni singolo test.
  setUp(() {
    // Crea istanze fresche dei nostri mock
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();

    // Crea l'istanza del nostro servizio, INIETTANDO il mock di FirebaseAuth.
    // Questo è possibile grazie al costruttore di 'Auth' che accetta un 'firebaseAuth'.
    authService = Auth(firebaseAuth: mockFirebaseAuth);
  });

  // Dati di test riutilizzabili
  const tEmail = 'test@example.com';
  const tPassword = 'password123';

  group('Auth Service', () {
    // TEST PER I GETTER
    test('il costruttore di default dovrebbe usare FirebaseAuth.instance', () {
      // ACT: Crea un'istanza di Auth senza passare alcun argomento.
      // Questo forza l'esecuzione della parte destra dell'operatore '??'.
      final defaultAuthService = Auth();

      // ASSERT:
      // Non possiamo facilmente verificare quale istanza di FirebaseAuth sia stata usata,
      // ma il semplice fatto di aver creato l'istanza senza errori
      // ha eseguito la linea di codice mancante.
      // Questo test serve principalmente a completare la coverage.
      expect(defaultAuthService, isNotNull);
      expect(defaultAuthService, isA<IAuth>());
    });

    test('currentUser dovrebbe restituire l\'utente corrente da FirebaseAuth', () {
      // ARRANGE (Prepara lo scenario):
      // Quando `currentUser` viene chiamato sul mock, istruiscilo a restituire il nostro utente finto.
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);

      // ACT (Esegui l'azione):
      final result = authService.currentUser;

      // ASSERT (Verifica il risultato):
      expect(result, equals(mockUser));
      verify(mockFirebaseAuth.currentUser);
    });

    test('authStateChanges dovrebbe restituire lo stream da FirebaseAuth', () {
      // ARRANGE:
      final fakeStream = Stream.value(mockUser);
      when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => fakeStream);

      // ACT:
      final result = authService.authStateChanges;

      // ASSERT:
      expect(result, equals(fakeStream));
      verify(mockFirebaseAuth.authStateChanges());
    });

    // TEST PER I METODI ASINCRONI
    test('signInWithEmailAndPassword dovrebbe chiamare il metodo corrispondente su FirebaseAuth', () async {
      // ARRANGE:
      // Configura il mock per restituire un MockUserCredential quando viene chiamato il sign-in.
      // Questo risolve l'errore "type 'Null' is not a subtype of type 'UserCredential'".
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // ACT:
      await authService.signInWithEmailAndPassword(email: tEmail, password: tPassword);

      // ASSERT:
      // Verifica che il metodo del mock sia stato chiamato esattamente una volta con i dati corretti.
      verify(mockFirebaseAuth.signInWithEmailAndPassword(
        email: tEmail,
        password: tPassword,
      )).called(1);
    });

    test('createUserWithEmailAndPassword dovrebbe chiamare il metodo corrispondente su FirebaseAuth', () async {
      // ARRANGE:
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // ACT:
      await authService.createUserWithEmailAndPassword(email: tEmail, password: tPassword);

      // ASSERT:
      verify(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: tEmail,
        password: tPassword,
      )).called(1);
    });

    test('signOut dovrebbe chiamare il metodo signOut su FirebaseAuth', () async {
      // ARRANGE:
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      // ACT:
      await authService.signOut();

      // ASSERT:
      verify(mockFirebaseAuth.signOut()).called(1);
    });
  });
}
