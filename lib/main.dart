import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:key_wallet_app/services/i_auth.dart';
import 'package:key_wallet_app/services/route_generator.dart';
import 'package:key_wallet_app/services/auth.dart';
import 'package:key_wallet_app/screens/landing_page.dart';
import 'package:key_wallet_app/screens/auth_page.dart';
import 'services/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:key_wallet_app/providers/wallet_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    const SnackBar(content: Text('Errore durante l\'inizializzazione di Firebase'));
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WalletProvider()),
          Provider<IAuth>(create: (_) => Auth()), //Fornisce un'unica istanza di autenticazione
        ],
        child: const  MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      themeMode: ThemeMode.system, // o ThemeMode.light o ThemeMode.dark
      home: StreamBuilder(
        stream: context.watch<IAuth>().authStateChanges,
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
