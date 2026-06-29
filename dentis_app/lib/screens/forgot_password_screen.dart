import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();

  void sendRecoveryEmail() {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa tu correo electrónico")),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Se envió un enlace de recuperación a tu correo"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// FONDO MARMOL
          Container(
            width: double.infinity,
            height: double.infinity,

            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fondo.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// CAPA BLANCA
          Container(color: Colors.white.withOpacity(0.78)),

          /// CONTENIDO
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),

                  child: Container(
                    width: MediaQuery.of(context).size.width > 600
                        ? 500
                        : double.infinity,

                    padding: const EdgeInsets.all(28),

                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),

                      borderRadius: BorderRadius.circular(30),

                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 1.3,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        /// LOGO
                        Image.asset("assets/images/logo.png", height: 120),

                        const SizedBox(height: 20),

                        /// TITULO
                        const Text(
                          "RECUPERAR\nCONTRASEÑA",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// TEXTO
                        const Text(
                          "Ingresa tu correo electrónico y te enviaremos un enlace para recuperar tu contraseña.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// EMAIL
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),

                            borderRadius: BorderRadius.circular(18),

                            border: Border.all(color: const Color(0xFFD4AF37)),
                          ),

                          child: TextField(
                            controller: emailController,

                            keyboardType: TextInputType.emailAddress,

                            decoration: const InputDecoration(
                              border: InputBorder.none,

                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.black54,
                              ),

                              hintText: "Correo electrónico",

                              contentPadding: EdgeInsets.symmetric(
                                vertical: 20,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        /// BOTON
                        SizedBox(
                          width: double.infinity,
                          height: 60,

                          child: ElevatedButton(
                            onPressed: sendRecoveryEmail,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),

                              elevation: 5,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),

                            child: const Text(
                              "ENVIAR ENLACE",
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// VOLVER
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Volver al Login",
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
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
          ),
        ],
      ),
    );
  }
}