import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/validators.dart';
import '../data/repositories/usuario_repository.dart';
import '../data/datasources/session_datasource.dart';
import '../services/device_auth_service.dart';
import '../widgets/auth_components.dart';
import 'home_admin.dart';
import 'home_doctor.dart';
import 'home_user.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'profile_setup_screen.dart';

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
  bool obscurePassword = true;
  bool canUseDeviceAuth = false;
  bool checkingDeviceAuth = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceAuthState();
  }

  Future<void> _loadDeviceAuthState() async {
    final available = await DeviceAuthService.isAvailable();
    final enabled = await SessionDataSource.canUseDeviceAuthLogin();

    if (!mounted) return;

    setState(() {
      canUseDeviceAuth = available && enabled;
      checkingDeviceAuth = false;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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

  Future<void> login() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    final validationMessage =
        Validators.email(email) ?? Validators.notEmpty(password, "Contraseña");

    if (validationMessage != null) {
      _showMsg(validationMessage);
      return;
    }

    setState(() => loading = true);

    try {
      final res = await repository.login(email, password);

      if (!mounted) return;

      setState(() => loading = false);

      if (res == null || res["token"] == null) {
        _showMsg("Credenciales incorrectas");
        return;
      }

      final user = res["usuario"];
      final rol = user["rol"] ?? "usuario";

      await SessionDataSource.saveSession(
        newToken: res["token"],
        newUser: user,
      );

      _goHome(user, rol);
    } catch (e) {
      setState(() => loading = false);
      _showMsg("Error de conexión");
    }
  }

  Future<void> loginWithDeviceAuth() async {
    setState(() => loading = true);

    final authenticated = await DeviceAuthService.authenticate();
    if (!authenticated) {
      if (!mounted) return;
      setState(() => loading = false);
      _showMsg("No se pudo verificar tu identidad");
      return;
    }

    final restored = await SessionDataSource.restoreLockedSession();
    if (!mounted) return;

    setState(() => loading = false);

    if (!restored) {
      _showMsg("No hay una sesión guardada para restaurar");
      await _loadDeviceAuthState();
      return;
    }

    _goHome(SessionDataSource.user, SessionDataSource.rol);
  }

  void _goHome(Map<String, dynamic> user, String rol) {
    if ((rol == "admin" || rol == "doctor") &&
        user["perfil_completo"] == false) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfileSetupScreen(user: user)),
      );
      return;
    }

    final page = rol == "admin"
        ? AdminHome(user: user)
        : rol == "doctor"
            ? DoctorHome(user: user)
            : UserHome(user: user);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return AuthScaffold(
      loading: loading,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          const AuthCard(
            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 32),
            radius: 35,
            darkOpacity: .82,
            child: AuthHeader(
              title: "SmartTooth",
              subtitle: "Agenda tu cita",
              badge: "Inicia sesión con tu cuenta",
              markSize: 95,
              titleSize: 32,
            ),
          ),
          const SizedBox(height: 40),
          _fieldLabel("CORREO"),
          const SizedBox(height: 8),
          AuthTextField(
            controller: emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.username,
              AutofillHints.email,
            ],
          ),
          const SizedBox(height: 22),
          _fieldLabel("CONTRASEÑA"),
          const SizedBox(height: 8),
          AuthTextField(
            controller: passwordController,
            icon: Icons.lock_outline,
            obscure: obscurePassword,
            isPassword: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: loading ? null : login,
            onTogglePassword: () {
              setState(() => obscurePassword = !obscurePassword);
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: Text(
                "¿Olvidaste tu contraseña?",
                style: TextStyle(color: colors.primary),
              ),
            ),
          ),
          const SizedBox(height: 15),
          AuthPrimaryButton(
            label: "Ingresar al sistema",
            onPressed: login,
            loading: loading,
            height: 58,
          ),
          if (!checkingDeviceAuth && canUseDeviceAuth) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: loading ? null : loginWithDeviceAuth,
                icon: const Icon(Icons.fingerprint),
                label: const Text("Entrar con seguridad del dispositivo"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.text,
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: Text(
              "Crear cuenta",
              style: TextStyle(color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    final colors = AppColors.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: colors.muted,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
