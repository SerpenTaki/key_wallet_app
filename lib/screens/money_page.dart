import 'package:flutter/material.dart';
import 'package:key_wallet_app/widgets/MoneyAlertDialogs/add_money_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';
import 'package:key_wallet_app/models/wallet.dart';

class MoneyPage extends StatefulWidget {
  final Wallet wallet;

  const MoneyPage({super.key, required this.wallet});

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  late double _currentBalance;

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.wallet.balance;
  }

  Future<void> _showAddMoneyDialog() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return const AddMoneyAlertDialog();
      },
    );

    if (amount != null && amount > 0) {
      final newBalance = _currentBalance + amount;
      try {
        await context.read<WalletProvider>().updateBalance(widget.wallet.id, newBalance);
        setState(() => _currentBalance = newBalance);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Errore durante l'aggiornamento del saldo.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                "Saldo Attuale:",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 80),
              Text(
                " ${_currentBalance.toStringAsFixed(2)} €",
                style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 100),
              ElevatedButton(
                onPressed: _showAddMoneyDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  "Aggiungi denaro",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
