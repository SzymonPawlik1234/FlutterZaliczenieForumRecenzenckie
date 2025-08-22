import 'package:bazydanychtest/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Klasa ta reprezentuje ekran rejestracji użytkownika
class RegisterPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                  final success = await register(email, password);
                  if (success && context.mounted) {
                    // Przejście do strony głównej
                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    // Komunikat błędu
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rejestracja nieudana')),
                    );
                  }
                },
                child: const Text('Zarejestruj się'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> register(String email, String password) async {
    try {
      await authService.value.createAccount(email: email, password: password); // Wywołanie metody createAccount z authService do stworzenia nowego konta
      return true;
    } on FirebaseAuthException catch (e) {
      print('Błąd rejestracji: ${e.message}');
      return false;
    }
  }
}
