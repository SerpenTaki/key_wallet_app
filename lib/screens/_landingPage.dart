import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:key_wallet_app/providers/auth.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  Future<void> signOut() async {
    await Auth().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                Icon(Icons.account_balance_wallet),
                SizedBox(width: 8),
                Text("Wallet", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              IconButton(
                onPressed: signOut,
                icon: Icon(Icons.logout, size: 25),
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.credit_card),
                    title: Text('Card ${index + 1}'),
                    subtitle: Text('This is a sample card item.'),
                    trailing: Icon(TargetPlatform.android == defaultTargetPlatform ? Icons.arrow_forward : Icons.arrow_forward_ios),
                    onTap: () {
                      // Handle card tap
                    },
                  ),
                );
              },
              childCount: 10, // Replace with your actual item count
            ),
          ),
        ],
        shrinkWrap: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
