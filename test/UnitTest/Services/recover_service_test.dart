import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/services/crypto_utils.dart';
import 'package:key_wallet_app/services/recover_service.dart';
import 'package:pointycastle/asymmetric/api.dart' as pointy;

void main() {
  final recoverService = RecoverService();
  final cryptoUtils = CryptoUtils();

  group('RecoverService Key Validation', () {
    late String publicKeyString;
    late String privateKeyString;
    late String wrongPrivateKeyString;

    setUp(() {
      final validKeyPair = cryptoUtils.generateRSAkeyPair(cryptoUtils.getSecureRandom());
      final wrongKeyPair = cryptoUtils.generateRSAkeyPair(cryptoUtils.getSecureRandom());

      publicKeyString = cryptoUtils.publicKeyToString(validKeyPair.publicKey as pointy.RSAPublicKey);
      privateKeyString = cryptoUtils.privateKeyToString(validKeyPair.privateKey as pointy.RSAPrivateKey);
      wrongPrivateKeyString = cryptoUtils.privateKeyToString(wrongKeyPair.privateKey as pointy.RSAPrivateKey);
    });

    test('checkIfRight ritorna vero se le chiavi corrispondono', () async {
      final bool isMatch = await recoverService.checkIfRight(publicKeyString, privateKeyString);
      expect(isMatch, isTrue);
    });

    test('checkIfRight ritorna falso se le chiavi non corrispondono', () async {
      final bool isMatch = await recoverService.checkIfRight(publicKeyString, wrongPrivateKeyString);
      expect(isMatch, isFalse);
    });

    test('checkIfRight ritorna false per chiave privata vuota', () async {
      bool isMatch = await recoverService.checkIfRight(publicKeyString, '');
      expect(isMatch, isFalse);

      isMatch = await recoverService.checkIfRight(publicKeyString, 'questa non e una chiave');
      expect(isMatch, isFalse);
    });
  });

  group("Assicura che il ciclo di generazione e crittografia sia superiore al 95%;", (){
    const int nCicli = 100;

    test("Deve avere successo per $nCicli cicli di generazione e verifica", () async {
      int count = 0;

      for( int i = 0; i < nCicli; i++){
      //Chiavi valide
      final validKeyPair = cryptoUtils.generateRSAkeyPair(cryptoUtils.getSecureRandom());
      final publicKey = validKeyPair.publicKey as pointy.RSAPublicKey;
      final privateKey = validKeyPair.privateKey as pointy.RSAPrivateKey;
      final publicKeyString = cryptoUtils.publicKeyToString(publicKey);
      final privateKeyString = cryptoUtils.privateKeyToString(privateKey);

      //Chiavi Sbagliate
      final wrongKeyPair = cryptoUtils.generateRSAkeyPair(cryptoUtils.getSecureRandom());
      final wrongPrivateKey = wrongKeyPair.privateKey as pointy.RSAPrivateKey;
      final wrongPrivateKeyString = cryptoUtils.privateKeyToString(wrongPrivateKey);

      final bool isCorrectMatch = await recoverService.checkIfRight(publicKeyString, privateKeyString);
      final bool isWrongMatch = await recoverService.checkIfRight(publicKeyString, wrongPrivateKeyString);

      if (isCorrectMatch == true && isWrongMatch == false){
        count++;
      }else{
        fail('Il ciclo di test #${i + 1} è fallito. Corretta: $isCorrectMatch, Sbagliata: $isWrongMatch');
      }
    }
      print("Accutatezza del test: ${(count / nCicli)*100} % su $nCicli cicli di generazione e verifica");
      expect(count, greaterThanOrEqualTo(nCicli*0.95));
    });
  });
}
