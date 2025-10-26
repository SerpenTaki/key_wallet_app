import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:key_wallet_app/services/cryptography_gen.dart';
import 'package:pointycastle/asymmetric/api.dart' as pointy;
import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String name;
  final String userId;
  final String email;
  final String publicKey;
  final String localKeyIdentifier;
  String? transientRawPrivateKey;
  final Color color;
  final String? hBytes;
  final String? standard;
  final String? device;
  final double balance;

  Wallet({
    required this.id,
    required this.name,
    required this.userId,
    required this.email,
    required this.publicKey,
    required this.localKeyIdentifier,
    this.transientRawPrivateKey,
    required this.color,
    this.hBytes,
    this.standard,
    this.device,
    required this.balance,
  });

  factory Wallet.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Dati mancanti per il documento Wallet con ID: ${doc.id}');
    }
    return Wallet.fromMap(data, id: doc.id);
  }

  factory Wallet.fromMap(Map<String, dynamic> map, {String? id}) {
    return Wallet(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Wallet Senza Nome',
      userId: map['userId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      publicKey: map['publicKey'] as String? ?? '',
      localKeyIdentifier: map['localKeyIdentifier'] as String? ?? '',
      color: _colorFromString(map['color'] as String?),
      hBytes: map['hBytes'] as String?,
      standard: map['standard'] as String?,
      device: map['device'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static Color _colorFromString(String? colorString) {
    if (colorString == null) {
      return Colors.deepPurpleAccent; // Default
    }
    final descriptiveMatch = RegExp(r'alpha: ([\d.]+), red: ([\d.]+), green: ([\d.]+), blue: ([\d.]+)').firstMatch(colorString);
    if (descriptiveMatch != null) {
        final alpha = double.parse(descriptiveMatch.group(1)!);
        final red = double.parse(descriptiveMatch.group(2)!);
        final green = double.parse(descriptiveMatch.group(3)!);
        final blue = double.parse(descriptiveMatch.group(4)!);
        return Color.fromRGBO(
          (red * 255).round(),
          (green * 255).round(),
          (blue * 255).round(),
          alpha,
        );
    }
    return Colors.deepPurpleAccent; // Default finale
  }

  static Future<Wallet> generateNew(
    String userId, String email, String nome, Color selectedColor, 
    String hBytes, String standard, String device
  ) async {
    var uuid = const Uuid();
    final newLocalKeyIdentifier = uuid.v4();

    final keyPair = generateRSAkeyPair(getSecureRandom());
    final publicKeyObj = keyPair.publicKey as pointy.RSAPublicKey;
    final privateKeyObj = keyPair.privateKey as pointy.RSAPrivateKey;

    String privateKeyString = privateKeyToString(privateKeyObj);
    String publicKeyString = publicKeyToString(publicKeyObj);

    return Wallet(
      id: newLocalKeyIdentifier, 
      name: nome,
      userId: userId,
      email: email,
      publicKey: publicKeyString,
      localKeyIdentifier: newLocalKeyIdentifier,
      transientRawPrivateKey: privateKeyString,
      color: selectedColor,
      hBytes: hBytes,
      standard: standard,
      device: device,
      balance: 0.0,
    );
  }
}
