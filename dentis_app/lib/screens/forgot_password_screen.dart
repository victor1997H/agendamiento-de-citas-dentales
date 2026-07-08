import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
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
    final colors = AppColors.of(context);
    const Color azulMate = AppTheme.primary;
    const Color azulMateOscuro = AppTheme.primaryDark;
    const Color campoMate = AppTheme.darkPanel;

    return Scaffold(
      backgroundColor: colors.background,
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
                      color: colors.isLight
                          ? colors.panel.withValues(alpha: .94)
                          : azulMateOscuro.withValues(alpha: .84),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: colors.border),
                      boxShadow: [
                        colors.softShadow ??
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
                          toothColor:
                              colors.isLight ? azulMate : azulMateOscuro,
                          shineColor: colors.isLight
                              ? Colors.white.withValues(alpha: .70)
                              : Colors.white.withValues(alpha: .45),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Recuperar contraseña",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Ingresa el correo de tu cuenta. Si está registrado, enviaremos un código de seguridad.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: colors.muted,
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
                          cursorColor: colors.primary,
                          style: TextStyle(color: colors.text),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.isLight
                                ? colors.field.withValues(alpha: .94)
                                : campoMate.withValues(alpha: .94),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: colors.muted,
                            ),
                            labelText: "Correo electrónico",
                            labelStyle: TextStyle(color: colors.muted),
                            floatingLabelStyle:
                                TextStyle(color: colors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  BorderSide(color: colors.primary, width: 1.3),
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
                          child: Text(
                            "Volver al login",
                            style: TextStyle(
                              color: colors.muted,
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
              color: colors.isLight
                  ? Colors.white.withValues(alpha: .55)
                  : Colors.black.withValues(alpha: .45),
              child: Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
