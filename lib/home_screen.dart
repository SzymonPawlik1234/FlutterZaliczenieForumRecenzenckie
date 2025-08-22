import 'dart:ui';
import 'package:flutter/material.dart';
import 'side_menu.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildBlurButton({   // Funkcja tworząca przycisk z obrazem
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Lekkie rozmycie
                child: Container(
                  color: Colors.black26, // Lekki półprzezroczysty overlay
                ),
              ),
              Center(
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Główny kontener aplikacji
      appBar: AppBar(
        title: const Text('Strona Główna'),
      ),
      drawer: const SideMenu(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBlurButton(
              imagePath: 'assets/images/parametric_eq.jpg',
              label: 'Wyszukaj słuchawki',
              onTap: () => Navigator.pushNamed(context, '/see-review'),
            ),
            const SizedBox(height: 16),
            _buildBlurButton(
              imagePath: 'assets/images/5band_eq.jpg',
              label: 'Dodaj Recenzje',
              onTap: () => Navigator.pushNamed(context, '/add-review'),
            ),
          ],
        ),
      ),
    );
  }
}
