import 'package:flutter/material.dart';

import '../data/models/cita_model.dart';
import '../data/repositories/cita_repository.dart';
import '../widgets/month_calendar.dart';
import 'nueva_cita_screen.dart';

class UserAgendaScreen extends StatefulWidget {
  const UserAgendaScreen({super.key});

  @override
  State<UserAgendaScreen> createState() => _UserAgendaScreenState();
}

class _UserAgendaScreenState extends State<UserAgendaScreen> {
  final CitaRepository repository = CitaRepository();

  DateTime selectedDate = DateTime.now();
  List<CitaModel> citas = [];
  bool loading = true;

  static const Color fondo = Color(0xff08151B);
  static const Color panel = Color(0xff18323B);
  static const Color azul = Color(0xff2F6F88);
  static const Color textoSuave = Color(0xff9FC7D3);
  static const Color rojo = Color(0xffD95B6A);
  static const Color calendario = Color(0xffD78BE8);

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
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

    if (creada == true) cargar();
  }

  String _dos(int value) => value.toString().padLeft(2, "0");

  String _iso(DateTime date) {
    return "${date.year}-${_dos(date.month)}-${_dos(date.day)}";
  }

  List<CitaModel> get citasDelDia {
    final fecha = _iso(selectedDate);
    final data = citas.where((cita) => cita.fecha == fecha).toList();
    data.sort((a, b) => a.horaCorta.compareTo(b.horaCorta));
    return data;
  }

  Color _estadoColor(CitaModel cita) {
    if (cita.estaCancelada) return rojo;
    if (cita.estaConfirmada || cita.estaCompletada) return textoSuave;
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text("Agenda"),
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: abrirNuevaCita,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cargar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            MonthCalendar(
              selectedDate: selectedDate,
              accentColor: calendario,
              onDateSelected: (date) {
                setState(() => selectedDate = date);
              },
            ),
            const SizedBox(height: 18),
            Text(
              "Citas del ${_iso(selectedDate)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            if (loading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.white))
            else if (citasDelDia.isEmpty)
              _empty()
            else
              ...citasDelDia.map(_citaCard),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        onPressed: abrirNuevaCita,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _box(),
      child: const Text(
        "No tienes citas para este dia",
        style: TextStyle(color: textoSuave),
      ),
    );
  }

  Widget _citaCard(CitaModel cita) {
    final color = _estadoColor(cita);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: azul,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.medical_services, color: Colors.white),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
                Text(
                  "${cita.doctor} - ${cita.horaCorta}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: textoSuave),
                ),
              ],
            ),
          ),
          _chip(cita.estado, color),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 105),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
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

  BoxDecoration _box() {
    return BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withOpacity(.08)),
    );
  }
}
