import 'package:flutter/material.dart';

import '../core/utils/validators.dart';
import '../data/repositories/usuario_repository.dart';
import '../widgets/auth_background.dart';
import 'reset_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final UsuarioRepository repository = UsuarioRepository();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> sendCode() async {
    final email = emailController.text.trim().toLowerCase();
    final validationMessage = Validators.email(email);

    if (validationMessage != null) {
      _showMsg(validationMessage);
      return;
    }

    setState(() => loading = true);

    try {
      final ok = await repository.requestPasswordResetCode(email);

      if (!mounted) return;

      setState(() => loading = false);

      if (!ok) {
        _showMsg("No se pudo enviar el código");
        return;
      }

      _showMsg("Revisa el correo registrado");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetCodeScreen(email: email),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _showMsg("Error de conexión");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color azulMate = Color(0xff2F6F88);
    const Color azulMateOscuro = Color(0xff1F4F63);
    const Color campoMate = Color(0xff18323B);

    return Scaffold(
      backgroundColor: const Color(0xff02050B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuthBackground(overlayOpacity: .18),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 22,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    decoration: BoxDecoration(
                      color: azulMateOscuro.withValues(alpha: .84),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .28),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AuthBrandMark(
                          size: 82,
                          toothColor: azulMateOscuro,
                          shineColor: Colors.white.withValues(alpha: .45),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Recuperar contraseña",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Ingresa el correo de tu cuenta. Si está registrado, enviaremos un código de seguridad.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 26),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          autocorrect: false,
                          onSubmitted: (_) {
                            if (!loading) {
                              sendCode();
                            }
                          },
                          cursorColor: const Color(0xffB8D8E0),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: campoMate.withValues(alpha: .94),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Colors.white70,
                            ),
                            labelText: "Correo electrónico",
                            labelStyle: const TextStyle(color: Colors.white70),
                            floatingLabelStyle: const TextStyle(
                              color: Color(0xffB8D8E0),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xffB8D8E0),
                                width: 1.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: loading ? null : sendCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: azulMate,
                              disabledBackgroundColor:
                                  azulMate.withValues(alpha: .52),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: loading
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Text(
                                    "Enviar código",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed:
                              loading ? null : () => Navigator.pop(context),
                          child: const Text(
                            "Volver al login",
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (loading)
            Container(
              color: Colors.black.withValues(alpha: .45),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
