import 'package:flutter/material.dart';
import '../data/repositories/usuario_repository.dart';
import '../data/datasources/session_datasource.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final UsuarioRepository repository = UsuarioRepository();

  bool loading = false;

  Future login() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final res = await repository.login(email, password);

      if (!mounted) return;

      setState(() => loading = false);

      if (res != null && res["token"] != null) {
        SessionDataSource.saveSession(
          newToken: res["token"],
          newUser: res["usuario"],
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(user: res["usuario"]),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Credenciales incorrectas")),
        );
      }
    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void recuperarPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Contacta al administrador para recuperar contraseña"),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B3D2E),
              Color(0xFF145A32),
              Color(0xFF1E8449),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Icon(Icons.local_hospital,
                      size: 90, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    "SMARTTOOTH",
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: "Correo electrónico",
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Contraseña",
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: recuperarPassword,
                            child: const Text("¿Olvidaste tu contraseña?"),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: loading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B3D2E),
                            ),
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("INICIAR SESIÓN"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
