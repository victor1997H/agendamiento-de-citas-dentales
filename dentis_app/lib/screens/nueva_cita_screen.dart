import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
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
  DateTime fecha = DateTime.now();
  String? horaSeleccionada;
  bool loading = false;
  bool cargandoHoras = true;
  bool cargandoDisponibilidad = true;
  List<String> horasDisponibles = [];
  Map<String, List<String>> horasPorFecha = {};

  final servicios = [
    "Limpieza Dental",
    "Blanqueamiento",
    "Control Dental",
    "Ortodoncia",
    "Extraccion",
    "Consulta Dental",
  ];

  static const azul = AppTheme.primary;

  @override
  void initState() {
    super.initState();
    cargarDisponibilidadInicial();
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
    final colors = AppColors.of(context);
    final baseTheme = Theme.of(context);
    final selected = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: azul,
              surface: colors.panel,
              onSurface: colors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      setState(() {
        fecha = selected;
        horaSeleccionada = null;
      });
      await cargarHoras();
    }
  }

  Future<void> cargarDisponibilidadInicial() async {
    setState(() {
      cargandoDisponibilidad = true;
      cargandoHoras = true;
    });

    final now = DateTime.now();
    final dias = List.generate(
      7,
      (index) => DateTime(now.year, now.month, now.day + index),
    );

    final results = await Future.wait(
      dias.map((dia) async {
        final key = _dateKey(dia);
        final horas = await repository.getHorasDisponibles(key);
        return MapEntry(key, horas);
      }),
    );

    if (!mounted) return;

    final mapa = Map<String, List<String>>.fromEntries(results);
    DateTime? firstAvailable;
    for (final dia in dias) {
      if ((mapa[_dateKey(dia)] ?? []).isNotEmpty) {
        firstAvailable = dia;
        break;
      }
    }

    setState(() {
      horasPorFecha = mapa;
      if (firstAvailable != null) {
        fecha = firstAvailable;
      }
      horasDisponibles = mapa[fechaTexto] ?? [];
      cargandoDisponibilidad = false;
      cargandoHoras = false;
    });
  }

  Future<void> cargarHoras() async {
    setState(() => cargandoHoras = true);

    final data = await repository.getHorasDisponibles(fechaTexto);

    if (!mounted) return;

    setState(() {
      horasDisponibles = data;
      horasPorFecha = {
        ...horasPorFecha,
        fechaTexto: data,
      };
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
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("Nueva cita"),
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _availabilityHero(),
            const SizedBox(height: 18),
            _sectionTitle("1. Día disponible"),
            const SizedBox(height: 8),
            _diasPanel(),
            const SizedBox(height: 18),
            _sectionTitle("2. Hora disponible"),
            const SizedBox(height: 8),
            _horasPanel(),
            const SizedBox(height: 18),
            _sectionTitle("3. ¿Qué necesitas atenderte?"),
            const SizedBox(height: 8),
            _serviciosPanel(),
            const SizedBox(height: 18),
            _info("Doctor", doctor, Icons.medical_services),
            const SizedBox(height: 18),
            _sectionTitle("4. Detalle adicional"),
            const SizedBox(height: 8),
            TextField(
              controller: notasController,
              minLines: 3,
              maxLines: 5,
              style: TextStyle(color: colors.text),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.panel,
                hintText: "Detalle opcional",
                hintStyle: TextStyle(color: colors.muted),
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
    final colors = AppColors.of(context);

    return Text(
      text,
      style: TextStyle(
        color: colors.muted,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _availabilityHero() {
    final selectedText = horaSeleccionada == null
        ? "Elige un horario para continuar"
        : "$fechaTexto a las $horaSeleccionada";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: azul,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.event_available, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Disponibilidad del odontólogo",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  selectedText,
                  style: const TextStyle(color: Color(0xffD8EEF3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diasPanel() {
    final colors = AppColors.of(context);
    final dias = List.generate(7, (index) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day + index);
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: colors.softShadow == null ? null : [colors.softShadow!],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Toca un día con horarios disponibles",
            style: TextStyle(
              color: colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dias.map((dia) {
                final selected = _sameDay(dia, fecha);
                final key = _dateKey(dia);
                final count = horasPorFecha[key]?.length ?? 0;
                final available = count > 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: !available && !cargandoDisponibilidad
                        ? null
                        : () async {
                            setState(() {
                              fecha = dia;
                              horaSeleccionada = null;
                              horasDisponibles = horasPorFecha[key] ?? [];
                            });
                            if (!horasPorFecha.containsKey(key)) {
                              await cargarHoras();
                            }
                          },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 88,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? azul
                            : available
                                ? colors.field.withValues(alpha: .85)
                                : colors.field.withValues(alpha: .45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? azul
                              : available
                                  ? colors.primary.withValues(alpha: .22)
                                  : colors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _diaCorto(dia.weekday),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : available
                                      ? colors.muted
                                      : colors.muted.withValues(alpha: .45),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dos(dia.day),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : available
                                      ? colors.text
                                      : colors.muted.withValues(alpha: .45),
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cargandoDisponibilidad
                                ? "..."
                                : available
                                    ? "$count horas"
                                    : "Sin horario",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : available
                                      ? colors.muted
                                      : colors.muted.withValues(alpha: .45),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: elegirFecha,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colors.field.withValues(alpha: .8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: colors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Buscar otra fecha: $fechaTexto",
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _horasPanel() {
    final colors = AppColors.of(context);

    if (cargandoHoras) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    if (horasDisponibles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: colors.border),
          boxShadow: colors.softShadow == null ? null : [colors.softShadow!],
        ),
        child: Text(
          "No hay horas disponibles para este día",
          style: TextStyle(color: colors.muted),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: colors.softShadow == null ? null : [colors.softShadow!],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: horasDisponibles.map((hora) {
          final selected = horaSeleccionada == hora;
          return ChoiceChip(
            showCheckmark: false,
            avatar: Icon(
              Icons.schedule,
              size: 16,
              color: selected ? Colors.white : colors.primary,
            ),
            label: Text(hora),
            selected: selected,
            selectedColor: azul,
            backgroundColor: colors.field.withValues(alpha: .85),
            side: BorderSide(
              color: selected ? azul : colors.primary.withValues(alpha: .28),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            labelStyle: TextStyle(
              color: selected ? Colors.white : colors.muted,
              fontWeight: FontWeight.bold,
            ),
            onSelected: (_) => setState(() => horaSeleccionada = hora),
          );
        }).toList(),
      ),
    );
  }

  Widget _serviciosPanel() {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: colors.softShadow == null ? null : [colors.softShadow!],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: servicios.map((item) {
          final selected = servicio == item;
          return ChoiceChip(
            showCheckmark: false,
            avatar: Icon(
              Icons.medical_services_outlined,
              size: 16,
              color: selected ? Colors.white : colors.primary,
            ),
            label: Text(item),
            selected: selected,
            selectedColor: azul,
            backgroundColor: colors.field.withValues(alpha: .85),
            side: BorderSide(
              color: selected ? azul : colors.primary.withValues(alpha: .28),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            labelStyle: TextStyle(
              color: selected ? Colors.white : colors.muted,
              fontWeight: FontWeight.bold,
            ),
            onSelected: (_) => setState(() => servicio = item),
          );
        }).toList(),
      ),
    );
  }

  Widget _info(String title, String value, IconData icon) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
        boxShadow: colors.softShadow == null ? null : [colors.softShadow!],
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateKey(DateTime date) {
    return "${date.year}-${_dos(date.month)}-${_dos(date.day)}";
  }

  String _diaCorto(int weekday) {
    const dias = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    return dias[(weekday - 1).clamp(0, 6)];
  }
}
