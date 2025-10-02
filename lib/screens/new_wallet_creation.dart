import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:key_wallet_app/widgets/color_picker_dialog.dart';
import 'package:key_wallet_app/services/NFC/nfc_fetch_data.dart';

class NewWalletCreation extends StatefulWidget {
  const NewWalletCreation({super.key});

  @override
  State<NewWalletCreation> createState() => _NewWalletCreationState();
}

class _NewWalletCreationState extends State<NewWalletCreation> {
  final _formKey = GlobalKey<FormState>();
  String nome = "";
  Color selectedColor = Colors.deepPurpleAccent;
  String hBytes = "";
  String standard = "";
  String device = Platform.operatingSystem; // Ottiene il sistema operativo del dispositivo
  bool _isNfcAvailable = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    bool isAvailable = await NfcFetchData().checkAvailability();
    if (mounted) {
      setState(() {
        _isNfcAvailable = isAvailable;
      });
    }
  }

  Future<void> _scanNfcTag() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
    });

    try {
      // fetchNfcData restituisce un oggetto di tipo NFCTag, non una mappa.
      dynamic tagData = await NfcFetchData().fetchNfcData();
      if (tagData != null && mounted) {
        // Accediamo alle proprietà dell'oggetto usando la notazione con il punto.
        // Ipotizzando che le proprietà esistano sull'oggetto tagData.
        setState(() {
          hBytes = tagData.historicalBytes?.toString() ?? 'N/D';
          standard = tagData.standard?.toString() ?? 'N/D';
          // Mostra un feedback all'utente
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Wallet scansionato con successo!"), backgroundColor: Colors.green),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore durante la scansione: $e"), backgroundColor: Colors.red),
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
    // Logica per abilitare il pulsante di creazione solo se i dati NFC sono validi.
    final bool canCreateWallet = hBytes.isNotEmpty && hBytes != 'N/D' &&
                                 standard.isNotEmpty && standard != 'N/D';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Creazione nuovo wallet",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Inserisci un nome";
                }
                return null;
              },
              onSaved: (value) {
                nome = value!;
              },
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Nome del nuovo wallet",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return ColorPickerDialog(
                      initialColor: selectedColor,
                      onColorChanged: (Color value) {
                        setState(() {
                          selectedColor = value;
                        });
                      },
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                foregroundColor: selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.color_lens_outlined),
              label: const Text('Seleziona Colore Wallet'),
            ),
            const SizedBox(height: 30),
            if (_isNfcAvailable)
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanNfcTag,
                icon: _isScanning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white,))
                    : const Icon(Icons.nfc_outlined),
                label: Text(_isScanning ? "Scansione in corso..." : "Scansiona wallet"),
              )
            else
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Questo dispositivo non supporta la tecnologia NFC",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            const SizedBox(height: 30),
            // I Text widget si aggiornano automaticamente grazie a setState
            Text("Piattaforma: $device"),
            Text("HBytes: $hBytes"),
            Text("Standard: $standard"),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: canCreateWallet
                  ? () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        // Qui andrà la logica per creare il wallet con i dati raccolti:
                        print("Nome: $nome, Colore: $selectedColor, HBytes: $hBytes, Standard: $standard, Piattaforma: $device");
                        // Esempio: Navigator.pop(context, nuovoWallet);
                      }
                    }
                  : null, // Disabilita il pulsante se i dati NFC non sono stati scansionati
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text("Crea Wallet"),
            )
          ],
        ),
      ),
    );
  }
}
