import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'package:key_wallet_app/services/CryptographyGen.dart';
import 'package:pointycastle/asymmetric/api.dart' as pointy;

class Wallet {
  final String id;
  final String name;
  final String privateKey;
  final String publicKey;

  Wallet({
    required this.id,
    required this.name,
    required this.privateKey,
    required this.publicKey,
  });

  static Future<Wallet> generateNew(String nome) async {
    var uuid = const Uuid();
    String name = nome;

    final keyPair = generateRSAkeyPair(getSecureRandom());
    final publicKey = keyPair.publicKey as pointy.RSAPublicKey;
    final privateKey = keyPair.privateKey as pointy.RSAPrivateKey;

    String privateKeyString = privateKeyToString(privateKey);
    String publicKeyString = publicKeyToString(publicKey);


    return Wallet(
      id: uuid.v4(), // Genera un ID univoco
      name: name,
      privateKey: privateKeyString,
      publicKey: publicKeyString,
    );


  }
}
