import 'package:flutter/material.dart';

import '../data/models/cita_model.dart';
import '../data/repositories/cita_repository.dart';

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
  TimeOfDay hora = const TimeOfDay(hour: 10, minute: 0);
  bool loading = false;

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
  void dispose() {
    notasController.dispose();
    super.dispose();
  }

  String _dos(int value) => value.toString().padLeft(2, "0");

  String get fechaTexto =>
      "${fecha.year}-${_dos(fecha.month)}-${_dos(fecha.day)}";
  String get horaTexto => "${_dos(hora.hour)}:${_dos(hora.minute)}";

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
      setState(() => fecha = selected);
    }
  }

  Future<void> elegirHora() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: hora,
    );

    if (selected != null) {
      setState(() => hora = selected);
    }
  }

  Future<void> guardar() async {
    setState(() => loading = true);

    final cita = CitaModel(
      servicio: servicio,
      doctor: doctor,
      fecha: fechaTexto,
      hora: horaTexto,
      notas: notasController.text.trim(),
    );

    final ok = await repository.crearCita(cita);

    if (!mounted) return;

    setState(() => loading = false);

    if (ok) {
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
            const Text("Servicio", style: TextStyle(color: textoSuave)),
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
            Row(
              children: [
                Expanded(
                  child: _buttonInfo(
                      "Fecha", fechaTexto, Icons.calendar_today, elegirFecha),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buttonInfo(
                      "Hora", horaTexto, Icons.access_time, elegirHora),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text("Notas", style: TextStyle(color: textoSuave)),
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
