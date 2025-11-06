import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/models/wallet.dart';

void main() {
  group('Wallet Model Test', () {
    test('Wallet.generateNew should create a valid wallet', () async {
      const userId = 'user123';
      const email = 'test@example.com';
      const nome = 'Test Wallet';
      const selectedColor = Colors.blue;
      const hBytes = 'hbytes_test';
      const standard = 'standard_test';
      const device = 'test_device';

      final wallet = await Wallet.generateNew(
        userId, email, nome, selectedColor, hBytes, standard, device);


      expect(wallet, isA<Wallet>());
      expect(wallet.userId, userId);
      expect(wallet.email, email);
      expect(wallet.name, nome);
      expect(wallet.color, selectedColor);
      expect(wallet.hBytes, hBytes);
      expect(wallet.standard, standard);
      expect(wallet.device, device);
      expect(wallet.balance, 0.0);

      expect(wallet.id, isNotEmpty);
      expect(wallet.localKeyIdentifier, isNotEmpty);
      expect(wallet.id, wallet.localKeyIdentifier); // Devono coincidere alla creazione
      expect(wallet.publicKey, isNotEmpty);
      expect(wallet.transientRawPrivateKey, isNotEmpty);
    });

    test('Wallet.fromMap should create a wallet from a map', () {
      final map = {
        'id': 'wallet_id_456',
        'name': 'Wallet from Map',
        'userId': 'user456',
        'email': 'map@example.com',
        'publicKey': 'test_public_key',
        'localKeyIdentifier': 'local_id_456',
        'color': 'alpha: 1.0, red: 0.12, green: 0.34, blue: 0.56',
        'hBytes': 'hbytes_from_map',
        'standard': 'standard_from_map',
        'device': 'device_from_map',
        'balance': 150.75,
      };

      final wallet = Wallet.fromMap(map);

      expect(wallet.id, 'wallet_id_456');
      expect(wallet.name, 'Wallet from Map');
      expect(wallet.userId, 'user456');
      expect(wallet.balance, 150.75);
      final expectedColor = Color.fromRGBO((0.12 * 255).round(), (0.34 * 255).round(), (0.56 * 255).round(), 1.0);
      expect(wallet.color.value, expectedColor.value);
    });

    test('Wallet.fromMap should handle null or missing values with defaults', () {
      final map = {
        'userId': 'user789',
        'email': 'default@example.com',
      };

      final wallet = Wallet.fromMap(map, id: 'wallet_id_789');

      expect(wallet.id, 'wallet_id_789');
      expect(wallet.name, 'Wallet Senza Nome');
      expect(wallet.userId, 'user789');
      expect(wallet.publicKey, '');
      expect(wallet.localKeyIdentifier, '');
      expect(wallet.color, Colors.deepPurpleAccent);
      expect(wallet.hBytes, isNull);
      expect(wallet.standard, isNull);
      expect(wallet.balance, 0.0);
    });


    test('Wallet.fromMap should use default color for null color string', () {
      final map = {
        'id': 'wallet_id_101',
        'name': 'Wallet con colore nullo',
        'userId': 'user101',
        'email': 'nullcolor@example.com',
        'publicKey': 'pk_101',
        'localKeyIdentifier': 'lk_101',
        'color': null,
        'balance': 50.0
      };

      final wallet = Wallet.fromMap(map);
      expect(wallet.color, Colors.deepPurpleAccent);
    });
  });
}
