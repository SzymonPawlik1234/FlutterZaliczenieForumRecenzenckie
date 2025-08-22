import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import '../services/storage_service.dart';

class EditReviewPage extends StatefulWidget { //Wiget do edycji istniejących recenzji
  final String reviewKey;
  final Map review;

  const EditReviewPage({super.key, required this.reviewKey, required this.review});

  @override
  State<EditReviewPage> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends State<EditReviewPage> { //Zawiera zmienne do zmiany formularza recenzji
  final picker = ImagePicker();
  final modelController = TextEditingController();
  final reviewController = TextEditingController();
  final impedanceController = TextEditingController();

  String selectedType = '';
  String selectedTransducer = '';
  String selectedSound = '';
  String selectedBrand = '';
  bool _isLoading = false;

  final List<File> _newImages = [];             // Nowe pliki lokalne
  final List<String> _existingImages = [];      // URL z Firebase
  final List<String> _imagesToDelete = [];      // URL do usunięcia

  @override
  void initState() {
    super.initState();
    _loadReviewData();
  }

  void _loadReviewData() { //Wczytuję istniejące dane
    modelController.text = widget.review['model'] ?? '';
    reviewController.text = widget.review['review'] ?? '';
    impedanceController.text = widget.review['impedance']?.toString().replaceAll("Ω", "").trim() ?? '';

    selectedType = widget.review['type'] ?? '';
    selectedTransducer = widget.review['transducer'] ?? '';
    selectedSound = widget.review['sound'] ?? '';
    selectedBrand = widget.review['brand'] ?? '';

    if (widget.review['images'] != null) {
      _existingImages.addAll(List<String>.from(widget.review['images']));
    }
  }

  Future<void> _addImage() async { // Dodaje zdjęcia do listy
    if (_newImages.length + _existingImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Możesz dodać maksymalnie 10 zdjęć')),
      );
      return;
    }

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _newImages.add(File(pickedFile.path)));
    }
  }

  void _removeExistingImage(int index) { // Usuwa zdjęcie z istnejacych obrazów
    setState(() {
      _imagesToDelete.add(_existingImages[index]);
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) { // Usuwa zdjęcie z nowych obrazów
    setState(() => _newImages.removeAt(index));
  }

  Widget _buildImages() { // Zawiera widżety dla obrazów, które można usuwać klikając na ikonę zamknięcia.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Istniejące zdjęcia (URL)
        for (int i = 0; i < _existingImages.length; i++)
          Stack(
            children: [
              Image.network(
                _existingImages[i],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => _removeExistingImage(i),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

        // Nowe zdjęcia
        for (int i = 0; i < _newImages.length; i++)
          Stack(
            children: [
              Image.file(
                _newImages[i],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => _removeNewImage(i),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _updateReview() async { // Funkcja aktualizuąca dane
    setState(() => _isLoading = true);

    try {
      final reviewRef = FirebaseDatabase.instance.ref().child('reviews').child(widget.reviewKey);

      final updatedData = {
        'model': modelController.text.trim(),
        'review': reviewController.text.trim(),
        'type': selectedType,
        'transducer': selectedTransducer,
        'impedance': '${impedanceController.text.trim()} Ω',
        'sound': selectedSound,
        'brand': selectedBrand,
      };

      await reviewRef.update(updatedData);

      final storageService = StorageService();

      // Usuń zdjęcia ze storage
      for (final url in _imagesToDelete) {
        await storageService.deleteImageByUrl(url);
      }

      // Upload nowych zdjęć
      List<String> newUrls = [];
      for (int i = 0; i < _newImages.length; i++) {
        final url = await storageService.uploadReviewImage(
          image: _newImages[i],
          reviewId: widget.reviewKey,
          index: _existingImages.length + i,
        );
        newUrls.add(url);
      }

      // Finalna lista
      final allImages = [..._existingImages, ...newUrls];
      await reviewRef.child("images").set(allImages);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recenzja zaktualizowana!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd aktualizacji: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edytuj recenzję")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: modelController,
              decoration: const InputDecoration(labelText: "Model"),
            ),
            TextField(
              controller: reviewController,
              decoration: const InputDecoration(labelText: "Recenzja"),
              maxLines: 5,
            ),
            TextField(
              controller: impedanceController,
              decoration: const InputDecoration(labelText: "Impedancja (Ω)"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),
            const Text("Zdjęcia"),
            const SizedBox(height: 8),
            _buildImages(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addImage,
              icon: const Icon(Icons.add),
              label: const Text("Dodaj zdjęcie"),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateReview,
              child: const Text("Zapisz zmiany"),
            )
          ],
        ),
      ),
    );
  }
}
