import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService { // Klasa związana ze zdjęciami
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Uploaduje zdjęcie i zwraca publiczny URL
  Future<String> uploadReviewImage({
    required File image,
    required String reviewId,
    required int index,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child("review_images")
          .child(reviewId)
          .child("image_$index.jpg");

      final uploadTask = await ref.putFile(image);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception("Błąd podczas zapisu zdjęcia: $e");
    }

  }

  Future<void> deleteImageByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print("Błąd podczas usuwania obrazu: $e");
    }
  }

}
