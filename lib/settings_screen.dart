import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget { // Wiget ustawień
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('O aplikacji'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: "Forum recenzenckie",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2025 Szymon Pawlik",
              );
            },
          ),
        ],
      ),
    );
  }
}
