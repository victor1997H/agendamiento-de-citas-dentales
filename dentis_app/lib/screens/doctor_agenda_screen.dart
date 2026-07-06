import 'package:flutter/material.dart';

import '../data/models/cita_model.dart';
import '../data/repositories/doctor_repository.dart';
import '../widgets/month_calendar.dart';

class DoctorAgendaScreen extends StatefulWidget {
  const DoctorAgendaScreen({super.key});

  @override
  State<DoctorAgendaScreen> createState() => _DoctorAgendaScreenState();
}

class _DoctorAgendaScreenState extends State<DoctorAgendaScreen> {
  final DoctorRepository repository = DoctorRepository();

  DateTime selectedDate = DateTime.now();
  List<CitaModel> citas = [];
  bool loading = true;

  static const Color fondo = Color(0xff08151B);
  static const Color panel = Color(0xff18323B);
  static const Color verde = Color(0xff2DB58D);
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

    final data = await repository.getCitas();

    if (!mounted) return;

    setState(() {
      citas = data;
      loading = false;
    });
  }

  Future<void> cambiarEstado(CitaModel cita, String estado) async {
    if (cita.id == null) return;

    final ok = await repository.actualizarEstado(cita.id!, estado);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? "Cita actualizada" : "No se pudo actualizar")),
    );

    if (ok) cargar();
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
    if (cita.estaCompletada) return verde;
    if (cita.estaConfirmada) return textoSuave;
    if (cita.estaCancelada) return rojo;
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
            onPressed: cargar,
            icon: const Icon(Icons.refresh),
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
              "Agenda del ${_iso(selectedDate)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            if (loading)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else if (citasDelDia.isEmpty)
              _empty()
            else
              ...citasDelDia.map(_citaCard),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _box(),
      child: const Text(
        "No hay citas para este dia",
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xff1F4F63),
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
                      cita.paciente.isEmpty ? "Paciente" : cita.paciente,
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
                      "${cita.servicio} - ${cita.duracion}min",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: verde),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    cita.horaCorta,
                    style: const TextStyle(
                      color: verde,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _chip(cita.estado, color),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _action("Confirmar", () => cambiarEstado(cita, "confirmada")),
              _action("Completar", () => cambiarEstado(cita, "completada")),
              _action("Cancelar", () => cambiarEstado(cita, "cancelada")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(String text, VoidCallback onTap) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(.18)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
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
