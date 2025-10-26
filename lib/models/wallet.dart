import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:key_wallet_app/services/cryptography_gen.dart';
import 'package:pointycastle/asymmetric/api.dart' as pointy;
import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String name;
  final String userId;
  final String publicKey;
  final String localKeyIdentifier;
  String? transientRawPrivateKey;
  Color? color;
  String? hBytes;
  String? standard;
  String? device;
  double? balance;

  Wallet({
    required this.id,
    required this.name,
    required this.userId,
    required this.publicKey,
    required this.localKeyIdentifier,
    this.transientRawPrivateKey,
    required this.color,
    required this.hBytes,
    required this.standard,
    required this.device,
    required this.balance,
  });

  // Factory constructor per creare un'istanza di Wallet da un documento Firestore
  factory Wallet.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Dati mancanti per il documento Wallet con ID: ${doc.id}');
    }
    return Wallet(
      id: doc.id,
      name: data['name'] as String? ?? 'Wallet Senza Nome',
      userId: data['userId'] as String? ?? '',
      publicKey: data['publicKey'] as String? ?? '',
      localKeyIdentifier: data['localKeyIdentifier'] as String? ?? '',
      color: _colorFromString(data['color'] as String?),
      hBytes: data['hBytes'] as String? ?? '',
      standard: data['standard'] as String? ?? '',
      device: data['device'] as String? ?? '',
      balance: data['balance'] as double? ?? 0.0,
    );
  }

  // Factory constructor per creare un'istanza di Wallet da una mappa
  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Wallet Senza Nome',
      userId: map['userId'] as String? ?? '',
      publicKey: map['publicKey'] as String? ?? '',
      localKeyIdentifier: map['localKeyIdentifier'] as String? ?? '',
      color: _colorFromString(map['color'] as String?),
      hBytes: map['hBytes'] as String? ?? '',
      standard: map['standard'] as String? ?? '',
      device: map['device'] as String? ?? '',
      balance: map['balance'] as double? ?? 0.0,
    );
  }

  static Color _colorFromString(String? colorString) {
    if (colorString == null) {
      return Colors.deepPurpleAccent;
    }

    if (colorString.startsWith('Color(') && colorString.endsWith(')')) {
      try {
        final value = int.parse(colorString.substring(8, colorString.length - 1));
        return Color(value);
      } catch (e) { /* non fa nulla, prova il formato successivo */ }
    }

    try {
      var re = RegExp(r'Color\(0x([0-9a-fA-F]+)\)');
      var match = re.firstMatch(colorString);
      if (match != null) {
        final value = int.parse(match.group(1)!, radix: 16);
        return Color(value);
      }
      return Colors.deepPurpleAccent;
    } catch (e) {
      return Colors.deepPurpleAccent;
    }
  }


  static Future<Wallet> generateNew(String userId, String nome, Color selectedColor, String hBytes, String standard, String device) async {
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
