import 'package:flutter/material.dart';
import '../core/utils/validators.dart';
import '../data/models/usuario_model.dart';
import '../data/repositories/usuario_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final UsuarioRepository repository = UsuarioRepository();

  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _msg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    final validationMessage = Validators.notEmpty(name, "Nombre") ??
        Validators.email(email) ??
        Validators.phone(phone) ??
        Validators.password(password);

    if (validationMessage != null) {
      _msg(validationMessage);
      return;
    }

    if (password != confirmPassword) {
      _msg("Las contraseñas no coinciden");
      return;
    }

    setState(() => loading = true);

    try {
      final usuario = UsuarioModel(
        nombre: name,
        email: email,
        telefono: phone.replaceAll(RegExp(r'[\s()-]'), ''),
        password: password,
      );

      final ok = await repository.registrarUsuario(usuario);

      if (!mounted) return;

      setState(() => loading = false);

      if (ok) {
        _msg("Usuario registrado correctamente");
        Navigator.pop(context);
      } else {
        _msg("Error al registrar usuario");
      }
    } catch (e) {
      setState(() => loading = false);
      _msg("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF071A12),
                  Color(0xFF0B3D2E),
                  Color(0xFF145A32)
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.person_add,
                          size: 70, color: Colors.white),
                      const SizedBox(height: 10),
                      const Text(
                        "CREAR CUENTA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      _input(nameController, "Nombre", Icons.person),
                      const SizedBox(height: 15),
                      _input(emailController, "Correo", Icons.email),
                      const SizedBox(height: 15),
                      _input(phoneController, "Teléfono", Icons.phone),
                      const SizedBox(height: 15),
                      _input(passwordController, "Contraseña", Icons.lock,
                          obscure: true),
                      const SizedBox(height: 15),
                      _input(
                        confirmPasswordController,
                        "Confirmar contraseña",
                        Icons.lock_reset,
                        obscure: true,
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: loading ? null : register,
                          child: loading
                              ? const CircularProgressIndicator()
                              : const Text("REGISTRAR"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (loading)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon,
      {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
