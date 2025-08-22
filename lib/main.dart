import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'side_menu.dart';
import 'auth_gate.dart';
import 'change_password_screen.dart';
import 'change_user_name_sreeen.dart';
import 'profile_screen.dart';
import 'delete_user_screen.dart';
import 'add_review_screen.dart';
import 'see_review_screen.dart';
import 'see_my_review_screen.dart';
import 'edit_review-screen.dart';
import 'reset_pasword_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Upewnienie się, że wszystkie wymagane bindingi zostały zainicjalizowane
  await Firebase.initializeApp( // Inicjalizacja Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forum Recenzęckie słuchawek',
      home: const AuthGate(), // Strona główna to brama autoryzacyjna
      routes: { //Ścierzki do poszczegulnych podstron
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsPage(),
        '/profile': (context) => const ProfilePage(),
        '/change-password': (context) => const ChangePasswordPage(),
        '/change-username': (context) => const ChangeUsernamePage(),
        '/delete-user': (context) => const DeleteAccountPage(),
        '/add-review': (context) => const AddReviewPage(),
        '/see-review': (context) => const SeeReviewPage(),
        '/see-my-review': (context) => const SeeMyReviewPage(),
        '/reset': (context) => ResetPasswordPage(),


      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {




  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[


          ],
        ),
      ),
    );
  }
}


