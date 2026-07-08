import 'package:flutter/material.dart';
import '../core/utils/validators.dart';
import '../data/repositories/usuario_repository.dart';
import '../data/datasources/session_datasource.dart';
import '../services/device_auth_service.dart';
import '../widgets/auth_background.dart';
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
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: AutofillGroup(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: azulMateOscuro.withValues(alpha: .82),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            AuthBrandMark(
                              toothColor: azulMateOscuro,
                              shineColor: Colors.white.withValues(alpha: .45),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              "SmartTooth",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Agenda tu cita",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Inicia sesión con tu cuenta",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "CORREO",
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _input(
                        emailController,
                        Icons.email_outlined,
                        campoMate,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                      ),
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "CONTRASEÑA",
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _input(
                        passwordController,
                        Icons.lock_outline,
                        campoMate,
                        obscure: obscurePassword,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: loading ? null : login,
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
                          child: const Text(
                            "¿Olvidaste tu contraseña?",
                            style: TextStyle(
                              color: Color(0xffB8D8E0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: loading ? null : login,
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
                                  "Ingresar al sistema",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      if (!checkingDeviceAuth && canUseDeviceAuth) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: loading ? null : loginWithDeviceAuth,
                            icon: const Icon(Icons.fingerprint),
                            label: const Text(
                                "Entrar con seguridad del dispositivo"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xffB8D8E0),
                              ),
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
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Crear cuenta",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
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
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    IconData icon,
    Color fillColor, {
    bool obscure = false,
    bool isPassword = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    VoidCallback? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      autocorrect: false,
      enableSuggestions: !isPassword,
      onSubmitted: (_) => onSubmitted?.call(),
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor.withValues(alpha: .94),
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
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
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
