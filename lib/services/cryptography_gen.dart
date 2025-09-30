import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asymmetric/api.dart';

// Secure random generator
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

// RSA KeyPair generator
AsymmetricKeyPair<PublicKey, PrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom) {
  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
      secureRandom,
    ));

  return keyGen.generateKeyPair();
}

// Convert public key to string
String publicKeyToString(RSAPublicKey publicKey) {
  return jsonEncode({
    "modulus": publicKey.modulus.toString(),
    "publicExponent": publicKey.exponent.toString(),
  });
}

// Parse private key from string
// Convert private key to string (salva anche p e q)
String privateKeyToString(RSAPrivateKey privateKey) {
  return jsonEncode({
    "modulus": privateKey.modulus.toString(),
    "privateExponent": privateKey.exponent.toString(),
    "p": privateKey.p.toString(),
    "q": privateKey.q.toString(),
  });
}

// Parse private key from string
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
    print("Errore parsing private key: $e");
    return null;
  }
}


// Parse public key from string
RSAPublicKey? publicKeyFromString(String keyString) {
  try {
    final map = jsonDecode(keyString);
    return RSAPublicKey(
      BigInt.parse(map['modulus']),
      BigInt.parse(map['publicExponent']),
    );
  } catch (e) {
    print("Errore parsing public key: $e");
    return null;
  }
}

// Process with private key (firma)
Future<Uint8List?> rsaProcessWithPrivateKey(
    String plainText, RSAPrivateKey privateKey) async {
  try {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final sig = signer.generateSignature(Uint8List.fromList(utf8.encode(plainText)));
    return sig.bytes;
  } catch (e) {
    print("Errore processWithPrivateKey: $e");
    return null;
  }
}

// Process with public key (verifica/firma inversa)
Future<String?> rsaProcessWithPublicKey(
    Uint8List processedData, RSAPublicKey publicKey) async {
  try {
    // Per semplificare, facciamo solo decrypt stile "verify"
    final engine = RSAEngine()
      ..init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

    final decrypted = engine.process(processedData);
    return utf8.decode(decrypted);
  } catch (e) {
    print("Errore processWithPublicKey: $e");
    return null;
  }
}
