import 'package:flutter/material.dart';
import 'login_screen.dart';

class DoctorHome extends StatefulWidget {
  final Map<String, dynamic> user;
  const DoctorHome({super.key, required this.user});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  int selectedIndex = 0;

  static const Color fondo = Color(0xff08151B);
  static const Color panel = Color(0xff102832);
  static const Color panelClaro = Color(0xff18323B);
  static const Color azulMate = Color(0xff2F6F88);
  static const Color azulOscuro = Color(0xff1F4F63);
  static const Color textoSuave = Color(0xff9FC7D3);
  static const Color verdeMate = Color(0xff2FA884);
  static const Color amarillo = Color(0xffF4B728);
  static const Color azulNumero = Color(0xff63A7FF);
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
    final nombre = widget.user["nombre"] ?? "Roberto Méndez";

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
                    const SizedBox(height: 22),
                    _saludoCard(),
                    const SizedBox(height: 16),
                    _statsGrid(),
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        "Agenda de hoy",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _citaPaciente(
                      nombre: "María García",
                      detalle: "Limpieza Dental - 45min",
                      hora: "09:00",
                      estado: "Completada",
                    ),
                    _citaPaciente(
                      nombre: "Carlos Ruiz",
                      detalle: "Ortodoncia - 60min",
                      hora: "10:30",
                      estado: "Confirmada",
                    ),
                    _citaPaciente(
                      nombre: "Ana López",
                      detalle: "Blanqueamiento - 50min",
                      hora: "12:00",
                      estado: "Pendiente",
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
                  "Panel Médico",
                  style: TextStyle(
                    color: verdeMate,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Dr. $nombre",
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
          _circleButton(Icons.medical_services, verdeMate, Colors.white),
        ],
      ),
    );
  }

  Widget _saludoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff2FA884),
            Color(0xff1F7F69),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Jueves, 2 de Julio 2026",
            style: TextStyle(
              color: Color(0xffD8EEF3),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "¡Buen día, Doctor!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              _InfoPill(
                  icon: Icons.monitor_heart_outlined, text: "4 citas hoy"),
              SizedBox(width: 10),
              _InfoPill(icon: Icons.access_time, text: "08:00 - 17:00"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          _statCard(
            titulo: "Citas hoy",
            numero: "4",
            icon: Icons.calendar_today_outlined,
            colorNumero: verdeMate,
            colorIcon: verdeMate,
          ),
          _statCard(
            titulo: "Completadas",
            numero: "1",
            icon: Icons.check_circle_outline,
            colorNumero: verdeMate,
            colorIcon: verdeMate,
          ),
          _statCard(
            titulo: "Pendientes",
            numero: "2",
            icon: Icons.hourglass_empty,
            colorNumero: amarillo,
            colorIcon: amarillo,
          ),
          _statCard(
            titulo: "Este mes",
            numero: "47",
            icon: Icons.trending_up,
            colorNumero: azulNumero,
            colorIcon: azulNumero,
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String titulo,
    required String numero,
    required IconData icon,
    required Color colorNumero,
    required Color colorIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: textoSuave,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                icon,
                color: colorIcon,
                size: 18,
              ),
            ],
          ),
          const Spacer(),
          Text(
            numero,
            style: TextStyle(
              color: colorNumero,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _citaPaciente({
    required String nombre,
    required String detalle,
    required String hora,
    required String estado,
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
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detalle,
                  style: const TextStyle(
                    color: verdeMate,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hora,
                style: const TextStyle(
                  color: verdeMate,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: azulMate.withOpacity(.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estado,
                  style: const TextStyle(
                    color: textoSuave,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
          _navItem(Icons.grid_view_rounded, "Panel", 0),
          _navItem(Icons.calendar_today_outlined, "Agenda", 1),
          _navItem(Icons.group_outlined, "Pacientes", 2),
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
                color: active && !isExit ? verdeMate : Colors.transparent,
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
