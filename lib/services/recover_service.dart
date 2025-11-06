import 'package:key_wallet_app/services/crypto_utils.dart';
import 'package:key_wallet_app/services/i_recover_service.dart';

class RecoverService implements IRecoverService{
  final CryptoUtils _cryptoUtils;

  RecoverService({CryptoUtils? cryptoUtils})
    : _cryptoUtils = cryptoUtils ?? CryptoUtils();


  @override
  Future<bool> checkIfRight(String publicKey, String privateKeyString) async {
    if (privateKeyString.trim().isEmpty) {
      return false;
    }
    try {
      const String testString = "ciao";
      final dynamic encoded = await _cryptoUtils.rsaEncryptBase64(
          testString, _cryptoUtils.parsePublicKeyFromJsonString(publicKey));
      final dynamic decoded = await _cryptoUtils.rsaDecryptBase64(
          encoded, _cryptoUtils.parsePrivateKeyFromJsonString(privateKeyString.trim()));
      return decoded == testString;
    } catch (e) {
      //print("error: $e");
      return false;
    }
  }
}
