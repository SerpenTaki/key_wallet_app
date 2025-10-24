import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/contact_service.dart';
import 'package:key_wallet_app/services/chat_service.dart';
import 'package:key_wallet_app/services/validators.dart';
import 'package:key_wallet_app/services/nfc_services.dart';
import 'package:key_wallet_app/screens/chat_page.dart';

class AddContactPage extends StatefulWidget {
  final Wallet senderWallet;
  const AddContactPage({super.key, required this.senderWallet});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final TextEditingController _emailController = TextEditingController();
  final ContactService _contactService = ContactService();
  final ChatService _chatService = ChatService(); // Istanza del ChatService
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String hBytes = "";
  String standard = "";
  bool _isNfcAvailable = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    NfcServices().checkAvailability().then((isAvailable) {
      if (mounted) {
        setState(() {
          _isNfcAvailable = isAvailable;
        });
      }
    });
  }

  Future<void> _scanNfcTag() async {
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

  Future<void> _searchWalletsEmail() async {
    if (_emailController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final results = await _contactService.searchWalletsByEmail(_emailController.text);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore durante la ricerca: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchWalletsNFC() async{
    try{
      final results = await _contactService.searchWalletsByNfc(hBytes, standard);
      setState(() {
        _searchResults = results;
      });
    }catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore durante la ricerca: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aggiungi Contatto', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (_) => _searchWalletsEmail(),
              validator: (value) => emailValidator(value),
              decoration: const InputDecoration(
                labelText: "Email dell'utente",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: _searchWalletsEmail, icon: const Icon(Icons.search), label: const Text('Cerca tramite email')),
            const SizedBox(height: 16),
            if (_isNfcAvailable)
              Row(
                children: [
                  const Text("Cerca tramite NFC"),
                  const SizedBox(width: 30),
                  Column(
                    children: [
                      ElevatedButton.icon(
                      onPressed: _isScanning ? null : _scanNfcTag,
                      icon: _isScanning
                          ? const SizedBox(width: 20, height: 20,
                          child:  CircularProgressIndicator(strokeWidth: 3, color: Colors.white,)) : const Icon(Icons.nfc_outlined),
                      label: Text(_isScanning ? "Scansione in corso..." : "Scansiona documento"),),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(onPressed: _searchWalletsNFC, icon: const Icon(Icons.search), label: const Text('Cerca tramite NFC')),
                    ],
                  ),
                ]
              )
            else 
              const Center(
                  child: Text("NFC non disponibile su questo dispositivo.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
              ),
            const Divider(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_searchResults.isEmpty)
              const Center(child: Text("Nessun wallet trovato"))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final walletData = _searchResults[index];
                    final receiverWallet = Wallet.fromMap(walletData);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(walletData['name'] ?? 'Senza nome'),
                        subtitle: Text("Dispositivo: ${walletData['device']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          onPressed: () async {
                            // --- INIZIO BLOCCO DI DEBUG ---
                            print("DEBUG: ID Utente Mittente -> ${widget.senderWallet.userId}");
                            print("DEBUG: ID Utente Destinatario -> ${receiverWallet.userId}");
                            // --- FINE BLOCCO DI DEBUG ---

                            await _chatService.createConversationIfNotExists(widget.senderWallet, receiverWallet);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  senderWallet: widget.senderWallet,
                                  receiverWallet: receiverWallet,
                                ),
                              ),
                            );
                          },
                          tooltip: 'Inizia a chattare',
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
