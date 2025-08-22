import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class SideMenu extends StatelessWidget { // Wiget bocznego menu
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final user = authService.value.currentUser;

    final String userName = user?.displayName ?? 'Użytkownik';
    final String userEmail = user?.email ?? 'Brak emaila';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ustawienia'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Moje Recenzje'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/see-my-review');
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Wyloguj się'),
            onTap: () async {
              await authService.value.singOut();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
    );
  }
}
