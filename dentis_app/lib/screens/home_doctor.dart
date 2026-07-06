import 'package:flutter/material.dart';

import '../data/datasources/session_datasource.dart';
import '../data/models/cita_model.dart';
import '../data/repositories/doctor_repository.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class DoctorHome extends StatefulWidget {
  final Map<String, dynamic> user;

  const DoctorHome({super.key, required this.user});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  final DoctorRepository repository = DoctorRepository();

  int selectedIndex = 0;
  bool loading = true;

  List<CitaModel> citasHoy = [];
  List<Map<String, dynamic>> pacientes = [];

  Map<String, dynamic> resumen = {
    "citas_hoy": 0,
    "completadas": 0,
    "pendientes": 0,
    "este_mes": 0,
  };

  static const Color fondo = Color(0xff08151B);
  static const Color panel = Color(0xff18323B);
  static const Color verde = Color(0xff2DB58D);
  static const Color verdeOscuro = Color(0xff1C9B78);
  static const Color textoSuave = Color(0xff9FC7D3);
  static const Color rojoSalir = Color(0xffD95B6A);

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() => loading = true);

    final resumenData = await repository.getResumen();
    final citasData = await repository.getCitasHoy();
    final pacientesData = await repository.getPacientes();

    if (!mounted) return;

    setState(() {
      resumen = resumenData;
      citasHoy = citasData;
      pacientes = pacientesData;
      loading = false;
    });
  }

  Future<void> cambiarEstado(CitaModel cita, String estado) async {
    if (cita.id == null) return;

    final ok = await repository.actualizarEstado(cita.id!, estado);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? "Cita actualizada" : "No se pudo actualizar"),
      ),
    );

    if (ok) {
      cargar();
    }
  }

  Future<void> salir() async {
    await SessionDataSource.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void abrirAjustes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.user["nombre"] ?? "Doctor";

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: cargar,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: selectedIndex == 2
                      ? _pacientesView()
                      : selectedIndex == 1
                          ? _agendaView()
                          : _panelView(nombre),
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _panelView(String nombre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(nombre),
        const SizedBox(height: 22),
        _heroCard(),
        const SizedBox(height: 22),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.05,
          children: [
            _stat(
                "Citas hoy", resumen["citas_hoy"], Icons.calendar_today, verde),
            _stat("Completadas", resumen["completadas"],
                Icons.check_circle_outline, verde),
            _stat("Pendientes", resumen["pendientes"], Icons.hourglass_empty,
                Colors.amber),
            _stat("Este mes", resumen["este_mes"], Icons.trending_up,
                Colors.blueAccent),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "Agenda de hoy",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _agendaList(showActions: false),
      ],
    );
  }

  Widget _agendaView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Agenda",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Gestiona las citas de hoy",
          style: TextStyle(color: textoSuave, fontSize: 15),
        ),
        const SizedBox(height: 18),
        _agendaList(showActions: true),
      ],
    );
  }

  Widget _pacientesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pacientes",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        if (loading)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )
        else if (pacientes.isEmpty)
          const Text(
            "No hay pacientes registrados",
            style: TextStyle(color: textoSuave),
          )
        else
          ...pacientes.map(_pacienteCard),
      ],
    );
  }

  Widget _header(String nombre) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Panel Medico",
                style: TextStyle(
                  color: verde,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _circle(Icons.notifications_none, const Color(0xff1F4F63)),
        const SizedBox(width: 10),
        _circle(Icons.medical_services, verde, onTap: abrirAjustes),
      ],
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: verdeOscuro,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Buen dia, Doctor!",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill(
                Icons.monitor_heart_outlined,
                "${resumen["citas_hoy"]} citas hoy",
              ),
              _pill(Icons.access_time, "08:00 - 17:00"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textoSuave,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const Spacer(),
          Text(
            "${value ?? 0}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _agendaList({required bool showActions}) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (citasHoy.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _box(),
        child: const Text(
          "No hay citas para hoy",
          style: TextStyle(color: textoSuave),
        ),
      );
    }

    return Column(
      children: citasHoy.map((cita) {
        return _citaCard(cita, showActions);
      }).toList(),
    );
  }

  Widget _citaCard(CitaModel cita, bool showActions) {
    final color = _estadoColor(cita);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: _box(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xff1F4F63),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.paciente.isEmpty ? "Paciente" : cita.paciente,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${cita.servicio} - ${cita.duracion}min",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: verde,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    cita.horaCorta,
                    style: const TextStyle(
                      color: verde,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _estadoChip(cita.estadoTexto, color),
                ],
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _action("Confirmar", () => cambiarEstado(cita, "confirmada")),
                _action("Completar", () => cambiarEstado(cita, "completada")),
                _action("Cancelar", () => cambiarEstado(cita, "cancelada")),
                _action("No asistió", () => cambiarEstado(cita, "no_asistio")),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pacienteCard(Map<String, dynamic> paciente) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xff1F4F63),
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paciente["nombre"]?.toString() ?? "Paciente",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  paciente["email"]?.toString() ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: textoSuave),
                ),
                const SizedBox(height: 3),
                Text(
                  paciente["telefono"]?.toString() ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: textoSuave),
                ),
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
          _nav(Icons.grid_view_rounded, "Panel", 0),
          _nav(Icons.calendar_today_outlined, "Agenda", 1),
          _nav(Icons.people_outline, "Pacientes", 2),
          _nav(Icons.logout, "Salir", 3, isExit: true),
        ],
      ),
    );
  }

  Widget _nav(
    IconData icon,
    String label,
    int index, {
    bool isExit = false,
  }) {
    final active = selectedIndex == index;
    final color = isExit
        ? rojoSalir
        : active
            ? Colors.white
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
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: active && !isExit ? verde : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _action(String text, VoidCallback onTap) {
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: .18)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _estadoChip(String estado, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _estadoColor(CitaModel cita) {
    if (cita.estaCompletada) return verde;
    if (cita.estaConfirmada) return verde;
    if (cita.estaCancelada) return Colors.deepPurpleAccent;
    if (cita.estaNoAsistio) return rojoSalir;
    return Colors.amber;
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    );
  }
}
