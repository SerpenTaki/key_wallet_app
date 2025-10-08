import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:key_wallet_app/services/cryptography_gen.dart';
import 'package:pointycastle/asymmetric/api.dart' as pointy;
import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String name;
  final String publicKey;
  final String localKeyIdentifier;
  String? transientRawPrivateKey;
  Color? color;
  String? hBytes;
  String? standard;
  String? device;

  Wallet({
    required this.id,
    required this.name,
    required this.publicKey,
    required this.localKeyIdentifier,
    this.transientRawPrivateKey,
    required this.color,
    required this.hBytes,
    required this.standard,
    required this.device,
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
      // Usa la funzione helper per parsificare il colore dalla stringa
      color: _colorFromString(data['color'] as String?),
      hBytes: data['hBytes'] as String? ?? '',
      standard: data['standard'] as String? ?? '',
      device: data['device'] as String? ?? '',
    );
  }

  // Factory constructor per creare un'istanza di Wallet da una mappa
  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Wallet Senza Nome',
      publicKey: map['publicKey'] as String? ?? '',
      localKeyIdentifier: map['localKeyIdentifier'] as String? ?? '',
      color: _colorFromString(map['color'] as String?),
      hBytes: map['hBytes'] as String? ?? '',
      standard: map['standard'] as String? ?? '',
      device: map['device'] as String? ?? '',
    );
  }

  static Color _colorFromString(String? colorString) {
    if (colorString == null) {
      return Colors.deepPurpleAccent;
    }

    // Cerca di gestire il formato "Color(0xff...)"
    if (colorString.startsWith('Color(') && colorString.endsWith(')')) {
      try {
        final value = int.parse(colorString.substring(8, colorString.length - 1));
        return Color(value);
      } catch (e) { /* non fa nulla, prova il formato successivo */ }
    }

    try {
      // Gestisce il formato "MaterialColor(primary value: Color(0xff...))"
      var re = RegExp(r'Color\(0x([0-9a-fA-F]+)\)');
      var match = re.firstMatch(colorString);
      if (match != null) {
        final value = int.parse(match.group(1)!, radix: 16);
        return Color(value);
      }
      // Se nessun formato corrisponde, restituisce il colore di default
      return Colors.deepPurpleAccent;
    } catch (e) {
      // In caso di errore di parsing, restituisce il colore di default
      return Colors.deepPurpleAccent;
    }
  }


  static Future<Wallet> generateNew(String nome, Color selectedColor, String hBytes, String standard, String device) async {
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
      color: selectedColor, // Usa il colore passato come argomento
      hBytes: hBytes,
      standard: standard,
      device: device,
    );
  }
}
