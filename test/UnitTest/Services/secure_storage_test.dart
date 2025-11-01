import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/services/secure_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

//    Diciamo a Mockito di creare una versione "mock" della classe FlutterSecureStorage.
@GenerateMocks([FlutterSecureStorage])
import 'secure_storage_test.mocks.dart';

void main() {
  // Dichiarazione delle variabili di test
  late SecureStorage secureStorageService;
  late MockFlutterSecureStorage mockFlutterSecureStorage;

  setUp(() {
    mockFlutterSecureStorage = MockFlutterSecureStorage();
    secureStorageService = SecureStorage(storage: mockFlutterSecureStorage);
  });

  group('SecureStorage', () {
    const testKey = 'my_test_key';
    const testValue = 'my_secret_value';

    test('writeSecureData dovrebbe chiamare il metodo write del plugin', () async {
      //    Configuriamo il mock. Quando `write` viene chiamato con QUALSIASI
      //    argomento, non fare nulla (completa semplicemente il Future).
      when(mockFlutterSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      await secureStorageService.writeSecureData(testKey, testValue);

      //    Verifichiamo che il metodo `write` del mock sia stato chiamato
      //    esattamente una volta, con la chiave e il valore corretti.
      verify(mockFlutterSecureStorage.write(key: testKey, value: testValue)).called(1);
    });

    // TEST PER IL METODO readSecureData
    test('readSecureData dovrebbe chiamare il metodo read e restituire il valore', () async {
      // Quando `read` viene chiamato con la nostra chiave di test,
      // istruiamo il mock a restituire il nostro valore di test.
      when(mockFlutterSecureStorage.read(key: testKey))
          .thenAnswer((_) async => testValue);

      // Chiamiamo il nostro metodo e salviamo il risultato.
      final result = await secureStorageService.readSecureData(testKey);


      // Verifichiamo che il risultato sia quello che ci aspettavamo.
      expect(result, equals(testValue));
      // Verifichiamo anche che il metodo `read` del mock sia stato chiamato una volta.
      verify(mockFlutterSecureStorage.read(key: testKey)).called(1);
    });

    // TEST PER IL METODO deleteSecureData
    test('deleteSecureData dovrebbe chiamare il metodo delete del plugin', () async {
      // Quando `delete` viene chiamato, non fare nulla.
      when(mockFlutterSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async => {});

      // Chiamiamo il nostro metodo di cancellazione.
      await secureStorageService.deleteSecureData(testKey);
      verify(mockFlutterSecureStorage.delete(key: testKey)).called(1);
    });
  });
}
