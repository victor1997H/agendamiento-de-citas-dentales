import 'package:flutter/material.dart';

import '../data/datasources/session_datasource.dart';
import '../data/repositories/usuario_repository.dart';
import 'home_admin.dart';
import 'home_doctor.dart';

class ProfileSetupScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileSetupScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final repository = UsuarioRepository();
  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  final telefonoController = TextEditingController();
  final especialidadController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  static const fondo = Color(0xff08151B);
  static const panel = Color(0xff18323B);
  static const azul = Color(0xff2F6F88);
  static const textoSuave = Color(0xff9FC7D3);

  @override
  void initState() {
    super.initState();
    nombreController.text = widget.user["nombre"]?.toString() ?? "";
    emailController.text = widget.user["email"]?.toString() ?? "";
    telefonoController.text = widget.user["telefono"]?.toString() ?? "";
    especialidadController.text =
        widget.user["especialidad"]?.toString() ?? "Odontólogo General";
  }

  @override
  void dispose() {
    nombreController.dispose();
    emailController.dispose();
    telefonoController.dispose();
    especialidadController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    final nombre = nombreController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final telefono = telefonoController.text.trim();
    final especialidad = especialidadController.text.trim();
    final password = passwordController.text.trim();

    if (nombre.isEmpty || email.isEmpty || telefono.isEmpty) {
      _msg("Completa nombre, correo y teléfono");
      return;
    }

    setState(() => loading = true);

    final res = await repository.actualizarPerfil({
      "nombre": nombre,
      "email": email,
      "telefono": telefono,
      "especialidad": especialidad.isEmpty ? "Odontólogo General" : especialidad,
      if (password.isNotEmpty) "password": password,
    });

    if (!mounted) return;

    setState(() => loading = false);

    if (res == null || res["token"] == null || res["usuario"] == null) {
      _msg("No se pudo guardar el perfil");
      return;
    }

    final user = Map<String, dynamic>.from(res["usuario"]);
    await SessionDataSource.saveSession(
      newToken: res["token"],
      newUser: user,
    );

    if (!mounted) return;

    final page = user["rol"] == "doctor"
        ? DoctorHome(user: user)
        : AdminHome(user: user);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _msg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Completa tu perfil",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Estos datos aparecerán en el panel y en las citas.",
                style: TextStyle(color: textoSuave, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _input("Nombre del doctor", nombreController, Icons.person),
              _input("Correo", emailController, Icons.email_outlined),
              _input("Teléfono", telefonoController, Icons.phone_outlined),
              _input(
                "Especialidad",
                especialidadController,
                Icons.medical_services_outlined,
              ),
              _input(
                "Nueva contraseña opcional",
                passwordController,
                Icons.lock_outline,
                obscure: obscurePassword,
                isPassword: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : guardar,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text("Guardar y continuar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azul,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscure = false,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: textoSuave),
          prefixIcon: Icon(icon, color: textoSuave),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: () {
                    setState(() => obscurePassword = !obscurePassword);
                  },
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textoSuave,
                  ),
                )
              : null,
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
