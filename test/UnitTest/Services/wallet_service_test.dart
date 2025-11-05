import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/i_wallet_service.dart';
import 'package:key_wallet_app/services/secure_storage.dart';
import 'package:key_wallet_app/services/wallet_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';


// 1. ANNOTAZIONE: Specifichiamo tutte le classi da mockare
@GenerateMocks([
  FirebaseFirestore,
  SecureStorage,
  CollectionReference,
  DocumentReference,
  WriteBatch,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
import 'wallet_service_test.mocks.dart';

// Helper per mockare la chiamata a FieldValue.serverTimestamp()
// ignore: must_be_immutable
class MockFieldValue extends Mock implements FieldValue {
  static final serverTimestamp = MockFieldValue();
}

void main() {
  // Dichiarazione dei mock
  late WalletService walletService; // Testiamo la classe concreta
  late MockFirebaseFirestore mockFirestore;
  late MockSecureStorage mockSecureStorage;
  late MockCollectionReference<Map<String, dynamic>> mockWalletsCollection;
  late MockQuery<Map<String, dynamic>> mockQuery;
  late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;


  // 2. SETUP: Eseguito prima di ogni test
  setUp(() {
    // Inizializza i mock principali
    mockFirestore = MockFirebaseFirestore();
    mockSecureStorage = MockSecureStorage();

    // Inizializza i mock per le collection e query
    mockWalletsCollection = MockCollectionReference();
    mockQuery = MockQuery();
    mockQuerySnapshot = MockQuerySnapshot();

    // Crea l'istanza del servizio iniettando i mock
    walletService = WalletService(
      firestore: mockFirestore,
      secureStorage: mockSecureStorage,
    );

    // *** ARRANGE A CASCATA ***
    // Configura la catena di chiamate a Firestore
    when(mockFirestore.collection('wallets')).thenReturn(mockWalletsCollection);
    when(mockWalletsCollection.where(any, isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQuery);
    when(mockQuery.orderBy(any, descending: anyNamed('descending'))).thenReturn(mockQuery);
    when(mockQuery.limit(any)).thenReturn(mockQuery);
    when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
  });

  group('WalletService', () {

    // Test per il costruttore di default, per raggiungere il 100% di coverage
    test('il costruttore di default dovrebbe usare le istanze reali di Firebase e SecureStorage', () async {
      // ARRANGE: Inizializza il mock di Firebase per i test di unità.
      await Firebase.initializeApp();

      // ACT: Crea un'istanza senza passare argomenti.
      final defaultService = WalletService();

      // ASSERT: Verifica che l'oggetto sia stato creato correttamente.
      expect(defaultService, isNotNull);
      expect(defaultService, isA<IWalletService>());
    });

    group('fetchUserWallets', () {
      test('dovrebbe aggiornare isLoading e popolare la lista wallets con successo', () {
        // Usa fakeAsync per controllare il tempo e i micro-task (Futures)
        fakeAsync((async) {
          // ARRANGE
          final mockWalletDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
          when(mockWalletDoc.id).thenReturn('wallet1');
          when(mockWalletDoc.data()).thenReturn({
            'name': 'Test Wallet',
            'userId': 'user1',
            'email': 'email1',
            'publicKey': 'pk1',
            'localKeyIdentifier': 'lk1',
            'color': 'Color(0xff651fff)', // *** VIRGOLA CORRETTA ***
            'createdAt': Timestamp.now(), // Aggiunto per il parsing corretto
            'balance': 0.0, // Aggiunto per il parsing corretto
          });
          when(mockQuerySnapshot.docs).thenReturn([mockWalletDoc]);

          int listenerCallCount = 0;
          walletService.addListener(() => listenerCallCount++);

          // ACT
          walletService.fetchUserWallets('user1');

          // ASSERT - Stato iniziale dopo la chiamata
          expect(walletService.isLoading, isTrue, reason: "isLoading dovrebbe essere true subito dopo la chiamata");
          expect(listenerCallCount, 1, reason: "notifyListeners dovrebbe essere chiamato per isLoading=true");

          // Fai avanzare il tempo per completare tutti gli `await` dentro fetchUserWallets
          async.flushMicrotasks();

          // ASSERT - Stato finale dopo il completamento del Future
          expect(walletService.isLoading, isFalse, reason: "isLoading dovrebbe essere false dopo il caricamento");
          expect(walletService.wallets, isNotEmpty);
          expect(walletService.wallets.first.name, 'Test Wallet');
          expect(listenerCallCount, 2, reason: "notifyListeners dovrebbe essere chiamato dopo aver caricato i dati");
        });
      });

      test('dovrebbe gestire un errore e svuotare la lista wallets', () {
        fakeAsync((async) {
          // ARRANGE
          when(mockQuery.get()).thenThrow(Exception('Errore di rete simulato'));
          int listenerCallCount = 0;
          walletService.addListener(() => listenerCallCount++);

          // ACT
          walletService.fetchUserWallets('user1');

          // ASSERT - Stato iniziale
          expect(walletService.isLoading, isTrue);
          expect(listenerCallCount, 1);

          // Fai avanzare il tempo
          async.flushMicrotasks();

          // ASSERT - Stato finale dopo l'errore
          expect(walletService.isLoading, isFalse);
          expect(walletService.wallets, isEmpty);
          expect(listenerCallCount, 2);
        });
      });
    });

    group('generateAndAddWallet', () {
      test('dovrebbe scrivere su SecureStorage e aggiungere il wallet a Firestore', () async {
        // ARRANGE
        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        when(mockWalletsCollection.add(any)).thenAnswer((_) async => mockDocRef);
        when(mockDocRef.id).thenReturn('nuovo_wallet_id');
        when(mockSecureStorage.writeSecureData(any, any)).thenAnswer((_) async => {});

        int listenerCallCount = 0;
        walletService.addListener(() => listenerCallCount++);

        // ACT
        await walletService.generateAndAddWallet('user1', 'user@test.com', 'Nuovo Wallet', Colors.red, 'hbytes', 'standard', 'device');

        // ASSERT
        verify(mockSecureStorage.writeSecureData(any, any)).called(1);
        verify(mockWalletsCollection.add(any)).called(1);
        expect(listenerCallCount, 1);
        expect(walletService.wallets.first.name, 'Nuovo Wallet');
      });
    });

    group('deleteWalletDBandList', () {
      test('dovrebbe cancellare il documento da Firestore e rimuoverlo dalla lista', () async {
        // ARRANGE
        final walletDaCancellare = Wallet(
            id: 'id_da_cancellare', name: 'Da Cancellare', userId: '', email: '',
            publicKey: '', localKeyIdentifier: '', color: Colors.black, balance: 0
        );
        // Aggiungi manualmente il wallet alla lista interna per simulare lo stato pre-cancellazione.
        // Nota: Questo è un modo per testare la logica interna, accedendo a `_wallets` non sarebbe possibile.
        // Un'alternativa sarebbe fare prima un fetch.
        walletService.wallets.add(walletDaCancellare);

        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        when(mockWalletsCollection.doc('id_da_cancellare')).thenReturn(mockDocRef);
        when(mockDocRef.delete()).thenAnswer((_) async {});

        int listenerCallCount = 0;
        walletService.addListener(() => listenerCallCount++);

        // ACT
        await walletService.deleteWalletDBandList(walletDaCancellare);

        // ASSERT
        verify(mockDocRef.delete()).called(1);
        expect(walletService.wallets, isEmpty);
        expect(listenerCallCount, 1);
      });
    });

  });
}
