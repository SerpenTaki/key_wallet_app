import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/services/contact_service.dart';
import 'package:key_wallet_app/services/i_contact_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// 1. ANNOTAZIONE: Specifichiamo tutte le classi di Firestore che dobbiamo mockare
//    per simulare una query completa.
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])

import 'contact_service_test.mocks.dart';

void main() {
  // Dichiarazione delle variabili di test
  late IContactService contactService;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollectionReference;
  late MockQuery<Map<String, dynamic>> mockQuery;
  late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
  late MockQueryDocumentSnapshot<Map<String, dynamic>> mockQueryDocumentSnapshot;

  // 2. SETUP: Eseguito prima di ogni test
  setUp(() {
    // Inizializza tutti i mock
    mockFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference();
    mockQuery = MockQuery();
    mockQuerySnapshot = MockQuerySnapshot();
    mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

    // Crea l'istanza del nostro servizio, INIETTANDO il mock di Firestore
    contactService = ContactService(firestore: mockFirestore);

    // *** ARRANGE A CASCATA ***
    // Questa è la parte più importante: colleghiamo i mock tra loro per simulare una chiamata a Firestore.
    // 1. Quando si chiama .collection('wallets'), restituisci il nostro mock della collection.
    when(mockFirestore.collection('wallets')).thenReturn(mockCollectionReference);

    // 2. Quando si chiama .where(...) sulla collection, restituisci il nostro mock della query.
    //    Usiamo `any` perché non ci interessa testare il `.where()` qui, ma solo il risultato finale.
    when(mockCollectionReference.where(any, isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQuery);

    // 3. Quando si chiama .get() sulla query, restituisci il nostro mock dello snapshot.
    when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
  });

  group('ContactService', () {
    // Dati finti per i risultati della query
    final mockWalletData = {
      'name': 'Test Wallet',
      'email': 'test@example.com',
      // ... altri campi
    };
    const mockDocId = 'test_doc_id';

    // --- TEST PER searchWalletsByEmail ---
    group('searchWalletsByEmail', () {
      test('dovrebbe restituire una lista di wallet se l\'email viene trovata', () async {
        // ARRANGE
        // Configura la risposta finale: lo snapshot contiene un documento finto.
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
        when(mockQueryDocumentSnapshot.data()).thenReturn(mockWalletData);
        when(mockQueryDocumentSnapshot.id).thenReturn(mockDocId);

        // ACT
        final results = await contactService.searchWalletsByEmail('test@example.com');

        // ASSERT
        expect(results, isNotEmpty);
        expect(results.length, 1);
        expect(results[0]['name'], 'Test Wallet');
        expect(results[0]['id'], mockDocId); // Controlla che l'ID del documento sia stato aggiunto
      });

      test('dovrebbe restituire una lista vuota se l\'email non viene trovata', () async {
        // ARRANGE
        // Configura lo snapshot per non contenere documenti.
        when(mockQuerySnapshot.docs).thenReturn([]);

        // ACT
        final results = await contactService.searchWalletsByEmail('notfound@example.com');

        // ASSERT
        expect(results, isEmpty);
      });

      test('dovrebbe restituire una lista vuota se l\'email è vuota', () async {
        // ACT
        final results = await contactService.searchWalletsByEmail('');

        // ASSERT
        expect(results, isEmpty);
        // Verifica che Firestore NON sia stato chiamato se l'email è vuota, per ottimizzazione.
        verifyNever(mockFirestore.collection('wallets'));
      });
    });

    // --- TEST PER searchWalletsByNfc ---
    group('searchWalletsByNfc', () {
      test('dovrebbe restituire un wallet se i dati NFC corrispondono', () async {
        // ARRANGE
        // La configurazione a cascata del `setUp` è sufficiente, ma qui la ridefiniamo per chiarezza.
        // Simuliamo una query con due clausole `where`.
        when(mockCollectionReference.where('hBytes', isEqualTo: 'hbytes_test')).thenReturn(mockQuery);
        when(mockQuery.where('standard', isEqualTo: 'standard_test')).thenReturn(mockQuery);

        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
        when(mockQueryDocumentSnapshot.data()).thenReturn(mockWalletData);
        when(mockQueryDocumentSnapshot.id).thenReturn(mockDocId);

        // ACT
        final results = await contactService.searchWalletsByNfc('hbytes_test', 'standard_test');

        // ASSERT
        expect(results, isNotEmpty);
        expect(results.length, 1);
        expect(results[0]['email'], 'test@example.com');
      });

      test('dovrebbe restituire una lista vuota se i dati NFC non vengono trovati', () async {
        // ARRANGE
        when(mockQuerySnapshot.docs).thenReturn([]);

        // ACT
        final results = await contactService.searchWalletsByNfc('not_found', 'not_found');

        // ASSERT
        expect(results, isEmpty);
      });
    });
  });
}
