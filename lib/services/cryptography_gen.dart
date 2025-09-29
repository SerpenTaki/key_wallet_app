import 'package:pointycastle/export.dart' as pointy;
import 'dart:convert' show utf8;
import 'dart:math';
import 'dart:typed_data';

// --------- FUNZIONI DI CONVERSIONE BigInt <-> Uint8List LOCALI ---------
// Queste funzioni sono state internalizzate per evitare problemi con le esportazioni di pointycastle.

/// Decodifica una lista di byte (little-endian) in un BigInt.
BigInt _bytesToBigInt(Uint8List bytes) {
  BigInt result = BigInt.from(0);
  for (int i = 0; i < bytes.length; i++) {
    result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
  }
  return result;
}

/// Codifica un BigInt in una lista di byte (little-endian).
/// La lunghezza `outLen` può essere specificata, altrimenti viene calcolata.
Uint8List _bigIntToBytes(BigInt number, int? outLen) {
  int len = outLen ?? (number.bitLength + 7) >> 3;
  final result = Uint8List(len);
  for (int i = 0; i < len; i++) {
    result[len - i - 1] = (number >> (8 * i)).toUnsigned(8).toInt();
  }
  return result;
}
// --------- FINE FUNZIONI LOCALI ---------


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

// --- CHIAVE PUBBLICA ---
String publicKeyToString(pointy.RSAPublicKey publicKey) {
  final modulusString = publicKey.modulus!.toRadixString(16);
  final exponentString = publicKey.exponent!.toRadixString(16);
  return 'modulus:${modulusString}_exponent:$exponentString';
}

pointy.RSAPublicKey? publicKeyFromString(String keyString) {
  try {
    final parts = keyString.split('_');
    if (parts.length != 2 || !parts[0].startsWith('modulus:') || !parts[1].startsWith('exponent:')) {
      print('Formato stringa chiave pubblica non valido (struttura): $keyString');
      return null;
    }
    final modulusString = parts[0].substring('modulus:'.length);
    final exponentString = parts[1].substring('exponent:'.length);

    if (modulusString.isEmpty || exponentString.isEmpty) {
      print('Formato stringa chiave pubblica non valido (valori vuoti). Modulus: "$modulusString", Exponent: "$exponentString"');
      return null;
    }

    final modulus = BigInt.parse(modulusString, radix: 16);
    final exponent = BigInt.parse(exponentString, radix: 16);

    if (modulus <= BigInt.zero) {
      print('Errore in publicKeyFromString: Il modulus RSA deve essere positivo. Valore ricevuto: $modulus');
      return null;
    }
    if (exponent <= BigInt.zero) {
      print('Errore in publicKeyFromString: L\'esponente pubblico RSA deve essere positivo. Valore ricevuto: $exponent');
      return null;
    }
    
    print('DEBUG: publicKeyFromString - Prima della chiamata al costruttore RSAPublicKey:');
    print('DEBUG: Modulus Type: ${modulus.runtimeType}');
    print('DEBUG: Modulus Value: ${modulus.toString()}');
    print('DEBUG: Exponent Type: ${exponent.runtimeType}');
    print('DEBUG: Exponent Value: ${exponent.toString()}');

    return pointy.RSAPublicKey(modulus, exponent);
  } catch (e,s) {
    print('Errore durante il parsing o la creazione di RSAPublicKey in publicKeyFromString: $e');
    print('Stringa chiave problematica: $keyString');
    print(s);
    return null;
  }
}

// --- CHIAVE PRIVATA ---
String privateKeyToString(pointy.RSAPrivateKey privateKey) {
  final modulusString = privateKey.modulus!.toRadixString(16);
  final privateExponentString = privateKey.privateExponent!.toRadixString(16);
  return 'modulus:${modulusString}_privateExponent:$privateExponentString';
}

