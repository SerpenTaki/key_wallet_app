import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';

// =========================
// Secure random generator
// =========================
SecureRandom getSecureRandom() {
  final secureRandom = FortunaRandom(); //Generatore sicuro
  final seed = Uint8List(32); //Seed di 32 byte casuali
  final random = Random.secure();
  for (int i = 0; i < seed.length; i++) {
    seed[i] = random.nextInt(256); //Popola l'array seed lungo 32 byte con numeri casuali compresi tra 0 e 255
  }
  secureRandom.seed(KeyParameter(seed)); //Inizializza FortunaRandom con il seed popolato
  return secureRandom;
}

// =========================
// RSA KeyPair generator
// =========================
AsymmetricKeyPair<PublicKey, PrivateKey> generateRSAkeyPair(SecureRandom secureRandom) {
  final keyGen = RSAKeyGenerator(); //Generatore di chiavi RSA
  keyGen.init(ParametersWithRandom(RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64), secureRandom,));
  // Inizializza il generatore di chiavi RSA con i parametri specificati
  //65537 è il valore di default per il parametro publicExponent
  //2048 bit è il valore di default per il parametro keyLength sicura per l'uso moderno
  //64 rappresenta il numero di test di primalità per generare 2 numeri primi p e q
  //Parameters con Random usa secureRandom passato in funzione
  return keyGen.generateKeyPair();
}

// =========================
// Convert Keys <-> String
// =========================
String publicKeyToString(RSAPublicKey publicKey) {
  return jsonEncode({
    "modulus": publicKey.modulus.toString(), //prodotto dei primmi p e q
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


// =========================
// RSA Encryption / Decryption with Base64
// =========================

//Cripta una stringa e restituisce il risultato in base 64
Future<String?> rsaEncryptBase64(String plainText, RSAPublicKey publicKey) async {
  final engine = OAEPEncoding(RSAEngine()); //https://it.wikipedia.org/wiki/Optimal_Asymmetric_Encryption_Padding
  engine.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  
  try{
    final encrypted = engine.process(Uint8List.fromList(utf8.encode(plainText)));
    return base64Encode(encrypted);
  } catch (e) {
    //print("Errore nella codifica del messaggio ${e.toString()}");
    return null;
  }
}

Future<String?> rsaDecryptBase64(String cipherText, RSAPrivateKey privateKey) async {
  final engine = OAEPEncoding(RSAEngine());
  engine.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  
  try{
    final decrypted = engine.process(base64Decode(cipherText));
    return utf8.decode(decrypted);
  }catch(e){
    //print("Errore nella decodifica del messaggio ${e.toString()}");
    return "Messaggio non decodificabile";
  }
}

RSAPublicKey parsePublicKeyFromJsonString(String jsonString) {
  final Map<String, dynamic> keyData = jsonDecode(jsonString);

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

String convertPublicKeyToBase64String(String publicKey){
  return base64Encode(utf8.encode(publicKey));
}

String convertPrivateKeyToBase64String(String privateKey){
  return base64Encode(utf8.encode(privateKey));
}