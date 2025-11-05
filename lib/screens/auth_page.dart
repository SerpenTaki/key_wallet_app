import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:key_wallet_app/services/validators.dart';
import 'package:key_wallet_app/services/i_auth.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final validator = Validator();
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> signIn() async {
    try {
      final authService = context.read<IAuth>();
      await authService.signInWithEmailAndPassword(
        email: _email.text,
        password: _password.text,
      );
    } on FirebaseAuthException {
      ScaffoldMessenger.of(context,).showSnackBar(const SnackBar(content: Text("Credenziali errate")));
    }
  }

  Future<void> createUser() async {
    try {
      final authService = context.read<IAuth>();
      await authService.createUserWithEmailAndPassword(
        email: _email.text,
        password: _password.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utente registrato con successo")),
      );
    } on FirebaseAuthException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore durante la registrazione")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? "Login" : "Registrati",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          heightFactor: 1.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("images/logo.png", width: 60, height: 60),
                    const SizedBox(width: 10),
                    const Text("Key Wallet App", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key("emailField"),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (validator.emailValidator(value) == null) {
                              return null;
                            }
                            return validator.emailValidator(value);
                          },
                          decoration: InputDecoration(
                            label: const Text("Email"),
                            fillColor: Colors.grey[200],
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary,),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          key: const Key("passwordField"),
                          validator: (value) {
                            if (validator.passwordValidator(value) == null) {
                              return null;
                            }
                            return validator.passwordValidator(value);
                          },
                          controller: _password,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            label: const Text("Password"),
                            fillColor: Colors.grey[200],
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary,),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            key: const Key("actionButton"),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                isLogin ? signIn() : createUser();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.inversePrimary,
                            ),
                            child: Text(isLogin ? "Login" : "Registrati"),
                          ),
                        ),
                        TextButton(
                          onPressed: () {setState(() {isLogin = !isLogin;});},
                          child: Text(
                            isLogin ? "Non hai un account? Registrati" : "Hai un account? Accedi",
                            style: TextStyle(color: Theme.of(context).colorScheme.primary,),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
