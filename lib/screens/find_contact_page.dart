import 'package:flutter/material.dart';
import 'package:key_wallet_app/models/wallet.dart';
import 'package:key_wallet_app/services/contact_service.dart';
import 'package:key_wallet_app/services/chat_service.dart';
import 'package:key_wallet_app/services/validators.dart';
import 'package:key_wallet_app/services/nfc_services.dart';
import 'package:key_wallet_app/widgets/chatWidgets/user_tile.dart';

class FindContactPage extends StatefulWidget {
  final Wallet senderWallet;

  const FindContactPage({super.key, required this.senderWallet});

  @override
  State<FindContactPage> createState() => _FindContactPageState();
}

class _FindContactPageState extends State<FindContactPage> {
  final TextEditingController _emailController = TextEditingController();
  final ContactService _contactService = ContactService();
  final ChatService _chatService = ChatService();
  final validator = Validator();
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
      _emailController.addListener(() {
        setState(() {});
      });
      if (mounted) {
        setState(() {
          _isNfcAvailable = isAvailable;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
            _searchWalletsNFC();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Documento non valido per l'operazione"),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
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

  Future<void> _searchWalletsEmail() async {
    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final results = await _contactService.searchWalletsByEmail(
        _emailController.text,
      );
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Errore durante la ricerca: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchWalletsNFC() async {
    try {
      final results = await _contactService.searchWalletsByNfc(
        hBytes,
        standard,
      );
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Errore durante la ricerca: $e")));
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
        title: const Text(
          'Cerca/Aggiungi Contatto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .primary,
        foregroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => _searchWalletsEmail(),
                    validator: (value) => validator.emailValidator(value),
                    decoration: const InputDecoration(
                      labelText: "Email dell'utente",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _emailController.text
                      .trim()
                      .isEmpty
                      ? null
                      : _searchWalletsEmail,
                  icon: const Icon(Icons.search),
                  label: const Text('Cerca'),
                ),
              ],
            ),
            const Divider(height: 32),
            if (_isNfcAvailable)
              Row(
                children: [
                  const SizedBox(width: 30),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isScanning ? null : _scanNfcTag,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(300, 50),
                        ),
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
                          _isScanning
                              ? "Scansione in corso..."
                              : "Cerca tramite scansione documento",
                        ),
                      ),
                    ],
                  ),
                ],
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
            const Divider(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              if (_searchResults.isEmpty)
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
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: UserTile(
                            text: walletData["name"],
                            subtext: walletData["email"],
                            color: receiverWallet.color,
                            onTap: () async {
                              await _chatService.createConversationIfNotExists(
                                  widget.senderWallet, receiverWallet);
                              Navigator.pushNamed(context, "/chat", arguments: {
                                "senderWallet": widget.senderWallet,
                                "receiverWallet": receiverWallet,
                              });
                            },
                          )
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