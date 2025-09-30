import 'dart:convert'; // Per base64Encode e base64Decode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Per Clipboard
import 'package:key_wallet_app/services/cryptography_gen.dart';
import 'package:pointycastle/asymmetric/api.dart' as pointy;

class RsaTestPage extends StatefulWidget {
  final String? initialPublicKeyString;
  final String? initialPrivateKeyString;

  const RsaTestPage({
    super.key,
    this.initialPublicKeyString,
    this.initialPrivateKeyString,
  });

  @override
  State<RsaTestPage> createState() => _RsaTestPageState();
}

class _RsaTestPageState extends State<RsaTestPage> {
  final _privateKeyController = TextEditingController();
  final _publicKeyController = TextEditingController();
  final _plainTextController = TextEditingController(text: "Ciao");
  final _processedTextController = TextEditingController();
  final _recoveredTextController = TextEditingController();

  pointy.RSAPrivateKey? _currentPrivateKey;
  pointy.RSAPublicKey? _currentPublicKey;
  Uint8List? _currentProcessedData;

  @override
  void initState() {
    super.initState();
    if (widget.initialPublicKeyString != null) {
      _publicKeyController.text = widget.initialPublicKeyString!;
      _currentPublicKey = publicKeyFromString(widget.initialPublicKeyString!);
    }
    if (widget.initialPrivateKeyString != null) {
      _privateKeyController.text = widget.initialPrivateKeyString!;
      _currentPrivateKey = privateKeyFromString(widget.initialPrivateKeyString!);
    }
  }

  void _generateKeys() {
    final secureRandom = getSecureRandom();
    final keyPair = generateRSAkeyPair(secureRandom);

    _currentPrivateKey = keyPair.privateKey as pointy.RSAPrivateKey;
    _currentPublicKey = keyPair.publicKey as pointy.RSAPublicKey;

    _privateKeyController.text = privateKeyToString(_currentPrivateKey!);
    _publicKeyController.text = publicKeyToString(_currentPublicKey!);

    _processedTextController.clear();
    _recoveredTextController.clear();
    _currentProcessedData = null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nuova coppia di chiavi RSA generata!')),
    );
  }

  Future<void> _encryptWithPublicKey() async {
    if (_currentPublicKey == null && _publicKeyController.text.isNotEmpty) {
      _currentPublicKey = publicKeyFromString(_publicKeyController.text);
    }
    if (_currentPublicKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna chiave pubblica valida disponibile.')),
      );
      return;
    }

    final encrypted =
    await rsaEncrypt(_plainTextController.text, _currentPublicKey!);

    if (encrypted != null) {
      setState(() {
        _currentProcessedData = encrypted;
        _processedTextController.text = base64Encode(encrypted);
        _recoveredTextController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Testo cifrato con chiave pubblica!')),
      );
    }
  }

  Future<void> _decryptWithPrivateKey() async {
    if (_currentPrivateKey == null && _privateKeyController.text.isNotEmpty) {
      _currentPrivateKey = privateKeyFromString(_privateKeyController.text);
    }
    if (_currentPrivateKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna chiave privata valida disponibile.')),
      );
      return;
    }

    if (_currentProcessedData == null &&
        _processedTextController.text.isNotEmpty) {
      try {
        _currentProcessedData = base64Decode(_processedTextController.text);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Testo cifrato non valido.')),
        );
        return;
      }
    }

    if (_currentProcessedData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun dato cifrato da decifrare.')),
      );
      return;
    }

    final decrypted =
    await rsaDecrypt(_currentProcessedData!, _currentPrivateKey!);

    if (decrypted != null) {
      setState(() {
        _recoveredTextController.text = decrypted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Testo decifrato con chiave privata!')),
      );
    }
  }

  Widget _buildKeyTextField(
      TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            if (controller.text.isNotEmpty) {
              Clipboard.setData(ClipboardData(text: controller.text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label copiata negli appunti!')),
              );
            }
          },
        ),
      ),
      maxLines: 3,
      style: const TextStyle(fontSize: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: _generateKeys,
              child: const Text('1. Genera Nuova Coppia di Chiavi RSA'),
            ),
            const SizedBox(height: 12),
            _buildKeyTextField(_privateKeyController, 'Chiave Privata', 'Genera o incolla la chiave privata'),
            const SizedBox(height: 12),
            _buildKeyTextField(_publicKeyController, 'Chiave Pubblica', 'Genera o incolla la chiave pubblica'),
            const SizedBox(height: 20),
            TextField(
              controller: _plainTextController,
              decoration: const InputDecoration(
                labelText: 'Testo in Chiaro',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _encryptWithPublicKey,
              child: const Text('2. Cifra con Chiave Pubblica'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _processedTextController,
              decoration: const InputDecoration(
                labelText: 'Testo Cifrato (Base64)',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _decryptWithPrivateKey,
              child: const Text('3. Decifra con Chiave Privata'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _recoveredTextController,
              decoration: const InputDecoration(
                labelText: 'Testo Decifrato',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }
}
