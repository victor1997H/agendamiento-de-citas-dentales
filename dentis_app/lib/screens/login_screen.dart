import 'package:flutter/material.dart';
import '../data/repositories/usuario_repository.dart';
import '../data/datasources/session_datasource.dart';
import 'home_admin.dart';
import 'home_doctor.dart';
import 'home_user.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

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

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future login() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMsg("Completa todos los campos");
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

      SessionDataSource.saveSession(
        newToken: res["token"],
        newUser: user,
      );

      Widget page = rol == "admin"
          ? AdminHome(user: user)
          : rol == "doctor"
              ? DoctorHome(user: user)
              : UserHome(user: user);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e) {
      setState(() => loading = false);
      _showMsg("Error de conexion");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color azulMate = Color(0xff2F6F88);
    const Color campoMate = Color(0xff18323B);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/fondo1.jpg",
            fit: BoxFit.fill,
            alignment: Alignment.center,
          ),
          Container(
            color: Colors.black.withOpacity(.50),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                _waveHeader(topPadding),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
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
                      ),
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "CONTRASENA",
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
                            "Olvidaste tu contrasena?",
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
                const SizedBox(height: 24),
              ],
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

  Widget _waveHeader(double topPadding) {
    const Color azulMateOscuro = Color(0xff1F4F63);

    return SizedBox(
      width: double.infinity,
      height: 385 + topPadding,
      child: ClipPath(
        clipper: LoginWaveClipper(),
        child: CustomPaint(
          painter: LoginContourPainter(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(22, topPadding + 24, 22, 72),
            decoration: BoxDecoration(
              color: azulMateOscuro.withOpacity(.82),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(.16),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 95,
                  height: 95,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(.12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(.26),
                              blurRadius: 24,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      CustomPaint(
                        size: const Size(66, 76),
                        painter: ToothPainter(
                          color: azulMateOscuro,
                          shineColor: Colors.white.withOpacity(.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "SmartTooth",
                  textAlign: TextAlign.center,
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
                    color: Colors.white.withOpacity(.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Inicia sesion con tu cuenta",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    IconData icon,
    Color fillColor, {
    bool obscure = false,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor.withOpacity(.94),
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

class _DiagonalGlow extends StatelessWidget {
  const _DiagonalGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _DiagonalGlowPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _DiagonalGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff1C9B78).withOpacity(.18)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(-60, 0)
      ..lineTo(size.width * .25, 0)
      ..lineTo(size.width * .68, size.height)
      ..lineTo(size.width * .45, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height * .80);
    path.cubicTo(
      size.width * .23,
      size.height * .70,
      size.width * .43,
      size.height * .99,
      size.width * .68,
      size.height * .85,
    );
    path.cubicTo(
      size.width * .84,
      size.height * .78,
      size.width * .94,
      size.height * .84,
      size.width,
      size.height * .74,
    );
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class LoginContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    for (int i = 0; i < 9; i++) {
      final path = Path();
      final top = 22.0 + (i * 28);

      path.moveTo(-34, top);
      path.cubicTo(
        size.width * .20,
        top - 36,
        size.width * .34,
        top + 46,
        size.width * .58,
        top + 4,
      );
      path.cubicTo(
        size.width * .80,
        top - 28,
        size.width * .92,
        top + 34,
        size.width + 34,
        top,
      );

      canvas.drawPath(path, paint);
    }

    final ovalPaint = Paint()
      ..color = Colors.white.withOpacity(.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;

    for (int i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .55, 80 + (i * 19)),
          width: 90 + (i * 36),
          height: 42 + (i * 22),
        ),
        ovalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ToothPainter extends CustomPainter {
  final Color color;
  final Color shineColor;

  ToothPainter({
    required this.color,
    required this.shineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final toothPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(.18)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final shinePaint = Paint()
      ..color = shineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    final tooth = Path()
      ..moveTo(w * .30, h * .12)
      ..cubicTo(w * .18, h * .15, w * .11, h * .28, w * .13, h * .43)
      ..cubicTo(w * .15, h * .56, w * .25, h * .64, w * .30, h * .75)
      ..cubicTo(w * .35, h * .87, w * .36, h * .97, w * .45, h * .97)
      ..cubicTo(w * .51, h * .97, w * .49, h * .79, w * .50, h * .70)
      ..cubicTo(w * .51, h * .79, w * .49, h * .97, w * .56, h * .97)
      ..cubicTo(w * .64, h * .97, w * .66, h * .87, w * .70, h * .75)
      ..cubicTo(w * .75, h * .64, w * .85, h * .56, w * .87, h * .43)
      ..cubicTo(w * .89, h * .28, w * .82, h * .15, w * .70, h * .12)
      ..cubicTo(w * .61, h * .10, w * .56, h * .20, w * .50, h * .20)
      ..cubicTo(w * .44, h * .20, w * .39, h * .10, w * .30, h * .12)
      ..close();

    canvas.drawPath(tooth.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawPath(tooth, toothPaint);

    final shine = Path()
      ..moveTo(w * .32, h * .30)
      ..cubicTo(w * .39, h * .24, w * .46, h * .32, w * .50, h * .32)
      ..cubicTo(w * .54, h * .32, w * .61, h * .24, w * .68, h * .30);

    canvas.drawPath(shine, shinePaint);
  }

  @override
  bool shouldRepaint(covariant ToothPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shineColor != shineColor;
  }
}
