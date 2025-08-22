import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazydanychtest/services/auth_service.dart';



// Klasa która reprezentuje ekran resetowania hasła użytkownika
class ResetPasswordPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Główny kontener aplikacji
      appBar: AppBar(
        title: const Text("Resetowanie hasła"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Podaj adres e-mail, na który wyślemy link resetujący hasło:",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Podaj adres e-mail")),
                    );
                    return;
                  }

                  try {
                    await authService.value.resetPassword(email: email);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Link resetujący został wysłany"),
                        ),
                      );
                      Navigator.pop(context); // Wraca do logowania
                    }
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Błąd: ${e.message}")),
                    );
                  }
                },
                child: const Text("Wyślij link resetujący"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
