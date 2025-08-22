import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {  // Klasa zawierająca funkcje związane z logowaniem przez firebase
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
}) async {
    return await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> singOut() async {
    await firebaseAuth.signOut();
  }


  Future<void> resetPassword({
    required String email,
  }) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername({
    required String username,
  }) async {
    final user = currentUser;
    if (user != null) {
      await user.updateDisplayName(username);
    } else {
      throw Exception('Brak zalogowanego użytkownika');
    }
  }


  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final user = currentUser;
    if (user != null) {
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
      await user.delete();
      await firebaseAuth.signOut();
    } else {
      throw Exception('Brak zalogowanego użytkownika');
    }
  }


  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final user = currentUser;
    if (user != null) {
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } else {
      throw Exception('Brak zalogowanego użytkownika');
    }
  }












}