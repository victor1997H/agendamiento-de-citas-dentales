import 'package:flutter/material.dart';

import '../data/datasources/session_datasource.dart';
import '../data/models/cita_model.dart';
import '../data/repositories/cita_repository.dart';
import 'login_screen.dart';
import 'mis_citas_screen.dart';
import 'nueva_cita_screen.dart';

class UserHome extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserHome({super.key, required this.user});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final CitaRepository repository = CitaRepository();

  int selectedIndex = 0;
  bool loading = true;
  List<CitaModel> citas = [];

  static const Color fondo = Color(0xff08151B);
  static const Color panelClaro = Color(0xff18323B);
  static const Color azulMate = Color(0xff2F6F88);
  static const Color azulPrincipal = Color(0xff2F6F88);
  static const Color azulOscuro = Color(0xff1F4F63);
  static const Color textoSuave = Color(0xff9FC7D3);
  static const Color rojoSalir = Color(0xffD95B6A);

  @override
  void initState() {
    super.initState();
    cargarCitas();
  }

  Future<void> cargarCitas() async {
    setState(() => loading = true);

    final data = await repository.getMisCitas();

    if (!mounted) return;

    setState(() {
      citas = data;
      loading = false;
    });
  }

  Future<void> abrirNuevaCita() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NuevaCitaScreen()),
    );

    if (creada == true) {
      cargarCitas();
    }
  }

  Future<void> abrirMisCitas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MisCitasScreen()),
    );

    cargarCitas();
  }

  void salir() {
    SessionDataSource.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  CitaModel? get proximaCita {
    final activas = citas.where((cita) => !cita.estaCancelada).toList();

    if (activas.isEmpty) return null;

    return activas.first;
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.user["nombre"] ?? "Usuario";

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: cargarCitas,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _historialReciente(),
                    ],
                  ),
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
                  "Bienvenida",
                  style: TextStyle(
                    color: textoSuave,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
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
    final cita = proximaCita;

    return GestureDetector(
      onTap: cita == null ? abrirNuevaCita : abrirMisCitas,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: azulPrincipal,
          borderRadius: BorderRadius.circular(24),
        ),
        child: loading
            ? const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cita?.servicio ?? "Sin citas agendadas",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cita?.doctor ?? "Agenda tu primera cita",
                    style: const TextStyle(
                      color: Color(0xffD8EEF3),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _InfoPill(
                        icon: Icons.calendar_today,
                        text: cita?.fechaResumen ?? "Nueva cita",
                      ),
                      const SizedBox(width: 10),
                      _InfoPill(
                        icon: Icons.access_time,
                        text: cita == null ? "Disponible" : "${cita.horaCorta} hrs",
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _nuevaCita() {
    return GestureDetector(
      onTap: abrirNuevaCita,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration(),
        child: const Row(
          children: [
            Icon(Icons.add, color: textoSuave, size: 38),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nueva cita",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Ver disponibilidad",
                    style: TextStyle(color: textoSuave, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: textoSuave),
          ],
        ),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: azulMate,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.medical_services, color: Colors.white),
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Dr. Roberto Mendez",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Odontologo General",
                  style: TextStyle(color: textoSuave, fontSize: 14),
                ),
              ],
            ),
          ),
          _circleButton(Icons.call, azulOscuro, textoSuave),
        ],
      ),
    );
  }

  Widget _historialReciente() {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (citas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _panelDecoration(),
          child: const Text(
            "Todavia no tienes citas registradas",
            style: TextStyle(color: textoSuave),
          ),
        ),
      );
    }

    return Column(
      children: citas.take(3).map(_historial).toList(),
    );
  }

  Widget _historial(CitaModel cita) {
    final colorEstado = cita.estaCancelada
        ? rojoSalir
        : cita.estaConfirmada
            ? textoSuave
            : const Color(0xffF1B64B);

    return GestureDetector(
      onTap: abrirMisCitas,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        padding: const EdgeInsets.all(15),
        decoration: _panelDecoration(),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: azulOscuro,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.medical_services, color: Colors.white),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cita.servicio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    cita.fechaHoraTexto,
                    style: const TextStyle(color: textoSuave, fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorEstado.withOpacity(.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cita.estado,
                style: TextStyle(
                  color: colorEstado,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xff061017),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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

        if (index == 0) {
          setState(() => selectedIndex = 0);
          cargarCitas();
          return;
        }

        if (index == 1) {
          abrirNuevaCita();
          return;
        }

        if (index == 2) {
          abrirMisCitas();
        }
      },
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: active && !isExit ? azulMate : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: active && !isExit ? Colors.white : color,
                size: 25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _circleButton(IconData icon, Color bg, Color iconColor) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: panelClaro,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withOpacity(.08)),
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
          Icon(icon, color: Colors.white, size: 16),
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