import 'package:flutter/material.dart';
import 'package:bazydanychtest/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Główny kontener logowania
      appBar: AppBar(
        title: const Text('Logowanie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Hasło',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();

                  final success = await _login(email, password, context);
                  if (success && context.mounted) {
                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logowanie nieudane')),
                    );
                  }
                },
                child: const Text('Zaloguj się'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text('Nie masz konta? Zarejestruj się'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/reset');
              },
              child: const Text('Nie pamiętasz hasła?'),
            )

          ],
        ),
      ),
    );
  }

  Future<bool> _login(String email, String password, BuildContext context) async {  // Metoda logująca użytkownika
    try {
      await authService.value.signIn(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Błąd logowania: ${e.message}');
      return false;
    }
  }
}



void _showPasswordResetDialog(BuildContext context) async {  // Metoda wyświetlająca dialog resetujący hasło

  final TextEditingController resetEmailController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Resetuj hasło'),
        content: TextField(
          controller: resetEmailController,
          decoration: const InputDecoration(
            labelText: 'Podaj swój email',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              try {
                await authService.value.resetPassword(email: email);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link resetujący wysłany')),
                );
              } on FirebaseAuthException catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Błąd: ${e.message}')),
                );
              }
            },
            child: const Text('Wyślij'),
          ),
        ],
      );
    },
  );
}


