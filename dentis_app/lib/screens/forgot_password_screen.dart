import 'package:flutter/material.dart';
import '../data/repositories/usuario_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final UsuarioRepository repository = UsuarioRepository();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMsg("Completa todos los campos");
      return;
    }

    if (!email.contains("@")) {
      _showMsg("Ingresa un correo válido");
      return;
    }

    if (password.length < 6) {
      _showMsg("La contraseña debe tener mínimo 6 caracteres");
      return;
    }

    if (password != confirmPassword) {
      _showMsg("Las contraseñas no coinciden");
      return;
    }

    setState(() => loading = true);

    try {
      final ok = await repository.resetPassword(email, password);

      if (!mounted) return;

      setState(() => loading = false);

      if (ok) {
        _showMsg("Contraseña actualizada correctamente");
        Navigator.pop(context);
      } else {
        _showMsg("No se pudo actualizar. Verifica el correo");
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      _showMsg("Error de conexión");
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color azulMate = Color(0xff2F6F88);
    const Color azulMateOscuro = Color(0xff1F4F63);
    const Color campoMate = Color(0xff18323B);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/diente.jpg",
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Container(
            color: Colors.black.withOpacity(.55),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  width: MediaQuery.of(context).size.width > 600
                      ? 500
                      : double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: azulMateOscuro.withOpacity(.86),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          color: azulMateOscuro,
                          size: 55,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "RESTABLECER\nCONTRASEÑA",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Ingresa tu correo y crea una nueva contraseña para volver a entrar al sistema.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _input(
                        controller: emailController,
                        hint: "Correo electrónico",
                        icon: Icons.email_outlined,
                        fillColor: campoMate,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _input(
                        controller: passwordController,
                        hint: "Nueva contraseña",
                        icon: Icons.lock_outline,
                        fillColor: campoMate,
                        obscure: obscurePassword,
                        isPassword: true,
                        onEyePressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _input(
                        controller: confirmPasswordController,
                        hint: "Confirmar contraseña",
                        icon: Icons.lock_outline,
                        fillColor: campoMate,
                        obscure: obscureConfirmPassword,
                        isPassword: true,
                        onEyePressed: () {
                          setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: loading ? null : resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azulMate,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "ACTUALIZAR CONTRASEÑA",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: .5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: const Text(
                          "Volver al Login",
                          style: TextStyle(
                            color: Color(0xff9FC7D3),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color fillColor,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    bool isPassword = false,
    VoidCallback? onEyePressed,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor.withOpacity(.94),
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.white54,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white70,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white70,
                ),
                onPressed: onEyePressed,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
