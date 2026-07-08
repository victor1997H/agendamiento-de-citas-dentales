import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController {
  static const String preferenceKey = "smarttooth_light_mode";
  static final ValueNotifier<bool> lightMode = ValueNotifier<bool>(false);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    lightMode.value = prefs.getBool(preferenceKey) ?? false;
  }

  static Future<void> setLightMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(preferenceKey, value);
    lightMode.value = value;
  }
}

class AppTheme {
  static const Color darkBackground = Color(0xff08151B);
  static const Color darkPanel = Color(0xff18323B);
  static const Color darkSurface = Color(0xff061017);
  static const Color primary = Color(0xff2F6F88);
  static const Color primaryDark = Color(0xff1F4F63);
  static const Color softText = Color(0xff9FC7D3);
  static const Color danger = Color(0xffD95B6A);

  static const Color lightBackground = Color(0xffEDF5F7);
  static const Color lightPanel = Colors.white;
  static const Color lightSurface = Color(0xffF7FBFC);
  static const Color lightText = Color(0xff10272F);
  static const Color lightMutedText = Color(0xff5A7781);
  static const Color lightBorder = Color(0xffD9E8EC);

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Arial',
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: darkPanel,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: 'Arial',
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: lightPanel,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AppColors {
  final bool isLight;

  const AppColors._(this.isLight);

  factory AppColors.of(BuildContext context) {
    return AppColors._(Theme.of(context).brightness == Brightness.light);
  }

  Color get background =>
      isLight ? AppTheme.lightBackground : AppTheme.darkBackground;
  Color get panel => isLight ? AppTheme.lightPanel : AppTheme.darkPanel;
  Color get surface => isLight ? AppTheme.lightSurface : AppTheme.darkSurface;
  Color get field =>
      isLight ? const Color(0xffE5F0F3) : AppTheme.darkBackground;
  Color get primary => AppTheme.primary;
  Color get primaryDark => AppTheme.primaryDark;
  Color get text => isLight ? AppTheme.lightText : Colors.white;
  Color get muted => isLight ? AppTheme.lightMutedText : AppTheme.softText;
  Color get subtle => isLight ? const Color(0xff7C969F) : Colors.white70;
  Color get border =>
      isLight ? AppTheme.lightBorder : Colors.white.withValues(alpha: .08);
  Color get nav =>
      isLight ? Colors.white.withValues(alpha: .96) : AppTheme.darkSurface;
  Color get danger => AppTheme.danger;

  BoxShadow? get softShadow => isLight
      ? BoxShadow(
          color: Colors.black.withValues(alpha: .06),
          blurRadius: 16,
          offset: const Offset(0, 8),
        )
      : null;
}
