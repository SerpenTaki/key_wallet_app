import 'package:key_wallet_app/services/cryptography_gen.dart';

Future<bool> checkIfRight(String publicKey, String privateKeyString) async {
  if (privateKeyString.trim().isEmpty) {
    return false;
  }
  try {
    const String testString = "ciao";
    final dynamic encoded = await rsaEncryptBase64(testString, parsePublicKeyFromJsonString(publicKey));
    final dynamic decoded = await rsaDecryptBase64(encoded, parsePrivateKeyFromJsonString(privateKeyString));
    return decoded == testString;
  } catch (e) {
    //print("error: $e");
    return false;
  }
}
