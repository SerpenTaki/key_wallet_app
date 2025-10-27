import 'package:key_wallet_app/services/crypto_utils.dart';

class RecoverService {
  Future<bool> checkIfRight(String publicKey, String privateKeyString) async {
    final cryptoUtils = CryptoUtils();
    if (privateKeyString
        .trim()
        .isEmpty) {
      return false;
    }
    try {
      const String testString = "ciao";
      final dynamic encoded = await cryptoUtils.rsaEncryptBase64(
          testString, cryptoUtils.parsePublicKeyFromJsonString(publicKey));
      final dynamic decoded = await cryptoUtils.rsaDecryptBase64(
          encoded, cryptoUtils.parsePrivateKeyFromJsonString(privateKeyString));
      return decoded == testString;
    } catch (e) {
      //print("error: $e");
      return false;
    }
  }
}
