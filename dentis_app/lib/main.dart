import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const DentisApp());
}

class DentisApp extends StatelessWidget {
  const DentisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Tooth',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Arial',
      ),
      home: const LoginScreen(),
    );
  }
}