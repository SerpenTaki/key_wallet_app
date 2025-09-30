import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';

// =========================
// Secure random generator
// =========================
SecureRandom getSecureRandom() {
  final secureRandom = FortunaRandom();
  final seed = Uint8List(32);
  final random = Random.secure();
  for (int i = 0; i < seed.length; i++) {
    seed[i] = random.nextInt(256);
  }
  secureRandom.seed(KeyParameter(seed));
  return secureRandom;
}

// =========================
// RSA KeyPair generator
// =========================
AsymmetricKeyPair<PublicKey, PrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom) {
  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
      secureRandom,
    ));

  return keyGen.generateKeyPair();
}

// =========================
// Convert Keys <-> String
// =========================
String publicKeyToString(RSAPublicKey publicKey) {
  return jsonEncode({
    "modulus": publicKey.modulus.toString(),
    "publicExponent": publicKey.exponent.toString(),
  });
}

String privateKeyToString(RSAPrivateKey privateKey) {
  return jsonEncode({
    "modulus": privateKey.modulus.toString(),
    "privateExponent": privateKey.exponent.toString(),
    "p": privateKey.p.toString(),
    "q": privateKey.q.toString(),
  });
}

RSAPublicKey? publicKeyFromString(String keyString) {
  try {
    final map = jsonDecode(keyString);
    return RSAPublicKey(
      BigInt.parse(map['modulus']),
      BigInt.parse(map['publicExponent']),
    );
  } catch (e) {
    return null;
  }
}

RSAPrivateKey? privateKeyFromString(String keyString) {
  try {
    final map = jsonDecode(keyString);
    return RSAPrivateKey(
      BigInt.parse(map['modulus']),
      BigInt.parse(map['privateExponent']),
      BigInt.parse(map['p']),
      BigInt.parse(map['q']),
    );
  } catch (e) {

    return null;
  }
}

// =========================
// RSA Encryption / Decryption
// =========================
Future<Uint8List?> rsaEncrypt(String plainText, RSAPublicKey publicKey) async {
  try {
    final engine = RSAEngine()
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    return engine.process(Uint8List.fromList(utf8.encode(plainText)));
  } catch (e) {
    return null;
  }
}

Future<String?> rsaDecrypt(Uint8List cipherText, RSAPrivateKey privateKey) async {
  try {
    final engine = RSAEngine()
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final decrypted = engine.process(cipherText);
    return utf8.decode(decrypted);
  } catch (e) {
    return null;
  }
}
