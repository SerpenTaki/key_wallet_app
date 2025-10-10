import 'package:flutter/material.dart';

class KeyNotFound extends StatelessWidget {
  const KeyNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chiave privata non trovata!', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),),
            const Text("Riprova da un altro dispositivo", textAlign: TextAlign.center,),
            ElevatedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: const Text("Torna indietro"),
            ),
          ],
        ),
      ),
    );
  }
}
