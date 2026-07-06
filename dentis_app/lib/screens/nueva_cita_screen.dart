import 'package:flutter/material.dart';

import '../data/models/cita_model.dart';
import '../data/repositories/cita_repository.dart';
import '../services/notification_service.dart';

class NuevaCitaScreen extends StatefulWidget {
  const NuevaCitaScreen({super.key});

  @override
  State<NuevaCitaScreen> createState() => _NuevaCitaScreenState();
}

class _NuevaCitaScreenState extends State<NuevaCitaScreen> {
  final CitaRepository repository = CitaRepository();
  final notasController = TextEditingController();

  String servicio = "Limpieza Dental";
  final String doctor = "Dr. Roberto Mendez";
  DateTime fecha = DateTime.now().add(const Duration(days: 1));
  String? horaSeleccionada;
  bool loading = false;
  bool cargandoHoras = true;
  List<String> horasDisponibles = [];

  final servicios = [
    "Limpieza Dental",
    "Blanqueamiento",
    "Control Dental",
    "Ortodoncia",
    "Extraccion",
    "Consulta Dental",
  ];

  static const fondo = Color(0xff08151B);
  static const panel = Color(0xff18323B);
  static const azul = Color(0xff2F6F88);
  static const textoSuave = Color(0xff9FC7D3);

  @override
  void initState() {
    super.initState();
    cargarHoras();
  }

  @override
  void dispose() {
    notasController.dispose();
    super.dispose();
  }

  String _dos(int value) => value.toString().padLeft(2, "0");

  String get fechaTexto =>
      "${fecha.year}-${_dos(fecha.month)}-${_dos(fecha.day)}";

  void _msg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> elegirFecha() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected != null) {
      setState(() {
        fecha = selected;
        horaSeleccionada = null;
      });
      await cargarHoras();
    }
  }

  Future<void> cargarHoras() async {
    setState(() => cargandoHoras = true);

    final data = await repository.getHorasDisponibles(fechaTexto);

    if (!mounted) return;

    setState(() {
      horasDisponibles = data;
      cargandoHoras = false;
      if (horaSeleccionada != null && !data.contains(horaSeleccionada)) {
        horaSeleccionada = null;
      }
    });
  }

  Future<void> guardar() async {
    if (horaSeleccionada == null) {
      _msg("Selecciona una hora disponible");
      return;
    }

    setState(() => loading = true);

    final cita = CitaModel(
      servicio: servicio,
      doctor: doctor,
      fecha: fechaTexto,
      hora: horaSeleccionada!,
      notas: notasController.text.trim(),
    );

    final ok = await repository.crearCita(cita);

    if (!mounted) return;

    setState(() => loading = false);

    if (ok) {
      await NotificationService.scheduleAppointmentReminder(cita);
      if (!mounted) return;
      _msg("Cita creada correctamente");
      Navigator.pop(context, true);
    } else {
      _msg("No se pudo crear la cita");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text("Nueva cita"),
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("1. Elige una fecha"),
            const SizedBox(height: 8),
            _buttonInfo("Fecha", fechaTexto, Icons.calendar_today, elegirFecha),
            const SizedBox(height: 18),
            _sectionTitle("2. Selecciona una hora disponible"),
            const SizedBox(height: 8),
            _horasPanel(),
            const SizedBox(height: 18),
            _sectionTitle("3. Servicio"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: servicio,
                  isExpanded: true,
                  dropdownColor: panel,
                  style: const TextStyle(color: Colors.white),
                  items: servicios.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => servicio = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            _info("Doctor", doctor, Icons.medical_services),
            const SizedBox(height: 18),
            _sectionTitle("4. Detalle adicional"),
            const SizedBox(height: 8),
            TextField(
              controller: notasController,
              minLines: 3,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: panel,
                hintText: "Detalle opcional",
                hintStyle: const TextStyle(color: textoSuave),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azul,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Guardar cita",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: textoSuave,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _horasPanel() {
    if (cargandoHoras) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (horasDisponibles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15)),
        child: const Text(
          "No hay horas disponibles para este día",
          style: TextStyle(color: textoSuave),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: horasDisponibles.map((hora) {
        final selected = horaSeleccionada == hora;
        return ChoiceChip(
          label: Text(hora),
          selected: selected,
          selectedColor: azul,
          backgroundColor: panel,
          labelStyle: TextStyle(
            color: selected ? Colors.white : textoSuave,
            fontWeight: FontWeight.bold,
          ),
          onSelected: (_) => setState(() => horaSeleccionada = hora),
        );
      }).toList(),
    );
  }

  Widget _info(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: textoSuave),
          const SizedBox(width: 10),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buttonInfo(
      String title, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: panel, borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: textoSuave),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: textoSuave)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
