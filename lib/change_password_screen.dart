import 'package:flutter/material.dart';
import 'package:bazydanychtest/services/auth_service.dart';

class ChangePasswordPage extends StatefulWidget { // Klasa zmiany hasła
  const ChangePasswordPage({super.key}); // I konstruktor owej klasy

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;

  Future<void> _changePassword() async { // Metoda zmiany hasła
    final email = emailController.text.trim();
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();

    setState(() => isLoading = true);

    try {
      await authService.value.resetPasswordFromCurrentPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        email: email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hasło zostało zmienione')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) { // Wywołanie wigetu
    return Scaffold(
      appBar: AppBar(title: const Text('Zmień hasło')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Aktualne hasło',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Nowe hasło',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _changePassword,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Zmień hasło'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
