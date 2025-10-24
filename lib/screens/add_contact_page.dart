import 'package:flutter/material.dart';
import 'package:key_wallet_app/services/validators.dart';
import 'package:key_wallet_app/services/nfc_services.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final TextEditingController _email = TextEditingController();
  String hBytes = "";
  String standard = "";
  bool _isNfcAvailable = false;
  bool _isScanning = false;

  Future<void> _scanNfcTag() async { //da mettere da un altra parte
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
          if (hBytes.isNotEmpty && hBytes != 'N/D' && standard.isNotEmpty && standard != 'N/D') {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Documento scansionato con successo!"), backgroundColor: Colors.green));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Documento non valido per l'operazione"), backgroundColor: Colors.red));
          }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aggiungi contatto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          spacing: 20,
          children: <Widget>[
            const SizedBox(height: 40,),
            const Text(
              "Aggiungi contatto tramite inserimento email",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(9.0),
              child: TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (emailValidator(value) == null) {
                    return null;
                  }
                  return emailValidator(value);
                },
                decoration: InputDecoration(
                  label: const Text("Email dell'utente"),
                  filled: false,
                  border: OutlineInputBorder(),
                  ),
                ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.search),
              label: const Text("Cerca i Wallet dell'utente", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(thickness: 1),
            ),
            const Text(
              "Cerca tramite scansione NFC documento",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_isNfcAvailable)
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanNfcTag,
                icon: _isScanning
                    ? const SizedBox(width: 20, height: 20,
                    child:  CircularProgressIndicator(strokeWidth: 3, color: Colors.white,)) : const Icon(Icons.nfc_outlined),
                label: Text(_isScanning ? "Scansione in corso..." : "Scansiona documento"),)
            else // questo non lo vedo mai
              const Center(
                  child: Text("NFC non disponibile su questo dispositivo.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
              ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.search),
              label: const Text("Cerca i Wallet dell'utente tramite NFC", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
