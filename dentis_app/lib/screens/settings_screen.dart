import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/session_datasource.dart';
import '../services/device_auth_service.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color fondo = Color(0xff08151B);
  static const Color panel = Color(0xff18323B);
  static const Color azul = Color(0xff2F6F88);
  static const Color textoSuave = Color(0xff9FC7D3);
  static const Color rojo = Color(0xffD95B6A);

  final picker = ImagePicker();
  bool deviceAuth = false;
  bool lightMode = false;
  String? photoPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = await SessionDataSource.isDeviceAuthEnabled();

    if (!mounted) return;

    setState(() {
      deviceAuth = enabled;
      lightMode = prefs.getBool("smarttooth_light_mode") ?? false;
      photoPath = prefs.getString(_photoKey);
    });
  }

  String get _photoKey => "profile_photo_${widget.user["id"] ?? "local"}";

  Future<void> _pickPhoto() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 900,
    );

    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoKey, image.path);

    if (!mounted) return;
    setState(() => photoPath = image.path);
  }

  Future<void> _toggleDeviceAuth(bool value) async {
    if (value) {
      final ok = await DeviceAuthService.authenticate();
      if (!ok) {
        _msg("No se pudo activar la verificación del dispositivo");
        return;
      }
    }

    await SessionDataSource.setDeviceAuthEnabled(value);
    if (!mounted) return;
    setState(() => deviceAuth = value);
  }

  Future<void> _toggleLightMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("smarttooth_light_mode", value);
    if (!mounted) return;
    setState(() => lightMode = value);
  }

  Future<void> _logout() async {
    await SessionDataSource.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileSetupScreen(user: widget.user)),
    );
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.user["nombre"]?.toString() ?? "Usuario";
    final email = widget.user["email"]?.toString() ?? "Sin correo";

    return Scaffold(
      backgroundColor: lightMode ? const Color(0xffEDF5F7) : fondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: lightMode ? fondo : Colors.white,
        elevation: 0,
        title: const Text("Ajustes"),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _box(),
            child: Row(
              children: [
                InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(34),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: azul,
                    backgroundImage: photoPath != null && File(photoPath!).existsSync()
                        ? FileImage(File(photoPath!))
                        : null,
                    child: photoPath == null
                        ? Text(
                            nombre.isEmpty ? "S" : nombre[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: lightMode ? fondo : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: textoSuave),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Toca la foto para cambiarla",
                        style: TextStyle(
                          color: lightMode ? azul : textoSuave,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _tile(
            Icons.edit_outlined,
            "Editar perfil y contraseña",
            "Nombre, teléfono, especialidad y clave",
            _editProfile,
          ),
          _switchTile(
            Icons.fingerprint,
            "Entrada con huella, rostro, PIN o patrón",
            "Usa la seguridad configurada en tu teléfono",
            deviceAuth,
            _toggleDeviceAuth,
          ),
          _switchTile(
            Icons.light_mode_outlined,
            "Modo claro",
            "Guarda tu preferencia visual",
            lightMode,
            _toggleLightMode,
          ),
          _tile(
            Icons.logout,
            "Cerrar sesión",
            "Salir de SmartTooth",
            _logout,
            danger: true,
          ),
        ],
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger ? rojo : azul;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .18),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: lightMode ? fondo : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: textoSuave, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: danger ? rojo : textoSuave),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: _box(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: azul.withValues(alpha: .18),
            child: Icon(icon, color: azul),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: lightMode ? fondo : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: textoSuave, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, activeColor: azul, onChanged: onChanged),
        ],
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: lightMode ? Colors.white : panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
      boxShadow: lightMode
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: .06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );
  }
}
