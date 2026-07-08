import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/validators.dart';
import '../data/models/usuario_model.dart';
import '../data/repositories/usuario_repository.dart';
import '../widgets/auth_components.dart';
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
    final colors = AppColors.of(context);

    return AuthScaffold(
      loading: loading,
      overlayOpacity: .12,
      child: AuthCard(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        darkOpacity: .80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthHeader(
              title: "Crear cuenta",
              subtitle: "Completa tus datos",
            ),
            const SizedBox(height: 24),
            AuthTextField(
              controller: nameController,
              label: "Nombre completo",
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              autocorrect: true,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: emailController,
              label: "Correo",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: phoneController,
              label: "Teléfono",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: passwordController,
              label: "Contraseña",
              icon: Icons.lock_outline,
              obscure: obscurePassword,
              isPassword: true,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              focusNode: passwordFocusNode,
              onChanged: (_) => setState(() {}),
              onTogglePassword: () {
                setState(() => obscurePassword = !obscurePassword);
              },
            ),
            const SizedBox(height: 10),
            PasswordRequirements(
              password: passwordController.text,
              visible: passwordFocusNode.hasFocus,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: confirmPasswordController,
              label: "Confirmar contraseña",
              icon: Icons.lock_reset_outlined,
              obscure: obscureConfirmPassword,
              isPassword: true,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: loading ? null : register,
              onTogglePassword: () {
                setState(
                    () => obscureConfirmPassword = !obscureConfirmPassword);
              },
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: "Crear cuenta",
              onPressed: register,
              loading: loading,
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(context),
              child: Text(
                "Ya tengo una cuenta",
                style: TextStyle(color: colors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
