import 'package:uuid/uuid.dart';
import 'package:key_wallet_app/services/CryptographyGen.dart';
import 'package:pointycastle/asymmetric/api.dart' as pointy;
import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String name;
  final String publicKey;
  final String localKeyIdentifier;
  String? transientRawPrivateKey;

  Wallet({
    required this.id,
    required this.name,
    required this.publicKey,
    required this.localKeyIdentifier,
    this.transientRawPrivateKey,
  });

  // Factory constructor per creare un'istanza di Wallet da un documento Firestore
  factory Wallet.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Dati mancanti per il documento Wallet con ID: ${doc.id}');
    }
    return Wallet(
      id: doc.id, // Usa l'ID del documento Firestore
      name: data['name'] as String? ?? 'Wallet Senza Nome',
      publicKey: data['publicKey'] as String? ?? '',
      localKeyIdentifier: data['localKeyIdentifier'] as String? ?? '',
    );
  }


  static Future<Wallet> generateNew(String nome) async {
    var uuid = const Uuid();
    final newLocalKeyIdentifier = uuid.v4();

    // Generazione della coppia di chiavi RSA
    final keyPair = generateRSAkeyPair(getSecureRandom());
    final publicKeyObj = keyPair.publicKey as pointy.RSAPublicKey;
    final privateKeyObj = keyPair.privateKey as pointy.RSAPrivateKey;

    // Conversione delle chiavi in stringhe
    String privateKeyString = privateKeyToString(privateKeyObj);
    String publicKeyString = publicKeyToString(publicKeyObj);

    return Wallet(
      id: newLocalKeyIdentifier,
      name: nome,
      publicKey: publicKeyString,
      localKeyIdentifier: newLocalKeyIdentifier,
      transientRawPrivateKey: privateKeyString,
    );
  }
}
