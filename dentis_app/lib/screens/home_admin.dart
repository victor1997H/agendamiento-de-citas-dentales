import 'package:flutter/material.dart';
import 'login_screen.dart';

class AdminHome extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminHome({super.key, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int selectedIndex = 0;

  static const Color fondo = Color(0xff08151B);
  static const Color panelClaro = Color(0xff18323B);
  static const Color azulMate = Color(0xff2F6F88);
  static const Color azulOscuro = Color(0xff1F4F63);
  static const Color textoSuave = Color(0xff9FC7D3);
  static const Color amarillo = Color(0xffF4B728);
  static const Color verde = Color(0xff2FA884);
  static const Color azulNumero = Color(0xff63A7FF);
  static const Color rosa = Color(0xffFF5FA2);
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
                    _header(),
                    const SizedBox(height: 22),
                    _saludoCard(),
                    const SizedBox(height: 16),
                    _statsGrid(),
                    const SizedBox(height: 16),
                    _chartCard(),
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

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Panel de Control",
                  style: TextStyle(
                    color: textoSuave,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Administrador",
                  style: TextStyle(
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
          _circleButton(Icons.shield, azulMate, Colors.white),
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
            azulMate,
            azulOscuro,
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
            "SmartTooth Admin",
            style: TextStyle(
              color: Color(0xffD8EEF3),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "¡Buen día, Admin!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              _InfoPill(icon: Icons.group_outlined, text: "10 usuarios"),
              SizedBox(width: 10),
              _InfoPill(icon: Icons.shield_outlined, text: "3 doctores"),
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
            titulo: "Total usuarios",
            numero: "10",
            icon: Icons.groups_outlined,
            colorNumero: amarillo,
            colorIcon: amarillo,
          ),
          _statCard(
            titulo: "Doctores",
            numero: "3",
            icon: Icons.medical_services_outlined,
            colorNumero: verde,
            colorIcon: verde,
          ),
          _statCard(
            titulo: "Pacientes",
            numero: "7",
            icon: Icons.person_outline,
            colorNumero: azulNumero,
            colorIcon: azulNumero,
          ),
          _statCard(
            titulo: "Activos",
            numero: "8",
            icon: Icons.monitor_heart_outlined,
            colorNumero: rosa,
            colorIcon: rosa,
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

  Widget _chartCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CITAS POR MES",
            style: TextStyle(
              color: textoSuave,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _BarChartItem(month: "Abr", value: "38", height: 48),
                _BarChartItem(month: "May", value: "52", height: 66),
                _BarChartItem(month: "Jun", value: "45", height: 57),
                _BarChartItem(month: "Jul", value: "31", height: 39),
              ],
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
          _navItem(Icons.grid_view_rounded, "Panel", 0),
          _navItem(Icons.group_outlined, "Usuarios", 1),
          _navItem(Icons.bar_chart_rounded, "Reportes", 2),
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

class _BarChartItem extends StatelessWidget {
  final String month;
  final String value;
  final double height;

  const _BarChartItem({
    required this.month,
    required this.value,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xff9FC7D3),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 62,
            height: height,
            decoration: const BoxDecoration(
              color: Color(0xff2F6F88),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            month,
            style: const TextStyle(
              color: Color(0xff9FC7D3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
