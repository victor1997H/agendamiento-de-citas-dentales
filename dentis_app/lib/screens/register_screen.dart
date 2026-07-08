import 'package:flutter/material.dart';

import '../core/utils/validators.dart';
import '../data/models/usuario_model.dart';
import '../data/repositories/usuario_repository.dart';
import '../widgets/auth_background.dart';
import '../widgets/password_requirements.dart';

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
  final confirmPasswordController = TextEditingController();
  final passwordFocusNode = FocusNode();

  final UsuarioRepository repository = UsuarioRepository();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    passwordFocusNode.dispose();
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

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

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
        _msg("Cuenta creada correctamente");
        Navigator.pop(context);
      } else {
        _msg("No se pudo crear la cuenta");
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _msg("Error de conexión");
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
          const AuthBackground(overlayOpacity: .12),
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
                        horizontal: 22,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: azulMateOscuro.withValues(alpha: .80),
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
                          const SizedBox(height: 14),
                          const Text(
                            "Crear cuenta",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Completa tus datos",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _input(
                            nameController,
                            "Nombre completo",
                            Icons.person_outline,
                            campoMate,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                          ),
                          const SizedBox(height: 14),
                          _input(
                            emailController,
                            "Correo",
                            Icons.email_outlined,
                            campoMate,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],
                          ),
                          const SizedBox(height: 14),
                          _input(
                            phoneController,
                            "Teléfono",
                            Icons.phone_outlined,
                            campoMate,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                          ),
                          const SizedBox(height: 14),
                          _input(
                            passwordController,
                            "Contraseña",
                            Icons.lock_outline,
                            campoMate,
                            obscure: obscurePassword,
                            isPassword: true,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            focusNode: passwordFocusNode,
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
                            confirmPasswordController,
                            "Confirmar contraseña",
                            Icons.lock_reset_outlined,
                            campoMate,
                            obscure: obscureConfirmPassword,
                            isPassword: true,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onSubmitted: loading ? null : register,
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: azulMate,
                                disabledBackgroundColor:
                                    azulMate.withValues(alpha: .52),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: loading ? null : register,
                              child: loading
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : const Text(
                                      "Crear cuenta",
                                      style: TextStyle(
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
                              "Ya tengo una cuenta",
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

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon,
    Color fillColor, {
    bool obscure = false,
    bool isPassword = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    TextCapitalization textCapitalization = TextCapitalization.none,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmitted,
    VoidCallback? onTogglePassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      autocorrect: !isPassword,
      enableSuggestions: !isPassword,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      cursorColor: const Color(0xffB8D8E0),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor.withValues(alpha: .94),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                tooltip: obscure ? "Mostrar contraseña" : "Ocultar contraseña",
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white70,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelStyle: const TextStyle(color: Color(0xffB8D8E0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: .08),
          ),
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
