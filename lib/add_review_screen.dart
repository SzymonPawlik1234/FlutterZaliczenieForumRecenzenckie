import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'services/auth_service.dart';
import 'frequency_response_chart.dart';
import 'services/storage_service.dart';


class AddReviewPage extends StatefulWidget { // Dodawanie recęzji
  const AddReviewPage({super.key});

  @override
  State<AddReviewPage> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewPage> {
  final TextEditingController modelController = TextEditingController();
  final TextEditingController reviewController = TextEditingController();
  final TextEditingController impedanceController = TextEditingController();
  final List<File> _images = [];
  final picker = ImagePicker();

  String? selectedType;
  String? selectedTransducer;
  String? selectedSound;
  String? selectedBrand;

  bool _isLoading = false;
  bool _addFrequencyResponse = false;
  Map<String, double>? _frequencyResponseData;

  Future<void> _addImage() async {  // Funkcja do dodawania zdjęć
    if (_images.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Możesz dodać maksymalnie 10 zdjęć')),
      );
      return;
    }
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Widget _buildImages() { // Metoda tworząca widget zawierający zdjęcia
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_images.length, (index) {
        return Stack(
          children: [
            Image.file(
              _images[index],
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _images.removeAt(index);
                  });
                },
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _saveReview() async {  // Funkcja zapusu rezęzji
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Musisz być zalogowany, aby dodać recenzję')),
      );
      return;
    }

    if (_addFrequencyResponse && (_frequencyResponseData == null || _frequencyResponseData!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dodaj dane Frequency Response')),
      );
      return;
    }

    final String userName = user.displayName?.trim() ?? '';
    final String userEmail = user.email?.trim() ?? '';

    final Map<String, String> userData = {};
    if (userName.isNotEmpty) userData['name'] = userName;
    if (userEmail.isNotEmpty) userData['email'] = userEmail;

    final model = modelController.text.trim();
    final reviewText = reviewController.text.trim();
    final impedance = impedanceController.text.trim();

    if (model.isEmpty ||
        reviewText.isEmpty ||
        impedance.isEmpty ||
        selectedType == null ||
        selectedTransducer == null ||
        selectedSound == null ||
        selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wypełnij wszystkie pola')),
      );
      return;
    }

    final impedanceValue = int.tryParse(impedance);
    if (impedanceValue == null || impedanceValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj poprawną dodatnią wartość impedancji')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final DatabaseReference reviewsRef = FirebaseDatabase.instance.ref().child('reviews');
      final newReviewRef = reviewsRef.push();
      final reviewId = newReviewRef.key!;

      List<Map<String, dynamic>>? frList;
      if (_addFrequencyResponse && _frequencyResponseData != null) {
        final entries = _frequencyResponseData!.entries.toList()
          ..sort((a, b) {
            final fa = double.tryParse(a.key) ?? 0.0;
            final fb = double.tryParse(b.key) ?? 0.0;
            return fa.compareTo(fb);
          });

        frList = entries
            .map((e) => {'frequency': e.key, 'value': e.value})
            .toList();
      }

      final reviewData = {
        'userId': user.uid,
        'user': userData,
        'model': model,
        'review': reviewText,
        'timestamp': ServerValue.timestamp,
        'type': selectedType,
        'transducer': selectedTransducer,
        'impedance': '$impedanceValue Ω',
        'sound': selectedSound,
        'brand': selectedBrand,
        'frequencyResponse': frList,
      };

      await newReviewRef.set(reviewData);

      if (_images.isNotEmpty) {
        final storageService = StorageService();
        List<String> imageUrls = [];
        for (int i = 0; i < _images.length; i++) {
          final url = await storageService.uploadReviewImage(
            image: _images[i],
            reviewId: reviewId,
            index: i,
          );
          imageUrls.add(url);
        }
        await newReviewRef.child("images").set(imageUrls);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recenzja dodana!')),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd zapisu: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDropdown<T>({  // Budowa formularza, dropdowny itp.
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(labelText: label),
      value: value,
      items: items
          .map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(item.toString()),
      ))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Pole wymagane' : null,
    );
  }

  @override
  void dispose() {
    modelController.dispose();
    reviewController.dispose();
    impedanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headphoneBrands = [
      'Sony', 'Bose', 'Bowers And Wilkins', 'Sennheiser', 'AKG',
      'Audio-Technica', 'Beyerdynamic', 'Shure', 'Focal', 'Philips',
      'Pioneer', 'Grado', 'Koss', 'Bang & Olufsen', 'Marshall',
      'JBL', 'Skullcandy', 'Technics', 'Razer', 'HyperX',
      'SteelSeries', 'Plantronics', 'Edifier', 'Audeze', 'Hifiman',
      'Campfire Audio', 'Inna'
    ];

    return Scaffold(  // Wywołanie formularza
      appBar: AppBar(title: const Text('Dodaj Recenzję')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildDropdown<String>(
                label: 'Marka',
                value: selectedBrand,
                items: headphoneBrands,
                onChanged: (val) => setState(() => selectedBrand = val),
              ),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Model słuchawek'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(labelText: 'Rezenzja'),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addImage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Dodaj zdjęcie"),
              ),
              const SizedBox(height: 16),
              _buildImages(),
              const SizedBox(height: 16),
              _buildDropdown<String>(
                label: 'Typ',
                value: selectedType,
                items: const ['przewodowe', 'bezprzewodowe'],
                onChanged: (val) => setState(() => selectedType = val),
              ),
              const SizedBox(height: 16),
              _buildDropdown<String>(
                label: 'Rodzaj przetwornika',
                value: selectedTransducer,
                items: const ['Dynamiczny', 'Planarny', 'Elektrostatyczny'],
                onChanged: (val) => setState(() => selectedTransducer = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: impedanceController,
                decoration: const InputDecoration(labelText: 'Impedancja (Ω)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              _buildDropdown<String>(
                label: 'Brzmienie',
                value: selectedSound,
                items: const ['Ciepłe', 'Neutralne', 'V-shape', 'Jasne', 'Inne'],
                onChanged: (val) => setState(() => selectedSound = val),
              ),
              SwitchListTile(
                title: const Text("Dodaj wykres Frequency Response"),
                value: _addFrequencyResponse,
                onChanged: (v) {
                  setState(() {
                    _addFrequencyResponse = v;
                    if (!v) _frequencyResponseData = null;
                  });
                },
              ),
              if (_addFrequencyResponse)
                FrequencyResponseChart(
                  onDataChanged: (data) => _frequencyResponseData = data,
                ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _saveReview,
                child: const Text('Dodaj recenzję'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
