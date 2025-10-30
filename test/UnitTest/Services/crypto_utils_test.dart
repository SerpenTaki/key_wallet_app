import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/services/crypto_utils.dart';
import 'package:pointycastle/asymmetric/api.dart' as pointy;

void main() {
  // Crea un'istanza del servizio da testare
  final cryptoUtils = CryptoUtils();

  group('CryptoUtils generazioni chiavi e parsing', () {
    test('Genera una coppia di chiavi RSA valida', () {
      final keyPair = cryptoUtils.generateRSAkeyPair(
          cryptoUtils.getSecureRandom());

      //Controllo se è null quindi se generato
      expect(keyPair, isNotNull);
      //Controllo il tipo sia esatto
      expect(keyPair.publicKey, isA<pointy.RSAPublicKey>());
      expect(keyPair.privateKey, isA<pointy.RSAPrivateKey>());
    });

    test(
        'Controlla che il parsing delle chiavi a stringa e la riconversione in chiave sia corretto', () {
      final keyPair = cryptoUtils.generateRSAkeyPair(
          cryptoUtils.getSecureRandom());
      final publicKey = keyPair.publicKey as pointy.RSAPublicKey;
      final privateKey = keyPair.privateKey as pointy.RSAPrivateKey;

      //Conversione in stringhe
      final publicKeyString = cryptoUtils.publicKeyToString(publicKey);
      final privateKeyString = cryptoUtils.privateKeyToString(privateKey);

      // string != empty
      expect(publicKeyString, isNotEmpty);
      expect(privateKeyString, isNotEmpty);

      //Conversione stringhe -> chiavi
      final parsedPublicKey = cryptoUtils.parsePublicKeyFromJsonString(
          publicKeyString);
      final parsedPrivateKey = cryptoUtils.parsePrivateKeyFromJsonString(
          privateKeyString);

      // Confrontiamo i moduli, che sono un identificatore univoco della coppia di chiavi per vedere se ha successo
      expect(parsedPublicKey.modulus, equals(publicKey.modulus));
      expect(parsedPrivateKey.modulus, equals(privateKey.modulus));
    });
  });

  group("Processo criptazione/decrittazione", () {
    late pointy.RSAPrivateKey privateKey;
    late pointy.RSAPublicKey publicKey;
    const String originalMessage = "Questo è un messaggio dei test!";

    setUp(() {
      final keypair = cryptoUtils.generateRSAkeyPair(
          cryptoUtils.getSecureRandom());
      publicKey = keypair.publicKey as pointy.RSAPublicKey;
      privateKey = keypair.privateKey as pointy.RSAPrivateKey;
    });

    test(
        "Cripta con la chiave pubblica decripta con la chiave privata", () async {
      final encryptedMessage = await cryptoUtils.rsaEncryptBase64(
          originalMessage, publicKey);

      expect(encryptedMessage, isNotNull);
      expect(encryptedMessage, isNotEmpty);
      expect(encryptedMessage, isNot(equals(originalMessage)));

      final decryptedMessage = await cryptoUtils.rsaDecryptBase64(
          encryptedMessage!, privateKey);

      expect(decryptedMessage, equals(originalMessage));
    });

    test("Decriptazione con una chiave privata errata", () async {
      final wrongKeyPair = cryptoUtils.generateRSAkeyPair(cryptoUtils.getSecureRandom());
      final wrongPrivateKey = wrongKeyPair.privateKey as pointy.RSAPrivateKey;

      final encryptedMessage = await cryptoUtils.rsaEncryptBase64(originalMessage, publicKey);

      final decryptedResult = await cryptoUtils.rsaDecryptBase64(encryptedMessage!, wrongPrivateKey);

      expect(decryptedResult, equals("Messaggio non decodificabile"));
    });

  });

  group("convertKeysToBase64String", () {
    late pointy.RSAPrivateKey privateKey;
    late pointy.RSAPublicKey publicKey;

    setUp(() {
      final keypair = cryptoUtils.generateRSAkeyPair(cryptoUtils.getSecureRandom());
      publicKey = keypair.publicKey as pointy.RSAPublicKey;
      privateKey = keypair.privateKey as pointy.RSAPrivateKey;
    });

    test('convert to base64 from string', () {
      String publicKeyString = cryptoUtils.publicKeyToString(publicKey);
      String privateKeyString = cryptoUtils.privateKeyToString(privateKey);

      String encodedPublicKey = cryptoUtils.convertKeyToBase64String(publicKeyString);
      String encodedPrivateKey = cryptoUtils.convertKeyToBase64String(privateKeyString);

      expect(encodedPublicKey, isNotNull);
      expect(encodedPrivateKey, isNotNull);
      expect(encodedPublicKey, isNotEmpty);
      expect(encodedPrivateKey, isNotEmpty);

      String decodedPublicKey = cryptoUtils.convertBase64ToString(encodedPublicKey);
      String decodedPrivateKey = cryptoUtils.convertBase64ToString(encodedPrivateKey);

      expect(decodedPublicKey, isNotNull);
      expect(decodedPrivateKey, isNotNull);
      expect(decodedPublicKey, isNotEmpty);
      expect(decodedPrivateKey, isNotEmpty);
      expect(decodedPublicKey, equals(publicKeyString));
      expect(decodedPrivateKey, equals(privateKeyString));

    });
  });
}
