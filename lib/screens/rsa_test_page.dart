import 'dart:convert'; // Per base64Encode e base64Decode
import 'dart:typed_data';
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
      // Tentativo di parsare la chiave pubblica iniziale
      _currentPublicKey = publicKeyFromString(widget.initialPublicKeyString!);
      if (_currentPublicKey == null) {
        // Opzionale: notifica all'utente se la chiave iniziale non è valida
        // Non uso ScaffoldMessenger qui perché initState potrebbe essere troppo presto
        print("Avviso: Chiave pubblica iniziale fornita non valida.");
      }
    }
    if (widget.initialPrivateKeyString != null) {
      _privateKeyController.text = widget.initialPrivateKeyString!;
      // Tentativo di parsare la chiave privata iniziale
      _currentPrivateKey = privateKeyFromString(widget.initialPrivateKeyString!);
      if (_currentPrivateKey == null) {
        print("Avviso: Chiave privata iniziale fornita non valida.");
      }
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

  Future<void> _processWithPrivateKey() async {
    // Se _currentPrivateKey non è impostato, prova a usare il testo del controller
    if (_currentPrivateKey == null && _privateKeyController.text.isNotEmpty) {
      _currentPrivateKey = privateKeyFromString(_privateKeyController.text);
      if (_currentPrivateKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chiave privata non valida nel campo di testo.')),
        );
        return;
      }
    }
    if (_currentPrivateKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna chiave privata valida disponibile. Genera o incolla una chiave.')),
      );
      return;
    }
    if (_plainTextController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci del testo da processare.')),
      );
      return;
    }

    setState(() {
      _processedTextController.clear();
      _recoveredTextController.clear();
      _currentProcessedData = null;
    });

    final processedData = await rsaProcessWithPrivateKey(
        _plainTextController.text, _currentPrivateKey!);

    if (processedData != null) {
      _currentProcessedData = processedData;
      _processedTextController.text = base64Encode(processedData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Testo processato con chiave privata!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore durante il processamento con chiave privata.')),
      );
    }
  }

  Future<void> _processWithPublicKey() async {
    if (_currentPublicKey == null && _publicKeyController.text.isNotEmpty) {
      _currentPublicKey = publicKeyFromString(_publicKeyController.text);
       if (_currentPublicKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chiave pubblica non valida nel campo di testo.')),
        );
        return;
      }
    }
     if (_currentPublicKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna chiave pubblica valida disponibile. Genera o incolla una chiave.')),
      );
      return;
    }
    if (_currentProcessedData == null && _processedTextController.text.isNotEmpty) {
        try {
            _currentProcessedData = base64Decode(_processedTextController.text);
        } catch (e) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Testo processato (Base64) non valido.')),
            );
            return;
        }
    }
    if (_currentProcessedData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun dato processato da recuperare. Processa prima con chiave privata.')),
      );
      return;
    }

    final recoveredText = await rsaProcessWithPublicKey(
        _currentProcessedData!, _currentPublicKey!);

    if (recoveredText != null) {
      _recoveredTextController.text = recoveredText;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Testo recuperato con chiave pubblica!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore durante il recupero con chiave pubblica.')),
      );
    }
  }

  Widget _buildKeyTextField(TextEditingController controller, String label, String hint) {
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
            _buildKeyTextField(_privateKeyController, 'Chiave Privata (Stringa)', 'Genera o incolla la chiave privata'),
            const SizedBox(height: 12),
            _buildKeyTextField(_publicKeyController, 'Chiave Pubblica (Stringa)', 'Genera o incolla la chiave pubblica'),
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
              onPressed: _processWithPrivateKey,
              child: const Text('2. Processa con Chiave Privata (m^d mod n)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _processedTextController,
              decoration: InputDecoration(
                labelText: 'Testo Processato (Base64)',
                border: const OutlineInputBorder(),
                 suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    if (_processedTextController.text.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: _processedTextController.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Testo processato copiato!')),
                      );
                    }
                  },
                ),
              ),
              readOnly: true,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _processWithPublicKey,
              child: const Text('3. Recupera con Chiave Pubblica (c^e mod n)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _recoveredTextController,
              decoration: const InputDecoration(
                labelText: 'Testo Recuperato',
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
