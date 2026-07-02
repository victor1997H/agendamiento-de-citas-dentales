import 'package:flutter/material.dart';
import 'login_screen.dart';

class UserHome extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserHome({super.key, required this.user});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int selectedIndex = 0;

  static const Color fondo = Color(0xff08151B);
  static const Color panel = Color(0xff102832);
  static const Color panelClaro = Color(0xff18323B);
  static const Color azulMate = Color(0xff2F6F88);
  static const Color azulPrincipal = Color(0xff2F6F88);
  static const Color azulOscuro = Color(0xff1F4F63);
  static const Color textoSuave = Color(0xff9FC7D3);
  static const Color rojoSalir = Color(0xffD95B6A);

  void salir() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.user["nombre"] ?? "María García";

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(nombre),
                    const SizedBox(height: 18),
                    _citaPrincipal(),
                    const SizedBox(height: 15),
                    _nuevaCita(),
                    const SizedBox(height: 15),
                    _doctorCard(),
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        "Historial reciente",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _historial(
                      titulo: "Limpieza Dental",
                      fecha: "2026-07-10 10:00",
                      estado: "Confirmada",
                      colorEstado: azulPrincipal,
                    ),
                    _historial(
                      titulo: "Blanqueamiento",
                      fecha: "2026-07-18 14:30",
                      estado: "Pendiente",
                      colorEstado: Color(0xffC78A2D),
                    ),
                    _historial(
                      titulo: "Control Dental",
                      fecha: "2026-07-25 09:00",
                      estado: "Pendiente",
                      colorEstado: Color(0xffC78A2D),
                    ),
                  ],
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _header(String nombre) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bienvenida 👋",
                  style: TextStyle(
                    color: textoSuave,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _circleButton(Icons.notifications_none, azulOscuro, textoSuave),
          const SizedBox(width: 10),
          _circleButton(Icons.person, azulMate, Colors.white),
        ],
      ),
    );
  }

  Widget _citaPrincipal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: azulPrincipal,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🦷 Limpieza Dental",
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Dr. Roberto Méndez",
            style: TextStyle(
              color: Color(0xffD8EEF3),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              _InfoPill(icon: Icons.calendar_today, text: "10 Jul"),
              SizedBox(width: 10),
              _InfoPill(icon: Icons.access_time, text: "10:00 hrs"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nuevaCita() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: azulOscuro,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.add,
              color: textoSuave,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nueva cita",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Ver disponibilidad",
                  style: TextStyle(
                    color: textoSuave,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward,
            color: textoSuave,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _doctorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: azulMate,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TU DOCTOR",
                  style: TextStyle(
                    color: textoSuave,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  "Dr. Roberto Méndez",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Odontólogo General",
                  style: TextStyle(
                    color: textoSuave,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 15),
                    Icon(Icons.star, color: Colors.amber, size: 15),
                    Icon(Icons.star, color: Colors.amber, size: 15),
                    Icon(Icons.star, color: Colors.amber, size: 15),
                    Icon(Icons.star, color: Colors.amber, size: 15),
                    SizedBox(width: 6),
                    Text(
                      "5.0",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _circleButton(Icons.call, azulOscuro, textoSuave),
        ],
      ),
    );
  }

  Widget _historial({
    required String titulo,
    required String fecha,
    required String estado,
    required Color colorEstado,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: azulOscuro,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                "🦷",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  fecha,
                  style: const TextStyle(
                    color: textoSuave,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorEstado.withOpacity(.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              estado,
              style: TextStyle(
                color: colorEstado == azulPrincipal
                    ? const Color(0xff9FC7D3)
                    : const Color(0xffF1B64B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xff061017),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.grid_view_rounded, "Inicio", 0),
          _navItem(Icons.calendar_today_outlined, "Agendar", 1),
          _navItem(Icons.assignment_outlined, "Mis Citas", 2),
          _navItem(Icons.logout, "Salir", 3, isExit: true),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int index, {
    bool isExit = false,
  }) {
    final active = selectedIndex == index;
    final color = isExit
        ? rojoSalir
        : active
            ? textoSuave
            : Colors.white38;

    return GestureDetector(
      onTap: () {
        if (isExit) {
          salir();
          return;
        }

        setState(() {
          selectedIndex = index;
        });
      },
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: active && !isExit ? azulMate : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: active && !isExit ? Colors.white : color,
                size: 23,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, Color bg, Color iconColor) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: panelClaro,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.white.withOpacity(.08),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
