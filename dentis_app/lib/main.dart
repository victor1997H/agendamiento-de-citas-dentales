import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/session_datasource.dart';
import 'screens/home_admin.dart';
import 'screens/home_doctor.dart';
import 'screens/home_user.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await AppThemeController.load();
  await SessionDataSource.loadSession();
  runApp(const DentisApp());
}

class DentisApp extends StatelessWidget {
  const DentisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppThemeController.lightMode,
      builder: (context, lightMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SmartTooth',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: lightMode ? ThemeMode.light : ThemeMode.dark,
          home: _initialHome(),
        );
      },
    );
  }

  Widget _initialHome() {
    if (!SessionDataSource.isLoggedIn) {
      return const LoginScreen();
    }

    final user = SessionDataSource.user;

    if ((SessionDataSource.isAdmin || SessionDataSource.isDoctor) &&
        user["perfil_completo"] == false) {
      return ProfileSetupScreen(user: user);
    }

    if (SessionDataSource.isAdmin) {
      return AdminHome(user: user);
    }

    if (SessionDataSource.isDoctor) {
      return DoctorHome(user: user);
    }

    return UserHome(user: user);
  }
}
