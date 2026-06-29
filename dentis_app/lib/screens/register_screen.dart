import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../data/models/usuario_model.dart';
import '../data/repositories/usuario_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final UsuarioRepository repository = UsuarioRepository();
  bool isLoading = false;

  Future register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final usuario = UsuarioModel(
        nombre: name,
        email: email,
        telefono: phone,
        password: password,
      );

      final ok = await repository.registrarUsuario(usuario);

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Usuario registrado")));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No se pudo registrar")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset("assets/images/fondo.jpg", fit: BoxFit.cover),
            ),
            Container(color: Colors.white.withOpacity(0.45)),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - 40),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/images/logo.png", height: 110),
                        const SizedBox(height: 10),

                        const Text(
                          "REGISTRO",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Color(0xFFD4AF37)),
                          ),
                          child: Column(
                            children: [
                              CustomTextField(
                                hint: "Nombre",
                                icon: Icons.person,
                                controller: nameController,
                              ),
                              CustomTextField(
                                hint: "Correo",
                                icon: Icons.email,
                                controller: emailController,
                              ),
                              CustomTextField(
                                hint: "Teléfono",
                                icon: Icons.phone,
                                controller: phoneController,
                              ),
                              CustomTextField(
                                hint: "Contraseña",
                                icon: Icons.lock,
                                controller: passwordController,
                                obscureText: true,
                              ),

                              const SizedBox(height: 15),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF37),
                                  ),
                                  child: isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2,
                                        )
                                      : const Text(
                                          "REGISTRAR",
                                          style: TextStyle(color: Colors.black),
                                        ),
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
          ],
        ),
      ),
    );
  }
}
