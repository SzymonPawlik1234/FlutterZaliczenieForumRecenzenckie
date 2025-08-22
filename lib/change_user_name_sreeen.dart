import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:bazydanychtest/services/auth_service.dart';

class ChangeUsernamePage extends StatefulWidget {
  const ChangeUsernamePage({super.key});

  @override
  State<ChangeUsernamePage> createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<ChangeUsernamePage> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async { // Medota zapisywania zmiany nazwy urzytkownika
    final newUsername = _usernameController.text.trim();

    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wprowadź nową nazwę użytkownika')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Użytkownik niezalogowany");

      final db = FirebaseDatabase.instance.ref();

      // Zmiana w authService
      await authService.value.updateUsername(username: newUsername);

      // Aktualizacja username w komentarzach
      final commentsSnap = await db.child("comments").get();
      if (commentsSnap.exists) {
        for (final review in commentsSnap.children) {
          for (final comment in review.children) {
            final commentUserId = comment.child("userId").value?.toString();
            if (commentUserId == user.uid) {
              await db
                  .child("comments")
                  .child(review.key!) // reviewId
                  .child(comment.key!) // commentId
                  .update({"userName": newUsername});
            }
          }
        }
      }



      // Aktualizacja username w recenzjach
      final reviewsSnap = await db.child("reviews").get();
      if (reviewsSnap.exists) {
        for (final review in reviewsSnap.children) {
          final reviewUserId = review.child("userId").value?.toString();
          if (reviewUserId == user.uid) {
            await db
                .child("reviews")
                .child(review.key!)
                .child("user")
                .update({"name": newUsername});
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nazwa użytkownika została zmieniona')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) { // Medota build tworząca interface
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zmień nazwę użytkownika'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nowa nazwa użytkownika',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveUsername,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Zapisz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
