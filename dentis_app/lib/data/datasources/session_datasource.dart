import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionDataSource {
  static const String _tokenKey = 'session_token';
  static const String _userKey = 'session_user';
  static const String _roleKey = 'session_role';
  static const String _lockedKey = 'session_locked';
  static const String _deviceAuthEnabledKey = 'device_auth_enabled';

  static String token = "";
  static String rol = "";
  static Map<String, dynamic> user = {};

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final locked = prefs.getBool(_lockedKey) ?? false;

    if (locked) {
      _clearMemory();
      return;
    }

    _loadFromPrefs(prefs);

    if (token.isNotEmpty && _isTokenExpired(token)) {
      await clear();
    }
  }

  static Future<void> saveSession({
    required String newToken,
    required Map<String, dynamic> newUser,
  }) async {
    token = newToken;
    user = Map<String, dynamic>.from(newUser);
    rol = user["rol"] ?? "";

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
    await prefs.setString(_roleKey, rol);
    await prefs.setBool(_lockedKey, false);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceAuthEnabled = prefs.getBool(_deviceAuthEnabledKey) ?? false;
    final hasStoredSession = (prefs.getString(_tokenKey) ?? "").isNotEmpty;

    if (deviceAuthEnabled && hasStoredSession) {
      await prefs.setBool(_lockedKey, true);
      _clearMemory();
      return;
    }

    await clear();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_lockedKey);
    await prefs.setBool(_deviceAuthEnabledKey, false);
    _clearMemory();
  }

  static Future<bool> restoreLockedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceAuthEnabled = prefs.getBool(_deviceAuthEnabledKey) ?? false;

    if (!deviceAuthEnabled || (prefs.getString(_tokenKey) ?? "").isEmpty) {
      return false;
    }

    _loadFromPrefs(prefs);

    if (token.isNotEmpty && _isTokenExpired(token)) {
      await clear();
      return false;
    }

    await prefs.setBool(_lockedKey, false);
    return isLoggedIn;
  }

  static Future<bool> canUseDeviceAuthLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(_deviceAuthEnabledKey) ?? false) &&
        (prefs.getString(_tokenKey) ?? "").isNotEmpty;
  }

  static Future<bool> isDeviceAuthEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_deviceAuthEnabledKey) ?? false;
  }

  static Future<void> setDeviceAuthEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deviceAuthEnabledKey, enabled);

    if (!enabled) {
      await prefs.setBool(_lockedKey, false);
    }
  }

  static bool get isLoggedIn => token.isNotEmpty;

  static bool get isAdmin => rol == "admin";
  static bool get isDoctor => rol == "doctor";
  static bool get isUser => rol == "usuario";

  static void _loadFromPrefs(SharedPreferences prefs) {
    token = prefs.getString(_tokenKey) ?? "";
    rol = prefs.getString(_roleKey) ?? "";

    final userJson = prefs.getString(_userKey);
    if (userJson == null || userJson.isEmpty) {
      user = {};
      return;
    }

    final decoded = jsonDecode(userJson);
    if (decoded is Map<String, dynamic>) {
      user = decoded;
    } else if (decoded is Map) {
      user = Map<String, dynamic>.from(decoded);
    } else {
      user = {};
    }
  }

  static void _clearMemory() {
    token = "";
    user = {};
    rol = "";
  }

  static bool _isTokenExpired(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) {
        return true;
      }

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload);

      if (data is! Map || data["exp"] == null) {
        return true;
      }

      final exp = data["exp"];
      final expSeconds = exp is int ? exp : int.tryParse(exp.toString());
      if (expSeconds == null) {
        return true;
      }

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expSeconds * 1000,
        isUtc: true,
      );

      return DateTime.now().toUtc().isAfter(expiresAt);
    } catch (_) {
      return true;
    }
  }
}
