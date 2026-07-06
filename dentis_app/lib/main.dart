import 'package:flutter/material.dart';

import 'data/datasources/session_datasource.dart';
import 'screens/home_admin.dart';
import 'screens/home_doctor.dart';
import 'screens/home_user.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionDataSource.loadSession();
  runApp(const DentisApp());
}

class DentisApp extends StatelessWidget {
  const DentisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartTooth',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Arial',
      ),
      home: _initialHome(),
    );
  }

  Widget _initialHome() {
    if (!SessionDataSource.isLoggedIn) {
      return const LoginScreen();
    }

    final user = SessionDataSource.user;

    if (SessionDataSource.isAdmin) {
      return AdminHome(user: user);
    }

    if (SessionDataSource.isDoctor) {
      return DoctorHome(user: user);
    }

    return UserHome(user: user);
  }
}
