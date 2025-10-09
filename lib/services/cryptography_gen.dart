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
AsymmetricKeyPair<PublicKey, PrivateKey> generateRSAkeyPair(SecureRandom secureRandom) {
  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64), secureRandom,));
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


// =========================
// RSA Encryption / Decryption with Base64
// =========================

//Cripta una stringa e restituisce il risultato in base 64
Future<String?> rsaEncryptBase64(String plainText, RSAPublicKey publicKey) async {
  final engine = RSAEngine();
  engine.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  
  try{
    final encrypted = engine.process(Uint8List.fromList(utf8.encode(plainText)));
    return base64Encode(encrypted);
  } catch (e) {
    print("Errore nella codifica del messaggio ${e.toString()}");
    return null;
  }
}

Future<String?> rsaDecryptBase64(String cipherText, RSAPrivateKey privateKey) async {
  final engine = RSAEngine();
  engine.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  
  try{
    final decrypted = engine.process(base64Decode(cipherText));
    return utf8.decode(decrypted);
  }catch(e){
    print("Errore nella decodifica del messaggio ${e.toString()}");
    return "Messaggio non decodificabile";
  }
}


///////////////

RSAPublicKey parsePublicKeyFromJsonString(String jsonString) {
  final Map<String, dynamic> keyData = jsonDecode(jsonString);
  //
  final modulus = BigInt.parse(keyData['modulus']);
  final exponent = BigInt.parse(keyData['publicExponent']);

  return RSAPublicKey(modulus, exponent);
}

RSAPrivateKey parsePrivateKeyFromJsonString(String jsonString) {
  final Map<String, dynamic> keyData = jsonDecode(jsonString);

  final modulus = BigInt.parse(keyData['modulus']);
  final privateExponent = BigInt.parse(keyData['privateExponent']);
  final p = BigInt.parse(keyData['p']);
  final q = BigInt.parse(keyData['q']);

  return RSAPrivateKey(modulus, privateExponent, p, q);
}
