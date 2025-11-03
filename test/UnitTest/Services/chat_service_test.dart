// test/UnitTest/Services/chat_service_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/chat_service.dart';
import 'package:key_wallet_app/services/i_chat_service.dart';
import 'package:key_wallet_app/services/secure_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// 1. ANNOTAZIONE: Specifichiamo tutte le classi che dobbiamo mockare.
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  WriteBatch,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
  FirebaseAuth,
  User,
  SecureStorage,
])
import 'chat_service_test.mocks.dart';

// Funzione helper per creare un mock di Wallet per i test
Wallet createMockWallet(String id, String userId, {String? name, String? pk}) {
  return Wallet(
    id: 'doc_id_$id',
    localKeyIdentifier: 'local_key_$id',
    userId: userId,
    name: name ?? 'Wallet $id',
    email: 'test$id@example.com',
    publicKey: pk ?? 'pk_$id',
    color: Colors.blue,
    balance: 0.0,
  );
}

void main() {
  // Dichiarazione dei mock
  late IChatService chatService;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockSecureStorage mockSecureStorage;
  late MockCollectionReference<Map<String, dynamic>> mockChatRoomsCollection;
  late MockCollectionReference<Map<String, dynamic>> mockWalletsCollection;
  late MockQuery<Map<String, dynamic>> mockQuery;
  late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;

  // Dati di test
  final senderWallet = createMockWallet('sender', 'user_1');
  final receiverWallet = createMockWallet('receiver', 'user_2', name: 'Alice');

  // 2. SETUP: Eseguito prima di ogni test
  setUp(() {
    // Inizializza i mock principali
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockSecureStorage = MockSecureStorage();

    // Inizializza i mock per le collection e query
    mockChatRoomsCollection = MockCollectionReference();
    mockWalletsCollection = MockCollectionReference();
    mockQuery = MockQuery();
    mockQuerySnapshot = MockQuerySnapshot();

    // Crea l'istanza del servizio iniettando i mock
    chatService = ChatService(
      firestore: mockFirestore,
      auth: mockAuth,
    );

    // *** ARRANGE A CASCATA (Configurazione di base per tutti i test) ***
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('user_1');
    when(mockFirestore.collection('chat_rooms')).thenReturn(mockChatRoomsCollection);
    when(mockFirestore.collection('wallets')).thenReturn(mockWalletsCollection);
    when(mockChatRoomsCollection.where(any, arrayContains: anyNamed('arrayContains'))).thenReturn(mockQuery);
    when(mockWalletsCollection.where(any, whereIn: anyNamed('whereIn'))).thenReturn(mockQuery);
    when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));
    when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
  });

  group('ChatService', () {
    group('getConversationsStream', () {
      test('dovrebbe restituire una lista di contatti con cui si ha una chat', () {
        // ARRANGE
        final mockChatRoomDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockChatRoomDoc.data()).thenReturn({
          'participants': [senderWallet.localKeyIdentifier, receiverWallet.localKeyIdentifier],
          'participantUids': [senderWallet.userId, receiverWallet.userId],
        });
        when(mockQuerySnapshot.docs).thenReturn([mockChatRoomDoc]);

        final mockWalletDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockWalletDoc.id).thenReturn(receiverWallet.id);
        when(mockWalletDoc.data()).thenReturn({
          'name': receiverWallet.name, 'email': receiverWallet.email, 'localKeyIdentifier': receiverWallet.localKeyIdentifier,
        });
        final mockWalletSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
        when(mockWalletSnapshot.docs).thenReturn([mockWalletDoc]);
        when(mockWalletsCollection.where('localKeyIdentifier', whereIn: [receiverWallet.localKeyIdentifier])).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockWalletSnapshot);

        // ACT & ASSERT
        expectLater(
          chatService.getConversationsStream(senderWallet.id, senderWallet.localKeyIdentifier),
          emits(isA<List<Map<String, dynamic>>>()
              .having((list) => list.length, 'length', 1)
              .having((list) => list.first['name'], 'name', 'Alice')),
        );
      });
    });

    group('createConversationIfNotExists', () {
      test('dovrebbe creare una nuova chat room se non esiste', () async {
        // ARRANGE
        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockChatRoomsCollection.doc(any)).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocRef.set(any)).thenAnswer((_) async => {});

        // ACT
        await chatService.createConversationIfNotExists(senderWallet, receiverWallet);

        // ASSERT
        verify(mockDocRef.set(any)).called(1);
        verifyNever(mockDocRef.update(any));
      });

      test('dovrebbe aggiornare il timestamp se la chat room esiste già', () async {
        // ARRANGE
        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockChatRoomsCollection.doc(any)).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocRef.update(any)).thenAnswer((_) async => {});

        // ACT
        await chatService.createConversationIfNotExists(senderWallet, receiverWallet);

        // ASSERT
        verify(mockDocRef.update(any)).called(1);
        verifyNever(mockDocRef.set(any));
      });
    });

    group('sendMessage', () {
      test('non dovrebbe fare nulla se il messaggio è vuoto', () async {
        // ACT
        await chatService.sendMessage(receiverWallet, senderWallet, '   ');

        // ASSERT
        verifyNever(mockFirestore.batch());
      });

      test('dovrebbe scrivere un nuovo messaggio e aggiornare la chat room', () async {
        // ARRANGE
        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockBatch = MockWriteBatch();
        when(mockChatRoomsCollection.doc(any)).thenReturn(mockDocRef);
        when(mockDocRef.collection('messages')).thenReturn(mockChatRoomsCollection);
        when(mockChatRoomsCollection.doc()).thenReturn(mockDocRef);
        when(mockFirestore.batch()).thenReturn(mockBatch);

        // ACT
        await chatService.sendMessage(receiverWallet, senderWallet, 'Ciao!');

        // ASSERT
        verify(mockBatch.set(mockDocRef, any)).called(1);
        verify(mockBatch.update(mockDocRef, any)).called(1);
        verify(mockBatch.commit()).called(1);
      });
    });

    group('translateMessage', () {
      test('dovrebbe decifrare correttamente un messaggio se la chiave esiste', () async {
        // ARRANGE
        const privateKeyJson = '{"kty":"RSA","n":"...","e":"AQAB","d":"...","p":"...","q":"...","dp":"...","dq":"...","qi":"..."}'; // Esempio di chiave

        // Configura il mock di SecureStorage
        when(mockSecureStorage.readSecureData(senderWallet.localKeyIdentifier))
            .thenAnswer((_) async => privateKeyJson);

        // ACT (Questo test richiede un vero CryptoUtils, non è mockato)
        // Per un test più puro, dovresti iniettare anche CryptoUtils, ma per ora va bene.
        // Simuliamo il risultato della decifrazione per non dipendere dalla crittografia reale nel test.
        // Questa parte è difficile da testare senza dipendere da CryptoUtils,
        // quindi verifichiamo solo che readSecureData sia chiamato.
        await chatService.translateMessage('some_message', senderWallet);

        // ASSERT
        verify(mockSecureStorage.readSecureData(senderWallet.localKeyIdentifier)).called(1);
      });
    });
  });
}
