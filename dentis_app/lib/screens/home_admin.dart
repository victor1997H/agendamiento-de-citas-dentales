import 'package:flutter/material.dart';

import '../data/datasources/session_datasource.dart';
import '../data/models/cita_model.dart';
import '../data/repositories/cita_repository.dart';
import '../data/repositories/doctor_repository.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';
import 'settings_screen.dart';

class AdminHome extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminHome({super.key, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final doctorRepository = DoctorRepository();
  final citaRepository = CitaRepository();
  final pacienteController = TextEditingController();
  final notasController = TextEditingController();

  int selectedIndex = 0;
  bool loading = true;
  bool saving = false;
  bool savingDisponibilidad = false;
  String selectedService = "Consulta General";
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
  int selectedDiaSemana = DateTime.now().weekday;
  TimeOfDay disponibilidadInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay disponibilidadFin = const TimeOfDay(hour: 17, minute: 0);

  List<CitaModel> citas = [];
  List<Map<String, dynamic>> pacientes = [];
  List<Map<String, dynamic>> disponibilidad = [];
  Map<String, dynamic> resumen = {
    "citas_hoy": 0,
    "completadas": 0,
    "pendientes": 0,
    "este_mes": 0,
  };

  static const Color fondo = Color(0xff08151B);
  static const Color panel = Color(0xff18323B);
  static const Color azul = Color(0xff2F6F88);
  static const Color azulOscuro = Color(0xff1F4F63);
  static const Color textoSuave = Color(0xff9FC7D3);
  static const Color amarillo = Color(0xffF4B728);
  static const Color verde = Color(0xff2FA884);
  static const Color rosa = Color(0xffFF5FA2);
  static const Color rojoSalir = Color(0xffD95B6A);
  static const Color morado = Color(0xff8E7CF6);

  static const servicios = [
    "Consulta General",
    "Limpieza Dental",
    "Blanqueamiento",
    "Control Dental",
    "Ortodoncia",
    "Extracción",
  ];

  @override
  void initState() {
    super.initState();
    cargar();
  }

  @override
  void dispose() {
    pacienteController.dispose();
    notasController.dispose();
    super.dispose();
  }

  Future<void> cargar() async {
    setState(() => loading = true);

    final resumenData = await doctorRepository.getResumen();
    final citasData = await doctorRepository.getCitas();
    final pacientesData = await doctorRepository.getPacientes();
    final disponibilidadData = await doctorRepository.getDisponibilidad();

    if (!mounted) return;

    setState(() {
      resumen = resumenData;
      citas = citasData;
      pacientes = pacientesData;
      disponibilidad = disponibilidadData;
      loading = false;
    });
  }

  Future<void> cambiarEstado(CitaModel cita, String estado) async {
    if (cita.id == null) return;

    final ok = await doctorRepository.actualizarEstado(cita.id!, estado);

    if (!mounted) return;

    if (!ok) {
      _msg("No se pudo actualizar la cita");
      return;
    }

    _msg("Estado actualizado");
    await cargar();
  }

  Future<void> guardarDisponibilidad() async {
    setState(() => savingDisponibilidad = true);

    final ok = await doctorRepository.guardarDisponibilidad(disponibilidad);

    if (!mounted) return;

    setState(() => savingDisponibilidad = false);

    if (!ok) {
      _msg("No se pudo guardar el horario");
      return;
    }

    _msg("Disponibilidad guardada");
    await cargar();
  }

  Future<void> crearCitaManual() async {
    final paciente = pacienteController.text.trim();
    if (paciente.isEmpty) {
      _msg("Escribe el nombre del paciente");
      return;
    }

    final fecha = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (fecha.isBefore(DateTime.now())) {
      _msg("La cita debe ser futura");
      return;
    }

    setState(() => saving = true);

    final ok = await citaRepository.crearCita({
      "paciente": paciente,
      "servicio": selectedService,
      "fecha": fecha.toIso8601String(),
      "notas": notasController.text.trim(),
    });

    if (!mounted) return;

    setState(() => saving = false);

    if (!ok) {
      _msg("No se pudo crear la cita");
      return;
    }

    pacienteController.clear();
    notasController.clear();
    _msg("Cita creada correctamente");
    await cargar();
    setState(() => selectedIndex = 0);
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

  void editarPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileSetupScreen(user: widget.user)),
    );
  }

  void abrirAjustes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user)),
    );
  }

  void _msg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.user["nombre"]?.toString() ?? "Doctor";

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: cargar,
                color: azul,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: _currentView(nombre),
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _currentView(String nombre) {
    if (selectedIndex == 1) return _crearCitaView(nombre);
    if (selectedIndex == 2) return _usuariosView(nombre);
    if (selectedIndex == 3) return _reportesView(nombre);
    if (selectedIndex == 4) return _horarioView(nombre);
    return _panelView(nombre);
  }

  Widget _panelView(String nombre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(nombre, "Panel odontológico"),
        const SizedBox(height: 22),
        _hero(nombre),
        const SizedBox(height: 16),
        _quickCreateCard(),
        const SizedBox(height: 12),
        _availabilityShortcut(),
        const SizedBox(height: 18),
        _statsGrid(),
        const SizedBox(height: 22),
        _estadoLegend(),
        const SizedBox(height: 18),
        const Text(
          "Agenda reciente",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _agendaList(limit: 4),
      ],
    );
  }

  Widget _crearCitaView(String nombre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(nombre, "Crear cita manual"),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _box(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _input("Paciente sin cuenta", pacienteController, Icons.person),
              _serviceSelector(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _pickerButton(
                      Icons.calendar_today_outlined,
                      _formatDate(selectedDate),
                      _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _pickerButton(
                      Icons.access_time,
                      selectedTime.format(context),
                      _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _input("Notas opcionales", notasController, Icons.note_outlined,
                  maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : crearCitaManual,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text("Guardar cita"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azul,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _usuariosView(String nombre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(nombre, "Pacientes"),
        const SizedBox(height: 22),
        if (loading)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else if (pacientes.isEmpty)
          _empty("No hay pacientes registrados")
        else
          ...pacientes.map(_pacienteCard),
      ],
    );
  }

  Widget _reportesView(String nombre) {
    final completadas = citas.where((cita) => cita.estaCompletada).length;
    final pendientes = citas.where((cita) => cita.estaPendiente).length;
    final canceladas = citas.where((cita) => cita.estaCancelada).length;
    final noAsistio = citas.where((cita) => cita.estaNoAsistio).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(nombre, "Reportes"),
        const SizedBox(height: 22),
        _reportRow("Citas totales", citas.length, azul),
        _reportRow("Completadas", completadas, verde),
        _reportRow("Pendientes", pendientes, amarillo),
        _reportRow("Canceladas", canceladas, rojoSalir),
        _reportRow("No asistieron", noAsistio, rosa),
        const SizedBox(height: 18),
        _chartCard(),
      ],
    );
  }

  Widget _horarioView(String nombre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(nombre, "Disponibilidad"),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _box(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Días y horas disponibles",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(7, (index) {
                  final dia = index + 1;
                  final selected = selectedDiaSemana == dia;
                  return ChoiceChip(
                    showCheckmark: false,
                    label: Text(_diaNombre(dia)),
                    selected: selected,
                    selectedColor: azul,
                    backgroundColor: fondo.withValues(alpha: .55),
                    side: BorderSide(
                      color: selected ? azul : textoSuave.withValues(alpha: .35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : textoSuave,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => selectedDiaSemana = dia),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _timeBlockButton(
                      "Inicio",
                      disponibilidadInicio.format(context),
                      Icons.schedule,
                      () => _pickAvailabilityTime(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _timeBlockButton(
                      "Fin",
                      disponibilidadFin.format(context),
                      Icons.schedule_outlined,
                      () => _pickAvailabilityTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _agregarBloqueDisponibilidad,
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar bloque"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: azul.withValues(alpha: .9)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (disponibilidad.isEmpty)
          _empty("Aún no tienes horarios configurados")
        else
          ...disponibilidad.asMap().entries.map((entry) {
            final bloque = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              decoration: _box(),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: azul.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.event_available, color: textoSuave),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _diaNombre(_asInt(bloque["dia_semana"])),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "${bloque["hora_inicio"]} - ${bloque["hora_fin"]}",
                          style: const TextStyle(color: textoSuave),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => disponibilidad.removeAt(entry.key));
                    },
                    icon: const Icon(Icons.delete_outline, color: rojoSalir),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: savingDisponibilidad ? null : guardarDisponibilidad,
            icon: savingDisponibilidad
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text("Guardar disponibilidad"),
            style: ElevatedButton.styleFrom(
              backgroundColor: azul,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(String nombre, String title) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textoSuave,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _circle(Icons.edit_outlined, azulOscuro, onTap: editarPerfil),
        const SizedBox(width: 10),
        _circle(Icons.medical_services_outlined, azul, onTap: abrirAjustes),
      ],
    );
  }

  Widget _hero(String nombre) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: azul,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SmartTooth",
            style: TextStyle(
              color: Color(0xffD8EEF3),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Buen día, $nombre",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill(Icons.calendar_today, "${resumen["citas_hoy"]} hoy"),
              _pill(Icons.people_outline, "${pacientes.length} pacientes"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickCreateCard() {
    return InkWell(
      onTap: () => setState(() => selectedIndex = 1),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: azulOscuro,
              child: Icon(Icons.add, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Crear cita para paciente sin cuenta",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.arrow_forward, color: textoSuave),
          ],
        ),
      ),
    );
  }

  Widget _statsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _statCard("Pacientes", pacientes.length, Icons.people_outline, amarillo),
        _statCard("Citas hoy", resumen["citas_hoy"], Icons.event, verde),
        _statCard("Pendientes", resumen["pendientes"], Icons.hourglass_empty,
            Colors.blueAccent),
        _statCard("Este mes", resumen["este_mes"], Icons.trending_up, rosa),
      ],
    );
  }

  Widget _statCard(String title, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(icon, color: color),
            ],
          ),
          const Spacer(),
          Text(
            "${value ?? 0}",
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

  Widget _agendaList({int? limit}) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final data = limit == null ? citas : citas.take(limit).toList();

    if (data.isEmpty) {
      return _empty("No hay citas para mostrar");
    }

    return Column(children: data.map(_citaCard).toList());
  }

  Widget _citaCard(CitaModel cita) {
    final color = _estadoColor(cita);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .18),
                child: Icon(_estadoIcon(cita), color: color),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${cita.servicio} - ${cita.fechaHoraTexto}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textoSuave, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _chip(cita.estadoTexto, color),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _estadoButton(
                "Aceptar",
                Icons.check_circle_outline,
                verde,
                () => cambiarEstado(cita, "confirmada"),
                disabled: cita.estaConfirmada || cita.estaCompletada,
              ),
              _estadoButton(
                "Completar",
                Icons.done_all,
                azul,
                () => cambiarEstado(cita, "completada"),
                disabled: cita.estaCompletada,
              ),
              _estadoButton(
                "Cancelar",
                Icons.cancel_outlined,
                morado,
                () => cambiarEstado(cita, "cancelada"),
                disabled: cita.estaCancelada || cita.estaCompletada,
              ),
              _estadoButton(
                "No asistió",
                Icons.timer_off_outlined,
                rosa,
                () => cambiarEstado(cita, "no_asistio"),
                disabled: cita.estaNoAsistio || cita.estaCompletada,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _availabilityShortcut() {
    return InkWell(
      onTap: () => setState(() => selectedIndex = 4),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: azulOscuro,
              child: Icon(Icons.event_available, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Configurar disponibilidad",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Estos horarios se muestran al paciente al crear una cita.",
                    style: TextStyle(color: textoSuave, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: textoSuave),
          ],
        ),
      ),
    );
  }

  Widget _estadoLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          _LegendItem(color: amarillo, icon: Icons.schedule, text: "Pendiente"),
          _LegendItem(
            color: verde,
            icon: Icons.check_circle_outline,
            text: "Aceptada",
          ),
          _LegendItem(color: morado, icon: Icons.cancel_outlined, text: "Cancelada"),
          _LegendItem(color: rosa, icon: Icons.timer_off_outlined, text: "No asistió"),
        ],
      ),
    );
  }

  Widget _estadoButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool disabled = false,
  }) {
    return OutlinedButton.icon(
      onPressed: disabled ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: Colors.white24,
        side: BorderSide(color: color.withValues(alpha: disabled ? .25 : .7)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _pacienteCard(Map<String, dynamic> paciente) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: azulOscuro,
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
                Text(
                  paciente["email"]?.toString() ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: textoSuave, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            paciente["telefono"]?.toString() ?? "",
            style: const TextStyle(color: textoSuave, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(String label, int value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            "$value",
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard() {
    final values = _monthlyCounts();
    final maxValue = values.isEmpty
        ? 1
        : values.map((item) => item.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CITAS POR MES",
            style: TextStyle(
              color: textoSuave,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: values.map((item) {
                final height = maxValue == 0 ? 18.0 : 90 * item.value / maxValue;
                return _BarChartItem(
                  month: item.label,
                  value: "${item.value}",
                  height: height.clamp(18, 90).toDouble(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fondo.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedService,
          isExpanded: true,
          dropdownColor: panel,
          iconEnabledColor: textoSuave,
          style: const TextStyle(color: Colors.white),
          items: servicios
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedService = value);
            }
          },
        ),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: textoSuave),
          prefixIcon: Icon(icon, color: textoSuave),
          filled: true,
          fillColor: fondo.withValues(alpha: .55),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _pickerButton(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: fondo.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: textoSuave, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBlockButton(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: fondo.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: azul.withValues(alpha: .24)),
        ),
        child: Row(
          children: [
            Icon(icon, color: textoSuave, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: textoSuave, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: const BoxDecoration(
        color: Color(0xff061017),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.grid_view_rounded, "Panel", 0),
          _navItem(Icons.add_circle_outline, "Cita", 1),
          _navItem(Icons.group_outlined, "Usuarios", 2),
          _navItem(Icons.bar_chart_rounded, "Reportes", 3),
          _navItem(Icons.event_available_outlined, "Horario", 4),
          _navItem(Icons.logout, "Salir", 5, isExit: true),
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
            ? Colors.white
            : Colors.white38;

    return GestureDetector(
      onTap: () {
        if (isExit) {
          salir();
          return;
        }

        setState(() => selectedIndex = index);
      },
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: active && !isExit ? azul : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
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

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
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
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _empty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Text(text, style: const TextStyle(color: textoSuave)),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _pickAvailabilityTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? disponibilidadInicio : disponibilidadFin,
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        disponibilidadInicio = picked;
      } else {
        disponibilidadFin = picked;
      }
    });
  }

  void _agregarBloqueDisponibilidad() {
    final inicioMinutes =
        disponibilidadInicio.hour * 60 + disponibilidadInicio.minute;
    final finMinutes = disponibilidadFin.hour * 60 + disponibilidadFin.minute;

    if (finMinutes <= inicioMinutes) {
      _msg("La hora final debe ser mayor a la inicial");
      return;
    }

    setState(() {
      disponibilidad.add({
        "dia_semana": selectedDiaSemana,
        "hora_inicio": _formatTime(disponibilidadInicio),
        "hora_fin": _formatTime(disponibilidadFin),
        "activo": true,
      });
    });
  }

  Color _estadoColor(CitaModel cita) {
    if (cita.estaCompletada) return verde;
    if (cita.estaConfirmada) return verde;
    if (cita.estaCancelada) return morado;
    if (cita.estaNoAsistio) return rosa;
    return amarillo;
  }

  IconData _estadoIcon(CitaModel cita) {
    if (cita.estaCompletada) return Icons.done_all;
    if (cita.estaConfirmada) return Icons.check_circle_outline;
    if (cita.estaCancelada) return Icons.cancel_outlined;
    if (cita.estaNoAsistio) return Icons.timer_off_outlined;
    return Icons.schedule;
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${_two(date.month)}-${_two(date.day)}";
  }

  String _two(int value) => value.toString().padLeft(2, "0");

  String _formatTime(TimeOfDay time) {
    return "${_two(time.hour)}:${_two(time.minute)}";
  }

  String _diaNombre(int dia) {
    const dias = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    if (dia < 1 || dia > 7) return "Día";
    return dias[dia - 1];
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 1;
  }

  List<_MonthlyCount> _monthlyCounts() {
    final now = DateTime.now();
    final months = <_MonthlyCount>[];
    const labels = [
      "Ene",
      "Feb",
      "Mar",
      "Abr",
      "May",
      "Jun",
      "Jul",
      "Ago",
      "Sep",
      "Oct",
      "Nov",
      "Dic",
    ];

    for (var i = 3; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final count = citas.where((cita) {
        final parsed = DateTime.tryParse(cita.fecha);
        return parsed != null &&
            parsed.year == month.year &&
            parsed.month == month.month;
      }).length;

      months.add(_MonthlyCount(labels[month.month - 1], count));
    }

    return months;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyCount {
  final String label;
  final int value;

  const _MonthlyCount(this.label, this.value);
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
      width: 58,
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
            width: 58,
            height: height,
            decoration: const BoxDecoration(
              color: Color(0xff2F6F88),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
