import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/recover_service.dart';
import 'package:key_wallet_app/services/nfc_services.dart';
import "package:key_wallet_app/services/secure_storage.dart";

class WalletRecoverPage extends StatefulWidget {
  const WalletRecoverPage({super.key, required this.wallet});

  final Wallet wallet;

  @override
  State<WalletRecoverPage> createState() => _WalletRecoverPageState();
}

class _WalletRecoverPageState extends State<WalletRecoverPage> {
  final TextEditingController _privateKeyController = TextEditingController();
  String hBytes = "";
  String standard = "";
  bool _isNfcAvailable = false;
  bool _isScanning = false;
  final SecureStorage secureStorage = SecureStorage();
  bool _isRecoverButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _privateKeyController.addListener(_validateInputs);
    NfcServices().checkAvailability().then((isAvailable) {
      if (mounted) {
        setState(() {
          _isNfcAvailable = isAvailable;
        });
      }
    });
  }

  @override
  void dispose() {
    _privateKeyController.removeListener(_validateInputs);
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> _validateInputs() async {
    if (_privateKeyController.text.isEmpty || hBytes.isEmpty) {
      if (mounted && _isRecoverButtonEnabled) {
        setState(() {
          _isRecoverButtonEnabled = false;
        });
      }
      return;
    }

    final bool isKeyValid = await checkIfRight(
      widget.wallet.publicKey,
      _privateKeyController.text,
    );
    final bool isNfcMatch =
        hBytes == widget.wallet.hBytes && standard == widget.wallet.standard;

    final bool shouldBeEnabled = isKeyValid && isNfcMatch;

    if (mounted && _isRecoverButtonEnabled != shouldBeEnabled) {
      setState(() {
        _isRecoverButtonEnabled = shouldBeEnabled;
      });
    }
  }

  Future<void> _scanNfcTag() async {
    //Da mettere da un altra parte
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
    });

    try {
      dynamic tagData = await NfcServices().fetchNfcData();
      if (tagData != null && mounted) {
        setState(() {
          hBytes = tagData.historicalBytes?.toString() ?? 'N/D';
          standard = tagData.standard?.toString() ?? 'N/D';
          if (hBytes.isNotEmpty &&
              hBytes != 'N/D' &&
              standard.isNotEmpty &&
              standard != 'N/D') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Documento scansionato con successo!"),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Documento non valido per l'operazione"),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
        await _validateInputs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Errore durante la scansione: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recupera Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            spacing: 30,
            children: <Widget>[
              Image.asset("images/logo.png", width: 100, height: 100),
              const Text(
                "Attenzione questa pagina è riservata al recupero di un wallet nel caso di eliminazione della chiave privata, o per aumentare gli accessi ad esso",
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _privateKeyController,
                  maxLines: 7,
                  decoration: InputDecoration(
                    label: const Text('Chiave privata'),
                    fillColor: Colors.grey[200],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    hintText: 'Inserisci la chiave privata',
                  ),
                ),
              ),
              if (_isNfcAvailable)
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanNfcTag,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.nfc_outlined),
                  label: Text(
                    _isScanning ? "Scansione in corso..." : "Scansiona wallet",
                  ),
                )
              else
                const Center(
                  child: Text(
                    "NFC non disponibile su questo dispositivo.",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: _isRecoverButtonEnabled
                    ? () async {
                        await secureStorage.writeSecureData(
                          widget.wallet.localKeyIdentifier,
                          _privateKeyController.text,
                        );
                        if (mounted) Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(390, 50),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.inversePrimary,
                ),
                child: const Text(
                  "Recupera Wallet",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
