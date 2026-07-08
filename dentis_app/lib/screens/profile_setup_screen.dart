import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/datasources/session_datasource.dart';
import '../data/repositories/usuario_repository.dart';
import 'home_admin.dart';
import 'home_doctor.dart';
import 'home_user.dart';

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

  static const azul = AppTheme.primary;

  bool get isDoctorProfile {
    final role = widget.user["rol"]?.toString() ?? "usuario";
    return role == "doctor" || role == "admin";
  }

  @override
  void initState() {
    super.initState();
    nombreController.text = widget.user["nombre"]?.toString() ?? "";
    emailController.text = widget.user["email"]?.toString() ?? "";
    telefonoController.text = widget.user["telefono"]?.toString() ?? "";
    if (isDoctorProfile) {
      especialidadController.text =
          widget.user["especialidad"]?.toString() ?? "Odontólogo General";
    }
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
    final password = passwordController.text.trim();

    if (nombre.isEmpty || email.isEmpty || telefono.isEmpty) {
      _msg("Completa nombre, correo y teléfono");
      return;
    }

    setState(() => loading = true);

    final data = {
      "nombre": nombre,
      "email": email,
      "telefono": telefono,
      if (password.isNotEmpty) "password": password,
    };

    if (isDoctorProfile) {
      final especialidad = especialidadController.text.trim();
      data["especialidad"] =
          especialidad.isEmpty ? "Odontólogo General" : especialidad;
    }

    final res = await repository.actualizarPerfil(data);

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

    final role = user["rol"]?.toString() ?? "usuario";
    final Widget page;
    if (role == "admin") {
      page = AdminHome(user: user);
    } else if (role == "doctor") {
      page = DoctorHome(user: user);
    } else {
      page = UserHome(user: user);
    }

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
    final colors = AppColors.of(context);
    final title = isDoctorProfile ? "Completa tu perfil" : "Edita tu perfil";
    final description = isDoctorProfile
        ? "Estos datos aparecerán en el panel y en las citas."
        : "Mantén actualizados tus datos de contacto.";

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: colors.muted, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _input(
                isDoctorProfile ? "Nombre del doctor" : "Nombre completo",
                nombreController,
                Icons.person,
              ),
              _input("Correo", emailController, Icons.email_outlined),
              _input("Teléfono", telefonoController, Icons.phone_outlined),
              if (isDoctorProfile)
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
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: colors.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors.muted),
          prefixIcon: Icon(icon, color: colors.muted),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: () {
                    setState(() => obscurePassword = !obscurePassword);
                  },
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colors.muted,
                  ),
                )
              : null,
          filled: true,
          fillColor: colors.panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