pointy.RSAPrivateKey? privateKeyFromString(String keyString) {
  try {
    final parts = keyString.split('_');
    if (!parts[0].startsWith('modulus:') || !parts[1].startsWith('privateExponent:')) {
      print('Formato stringa chiave privata non valido (struttura): $keyString');
      return null;
    }
    final modulusString = parts[0].substring('modulus:'.length);
    final privateExponentString = parts[1].substring('privateExponent:'.length);

    if (modulusString.isEmpty || privateExponentString.isEmpty) {
      print('Formato stringa chiave privata non valido (valori vuoti). Modulus: "$modulusString", Exponent: "$privateExponentString"');
      return null;
    }

    final modulus = BigInt.parse(modulusString, radix: 16);
    final privateExponent = BigInt.parse(privateExponentString, radix: 16);
    
    if (modulus <= BigInt.zero) {
      print('Errore in privateKeyFromString: Il modulus RSA deve essere positivo. Valore ricevuto: $modulus');
      return null;
    }
    if (privateExponent <= BigInt.zero) {
      print('Errore in privateKeyFromString: L\'esponente privato RSA deve essere positivo. Valore ricevuto: $privateExponent');
      return null;
    }

    // --- NUOVE STAMPE DI DEBUG ---
    print('DEBUG: privateKeyFromString - Prima della chiamata al costruttore RSAPrivateKey:');
    print('DEBUG: Modulus Type: ${modulus.runtimeType}');
    print('DEBUG: Modulus Value: ${modulus.toString()}');
    print('DEBUG: PrivateExponent Type: ${privateExponent.runtimeType}');
    print('DEBUG: PrivateExponent Value: ${privateExponent.toString()}');
    // --- FINE NUOVE STAMPE DI DEBUG ---

    return pointy.RSAPrivateKey(modulus, privateExponent, null, null);
  } catch (e,s) {
    print('Errore durante il parsing o la creazione di RSAPrivateKey in privateKeyFromString: $e');
    print('Stringa chiave problematica: $keyString');
    print(s);
    return null;
  }
}

// --- FUNZIONI DI UTILITY PER CONVERSIONE STRINGA <-> Uint8List ---
Uint8List stringToUint8List(String data) {
  return Uint8List.fromList(utf8.encode(data));
}

String uint8ListToString(Uint8List data) {
  return utf8.decode(data);
}

// --- OPERAZIONI RSA CON BigInt.modPow (per test) ---

/// "Crittografa" i dati usando l'operazione RSA grezza con la chiave privata (m^d mod n).
Future<Uint8List?> rsaProcessWithPrivateKey(String plainText, pointy.RSAPrivateKey privateKey) async {
  try {
    final plainDataBytes = stringToUint8List(plainText);
    final plainDataBigInt = _bytesToBigInt(plainDataBytes); // USA LA VERSIONE LOCALE

    if (privateKey.privateExponent == null || privateKey.modulus == null) {
      print('Chiave privata non valida (mancano d o n per modPow)');
      return null;
    }
    // Controllo che i valori della chiave siano positivi per modPow
    if (privateKey.modulus! <= BigInt.zero || privateKey.privateExponent! <= BigInt.zero) {
       print('Chiave privata non valida per modPow (n o d non sono positivi).');
       return null;
    }
    if (plainDataBigInt >= privateKey.modulus!) {
        print('Dati in chiaro (come numero) troppo grandi per il modulo RSA.');
        return null;
    }

    final processedBigInt = plainDataBigInt.modPow(privateKey.privateExponent!, privateKey.modulus!);
    return _bigIntToBytes(processedBigInt, null); // USA LA VERSIONE LOCALE
  } catch (e, s) {
    print('Errore in rsaProcessWithPrivateKey: $e');
    print(s);
    return null;
  }
}

/// "Decifra" i dati usando l'operazione RSA grezza con la chiave pubblica (c^e mod n).
Future<String?> rsaProcessWithPublicKey(Uint8List processedDataBytes, pointy.RSAPublicKey publicKey) async {
  try {
    final processedDataBigInt = _bytesToBigInt(processedDataBytes); // USA LA VERSIONE LOCALE

    if (publicKey.exponent == null || publicKey.modulus == null) {
      print('Chiave pubblica non valida (mancano e o n per modPow)');
      return null;
    }
    // Controllo che i valori della chiave siano positivi per modPow
    if (publicKey.modulus! <= BigInt.zero || publicKey.exponent! <= BigInt.zero) {
       print('Chiave pubblica non valida per modPow (n o e non sono positivi).');
       return null;
    }
     if (processedDataBigInt >= publicKey.modulus!) {
        print('Dati cifrati (come numero) troppo grandi per il modulo RSA.');
        return null;
    }

    final originalBigInt = processedDataBigInt.modPow(publicKey.exponent!, publicKey.modulus!);
    final originalDataBytes = _bigIntToBytes(originalBigInt, null); // USA LA VERSIONE LOCALE
    return uint8ListToString(originalDataBytes);
  } catch (e, s) {
    print('Errore in rsaProcessWithPublicKey: $e');
    print(s);
    return null;
  }
}
