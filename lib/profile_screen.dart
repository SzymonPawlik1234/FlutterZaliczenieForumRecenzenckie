import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget { // Klasa która reprezentuje ekran profilu użytkownika
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Zmień nazwę użytkownika'),
            onTap: () {
              Navigator.pushNamed(context, '/change-username');
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Zmień hasło'),
            onTap: () {
              Navigator.pushNamed(context, '/change-password');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Usuń konto'),
            onTap: () {
              Navigator.pushNamed(context, '/delete-user');
            },
          ),
        ],
      ),
    );
  }
}
