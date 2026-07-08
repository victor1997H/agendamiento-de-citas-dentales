import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/validators.dart';
import '../data/repositories/usuario_repository.dart';
import '../widgets/auth_background.dart';
import '../widgets/password_requirements.dart';

class ResetCodeScreen extends StatefulWidget {
  final String email;

  const ResetCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetCodeScreen> createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends State<ResetCodeScreen> {
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final passwordFocusNode = FocusNode();
  final UsuarioRepository repository = UsuarioRepository();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String? resetToken;

  bool get codeVerified => resetToken != null;

  @override
  void initState() {
    super.initState();
    passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    passwordFocusNode.dispose();
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

  Future<void> verifyCode() async {
    final code = codeController.text.trim();

    if (code.length != 6) {
      _showMsg("Ingresa el código de 6 dígitos");
      return;
    }

    setState(() => loading = true);

    try {
      final token = await repository.verifyResetCode(widget.email, code);

      if (!mounted) return;

      setState(() {
        loading = false;
        resetToken = token;
      });

      if (token == null) {
        _showMsg("Código incorrecto o vencido");
        return;
      }

      _showMsg("Código verificado");
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _showMsg("Error de conexión");
    }
  }

  Future<void> resendCode() async {
    setState(() => loading = true);

    try {
      final ok = await repository.requestPasswordResetCode(widget.email);

      if (!mounted) return;

      setState(() {
        loading = false;
        resetToken = null;
      });

      if (ok) {
        codeController.clear();
        _showMsg("Código reenviado");
      } else {
        _showMsg("No se pudo reenviar el código");
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _showMsg("Error de conexión");
    }
  }

  Future<void> changePassword() async {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    final validationMessage = Validators.password(password);
    if (validationMessage != null) {
      _showMsg(validationMessage);
      return;
    }

    if (password != confirmPassword) {
      _showMsg("Las contraseñas no coinciden");
      return;
    }

    final token = resetToken;
    if (token == null) {
      _showMsg("Verifica el código primero");
      return;
    }

    setState(() => loading = true);

    try {
      final ok = await repository.resetPassword(
        widget.email,
        token,
        password,
      );

      if (!mounted) return;

      setState(() => loading = false);

      if (!ok) {
        _showMsg("La verificación expiró. Solicita un nuevo código");
        return;
      }

      _showMsg("Contraseña actualizada correctamente");
      Navigator.popUntil(context, (route) => route.isFirst);
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
                  child: AutofillGroup(
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
                            size: 78,
                            toothColor: azulMateOscuro,
                            shineColor: Colors.white.withValues(alpha: .45),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Código de seguridad",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            codeVerified
                                ? "Código verificado. Crea una nueva contraseña segura."
                                : "Ingresa el código de 6 dígitos enviado al correo registrado.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!codeVerified) ...[
                            TextField(
                              controller: codeController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              onSubmitted: (_) {
                                if (!loading) {
                                  verifyCode();
                                }
                              },
                              cursorColor: const Color(0xffB8D8E0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                              decoration: InputDecoration(
                                counterText: "",
                                filled: true,
                                fillColor: campoMate.withValues(alpha: .94),
                                prefixIcon: const Icon(
                                  Icons.verified_user_outlined,
                                  color: Colors.white70,
                                ),
                                hintText: "000000",
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: .24),
                                  letterSpacing: 8,
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
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: loading ? null : verifyCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: azulMate,
                                  disabledBackgroundColor:
                                      azulMate.withValues(alpha: .52),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  "Verificar código",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: loading ? null : resendCode,
                              child: const Text(
                                "Reenviar código",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ] else ...[
                            _input(
                              controller: passwordController,
                              label: "Nueva contraseña",
                              icon: Icons.lock_outline,
                              fillColor: campoMate,
                              obscure: obscurePassword,
                              focusNode: passwordFocusNode,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.newPassword,
                              ],
                              onChanged: (_) => setState(() {}),
                              onTogglePassword: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            PasswordRequirements(
                              password: passwordController.text,
                              visible: passwordFocusNode.hasFocus,
                            ),
                            const SizedBox(height: 14),
                            _input(
                              controller: confirmPasswordController,
                              label: "Confirmar contraseña",
                              icon: Icons.lock_reset_outlined,
                              fillColor: campoMate,
                              obscure: obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.newPassword,
                              ],
                              onSubmitted: loading ? null : changePassword,
                              onTogglePassword: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: loading ? null : changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: azulMate,
                                  disabledBackgroundColor:
                                      azulMate.withValues(alpha: .52),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  "Actualizar contraseña",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed:
                                loading ? null : () => Navigator.pop(context),
                            child: const Text(
                              "Volver",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
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

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color fillColor,
    required bool obscure,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmitted,
    VoidCallback? onTogglePassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      focusNode: focusNode,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      cursorColor: const Color(0xffB8D8E0),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor.withValues(alpha: .94),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: IconButton(
          tooltip: obscure ? "Mostrar contraseña" : "Ocultar contraseña",
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white70,
          ),
          onPressed: onTogglePassword,
        ),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelStyle: const TextStyle(color: Color(0xffB8D8E0)),
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
    );
  }
}
