import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:key_wallet_app/services/route_generator.dart';
import 'package:key_wallet_app/services/auth.dart';
import 'package:key_wallet_app/screens/_landing_page.dart';
import 'package:key_wallet_app/screens/_auth_page.dart';
import 'services/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => WalletProvider())],
        child: MyApp(),
    )
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.purpleAccent,
          brightness: Brightness.light,
        ),
      ),
      themeMode: ThemeMode.system, // o ThemeMode.light o ThemeMode.dark
      home: StreamBuilder(
        stream: Auth().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return LandingPage();
          } else {
            return AuthPage();
          }
        },
      ),
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
