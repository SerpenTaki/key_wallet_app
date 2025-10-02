import 'package:flutter/material.dart';


class NewWalletCreation extends StatefulWidget {
  const NewWalletCreation({super.key});

  @override
  State<NewWalletCreation> createState() => _NewWalletCreationState();
}

class _NewWalletCreationState extends State<NewWalletCreation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Creazione nuovo wallet", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField()
          ]
        )
      ),
    );
  }
}
