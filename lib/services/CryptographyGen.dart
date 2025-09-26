import 'package:pointycastle/export.dart' as pointy;
import 'package:convert/convert.dart';
import 'dart:math';
import 'dart:typed_data';

// Function to generate an RSA key pair
pointy.AsymmetricKeyPair<pointy.PublicKey, pointy.PrivateKey> generateRSAkeyPair(
    pointy.SecureRandom secureRandom, {int bitLength = 2048}) {
  final keyGen = pointy.RSAKeyGenerator()
    ..init(pointy.ParametersWithRandom(
        pointy.RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom));
  final pair = keyGen.generateKeyPair();
  return pointy.AsymmetricKeyPair<pointy.RSAPublicKey, pointy.RSAPrivateKey>(
      pair.publicKey as pointy.RSAPublicKey,
      pair.privateKey as pointy.RSAPrivateKey);
}
//Ritorna una mappa con chiave pubblica e privata.

pointy.SecureRandom getSecureRandom() {
  final secureRandom = pointy.FortunaRandom();
  final seed = Uint8List(32);
  final random = Random.secure();
  for (int i = 0; i < seed.length; i++) {
    seed[i] = random.nextInt(256);
  }
  secureRandom.seed(pointy.KeyParameter(seed));
  return secureRandom;
}

// Converts an RSA public key to a string representation.
// Note: This is a simplified representation. For production, use standard formats like PEM.
String publicKeyToString(pointy.RSAPublicKey publicKey) {
  final modulusHex = hex.encode(publicKey.modulus!.toRadixString(16).codeUnits);
  final exponentHex = hex.encode(publicKey.exponent!.toRadixString(16).codeUnits);
  return 'modulus:${modulusHex}_exponent:${exponentHex}';
}

// Converts an RSA private key to a string representation.
// WARNING: Private key material must be handled with extreme care.
// This simplified representation is not secure for storage or transmission of private keys.
String privateKeyToString(pointy.RSAPrivateKey privateKey) {
  final modulusHex = hex.encode(privateKey.modulus!.toRadixString(16).codeUnits);
  final privateExponentHex = hex.encode(privateKey.privateExponent!.toRadixString(16).codeUnits);
  return 'modulus:${modulusHex}_privateExponent:${privateExponentHex}';
}