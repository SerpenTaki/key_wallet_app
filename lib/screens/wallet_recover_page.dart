import 'package:flutter/material.dart';

class WalletRecoverPage extends StatelessWidget {
  const WalletRecoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recupera Wallet', style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20,
          children: <Widget>[
            const Text(
              "Attenzione questa pagina è riservata al recupero di un wallet nel caso di eliminazione della chiave privata, o per aumentare gli accessi ad esso",
              style: TextStyle(
                fontSize: 15
              ),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  label: const Text('Chiave privata'),
                  fillColor: Colors.grey[200],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary,),
                  ),
                  hintText: 'Inserisci la chiave privata',
                ),
              ),
            ),
            ElevatedButton(
                onPressed: (){},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(390, 50),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.inversePrimary,
                ),
                child: const Text("Recupera Wallet", style: TextStyle(fontWeight: FontWeight.bold),)
            ),
          ]
        ),
      ),
    );
  }
}
