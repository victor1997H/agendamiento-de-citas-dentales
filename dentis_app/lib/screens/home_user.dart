import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/datasources/session_datasource.dart';
import '../data/repositories/cita_repository.dart';
import '../services/sync_service.dart';
import 'login_screen.dart';
import 'mis_citas_screen.dart';
import 'nueva_cita_screen.dart';
import 'settings_screen.dart';

class UserHome extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserHome({super.key, required this.user});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final CitaRepository _citaRepository = CitaRepository();
  final TextEditingController _notesController = TextEditingController();

  int selectedIndex = 0;
  bool loadingCitas = false;
  bool savingCita = false;
  String selectedService = "Limpieza Dental";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  List<Map<String, dynamic>> citas = [];

  static const Color azulMate = AppTheme.primary;
  static const Color azulPrincipal = AppTheme.primary;
  static const Color azulOscuro = AppTheme.primaryDark;
  static const Color textoSuave = AppTheme.softText;
  static const Color rojoSalir = AppTheme.danger;
  static const Color amarillo = Color(0xffF1B64B);

  static const List<String> servicios = [
    "Limpieza Dental",
    "Blanqueamiento",
    "Control Dental",
    "Ortodoncia",
    "Consulta General",
  ];

  @override
  void initState() {
    super.initState();
    SyncService.sincronizar();
    _loadCitas();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCitas() async {
    setState(() => loadingCitas = true);

    try {
      final response = await _citaRepository.getCitas();
      if (!mounted) return;
      setState(() {
        citas = response
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      _showMsg("No se pudieron cargar tus citas");
    } finally {
      if (mounted) {
        setState(() => loadingCitas = false);
      }
    }
  }

  Future<void> _crearCita() async {
    if (selectedDate == null || selectedTime == null) {
      _showMsg("Selecciona fecha y hora");
      return;
    }

    final fecha = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (fecha.isBefore(DateTime.now())) {
      _showMsg("La cita debe ser futura");
      return;
    }

    setState(() => savingCita = true);

    try {
      final ok = await _citaRepository.crearCita({
        "paciente": widget.user["nombre"] ?? "Paciente",
        "servicio": selectedService,
        "fecha": fecha.toIso8601String(),
        "notas": _notesController.text.trim(),
      });

      if (!mounted) return;

      if (!ok) {
        _showMsg("No se pudo crear la cita");
        return;
      }

      _showMsg("Cita creada correctamente");
      _notesController.clear();
      selectedDate = null;
      selectedTime = null;
      selectedIndex = 2;
      await _loadCitas();
    } catch (_) {
      if (!mounted) return;
      _showMsg("Error de conexión al crear la cita");
    } finally {
      if (mounted) {
        setState(() => savingCita = false);
      }
    }
  }

  Future<void> _openNuevaCitaScreen() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NuevaCitaScreen()),
    );

    if (creada == true) {
      selectedIndex = 2;
      await _loadCitas();
    }
  }

  Future<void> _openMisCitasScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MisCitasScreen()),
    );

    await _loadCitas();
  }

  Future<void> salir() async {
    await SessionDataSource.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.user["nombre"] ?? "Paciente";
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCitas,
                color: colors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _currentContent(nombre),
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _currentContent(String nombre) {
    switch (selectedIndex) {
      case 1:
        return _agendarContent(nombre);
      case 2:
        return _misCitasContent(nombre);
      default:
        return _inicioContent(nombre);
    }
  }

  Widget _inicioContent(String nombre) {
    final proxima = citas.isNotEmpty ? citas.first : null;
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(nombre, "Bienvenida 👋"),
        const SizedBox(height: 18),
        _citaPrincipal(proxima),
        const SizedBox(height: 15),
        _nuevaCita(),
        const SizedBox(height: 15),
        _doctorCard(),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            "Historial reciente",
            style: TextStyle(
              color: colors.text,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (loadingCitas)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: CircularProgressIndicator(color: colors.muted),
            ),
          )
        else if (citas.isEmpty)
          _emptyPanel("Aún no tienes citas registradas")
        else
          ...citas.take(4).map(_historialFromCita),
      ],
    );
  }

  Widget _agendarContent(String nombre) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(nombre, "Agendar cita"),
        const SizedBox(height: 18),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.all(18),
          decoration: _panelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nueva cita",
                style: TextStyle(
                  color: colors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              _label("Servicio"),
              const SizedBox(height: 8),
              _serviceSelector(),
              const SizedBox(height: 16),
              _label("Fecha y hora"),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _pickerButton(
                      icon: Icons.calendar_today_outlined,
                      text: selectedDate == null
                          ? "Fecha"
                          : _formatDate(selectedDate!),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _pickerButton(
                      icon: Icons.access_time,
                      text: selectedTime == null
                          ? "Hora"
                          : selectedTime!.format(context),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label("Notas"),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(color: colors.text),
                decoration: InputDecoration(
                  hintText: "Ej. Dolor, control o preferencia de horario",
                  hintStyle: TextStyle(color: colors.muted),
                  filled: true,
                  fillColor: colors.field.withValues(alpha: .75),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: savingCita ? null : _crearCita,
                  icon: savingCita
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text("Confirmar cita"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulPrincipal,
                    foregroundColor: Colors.white,
                    elevation: 0,
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

  Widget _misCitasContent(String nombre) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(nombre, "Mis citas"),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Citas registradas",
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: loadingCitas ? null : _loadCitas,
                icon: Icon(Icons.refresh, color: colors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (loadingCitas)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: CircularProgressIndicator(color: colors.muted),
            ),
          )
        else if (citas.isEmpty)
          _emptyPanel("No hay citas para mostrar")
        else
          ...citas.map(_citaDetalle),
      ],
    );
  }

  Widget _header(String nombre, String subtitle) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombre,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _circleButton(
            Icons.notifications_none,
            colors.isLight ? colors.primary.withValues(alpha: .12) : azulOscuro,
            colors.isLight ? azulPrincipal : textoSuave,
            onTap: _showNotifications,
          ),
          const SizedBox(width: 10),
          _circleButton(
            Icons.person,
            azulMate,
            Colors.white,
            onTap: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _citaPrincipal(Map<String, dynamic>? cita) {
    final servicio = cita == null ? "Sin citas próximas" : _serviceName(cita);
    final doctor =
        cita == null ? "Agenda tu primera cita" : "Dr. Roberto Méndez";
    final fecha = _dateFromCita(cita);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: azulPrincipal,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🦷 $servicio",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            doctor,
            style: const TextStyle(
              color: Color(0xffD8EEF3),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _InfoPill(
                icon: Icons.calendar_today,
                text: fecha == null ? "Sin fecha" : _formatShortDate(fecha),
              ),
              const SizedBox(width: 10),
              _InfoPill(
                icon: Icons.access_time,
                text: fecha == null ? "--:--" : "${_formatTime(fecha)} hrs",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nuevaCita() {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: _openNuevaCitaScreen,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration(),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: azulOscuro,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nueva cita",
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Ver disponibilidad",
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: colors.muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _doctorCard() {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: azulMate,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TU DOCTOR",
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  "Dr. Roberto Méndez",
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Odontólogo General",
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 15),
                    Icon(Icons.star, color: Colors.amber, size: 15),
                    Icon(Icons.star, color: Colors.amber, size: 15),
                    Icon(Icons.star, color: Colors.amber, size: 15),
                    Icon(Icons.star, color: Colors.amber, size: 15),
                    SizedBox(width: 6),
                    Text(
                      "5.0",
                      style: TextStyle(
                        color: colors.subtle,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _circleButton(
            Icons.call,
            colors.isLight ? colors.primary.withValues(alpha: .12) : azulOscuro,
            colors.isLight ? colors.primary : textoSuave,
            onTap: () => _showMsg("Contacto del doctor disponible"),
          ),
        ],
      ),
    );
  }

  Widget _historialFromCita(Map<String, dynamic> cita) {
    final estado = _statusLabel(cita["estado"]);
    final fecha = _dateFromCita(cita);

    return _historial(
      titulo: _serviceName(cita),
      fecha: fecha == null ? _rawDate(cita) : _formatDateTime(fecha),
      estado: estado,
      colorEstado: estado == "Pendiente" ? amarillo : azulPrincipal,
    );
  }

  Widget _historial({
    required String titulo,
    required String fecha,
    required String estado,
    required Color colorEstado,
  }) {
    final colors = AppColors.of(context);

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
                  titulo,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  fecha,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _statusPill(estado, colorEstado),
        ],
      ),
    );
  }

  Widget _citaDetalle(Map<String, dynamic> cita) {
    final fecha = _dateFromCita(cita);
    final estado = _statusLabel(cita["estado"]);
    final color = estado == "Pendiente" ? amarillo : azulPrincipal;
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: azulOscuro,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text("🦷", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _serviceName(cita),
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusPill(estado, color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: colors.muted, size: 17),
              const SizedBox(width: 8),
              Text(
                fecha == null ? _rawDate(cita) : _formatDateTime(fecha),
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.medical_services_outlined,
                  color: colors.muted, size: 17),
              const SizedBox(width: 8),
              Text(
                "Dr. Roberto Méndez",
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceSelector() {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.field.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedService,
          dropdownColor: colors.panel,
          iconEnabledColor: colors.muted,
          isExpanded: true,
          style: TextStyle(color: colors.text, fontSize: 14),
          items: servicios
              .map(
                (servicio) => DropdownMenuItem(
                  value: servicio,
                  child: Text(servicio),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedService = value);
          },
        ),
      ),
    );
  }

  Widget _pickerButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.field.withValues(alpha: .75),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.muted, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    final colors = AppColors.of(context);

    return Text(
      text,
      style: TextStyle(
        color: colors.muted,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _statusPill(String estado, Color colorEstado) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorEstado.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: colorEstado == azulPrincipal ? colors.primary : colorEstado,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _emptyPanel(String message) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Text(
        message,
        style: TextStyle(
          color: colors.muted,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: colors.nav,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
        ),
        boxShadow: colors.softShadow == null ? null : [colors.softShadow!],
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
    final colors = AppColors.of(context);
    final color = isExit
        ? rojoSalir
        : active
            ? azulPrincipal
            : colors.muted.withValues(alpha: .72);

    return GestureDetector(
      onTap: () {
        if (isExit) {
          salir();
          return;
        }

        if (index == 1) {
          _openNuevaCitaScreen();
          return;
        }

        if (index == 2) {
          _openMisCitasScreen();
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

  Widget _circleButton(
    IconData icon,
    Color bg,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    final colors = AppColors.of(context);

    return BoxDecoration(
      color: colors.panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: colors.border),
      boxShadow: colors.softShadow == null ? null : [colors.softShadow!],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final colors = AppColors.of(context);
    final baseTheme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: azulPrincipal,
              surface: colors.panel,
              onSurface: colors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final colors = AppColors.of(context);
    final baseTheme = Theme.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: azulPrincipal,
              surface: colors.panel,
              onSurface: colors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  void _showNotifications() {
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _sheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notificaciones",
                style: TextStyle(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _notificationItem(
                Icons.calendar_today_outlined,
                "Recordatorio de cita",
                citas.isEmpty
                    ? "Agenda una cita para recibir recordatorios"
                    : "Tienes ${citas.length} cita(s) registradas",
              ),
              _notificationItem(
                Icons.sync,
                "Sincronización",
                "Tus datos se actualizan cuando hay conexión",
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user)),
    );
  }

  Widget _sheetContainer({required Widget child}) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: colors.softShadow == null ? null : [colors.softShadow!],
      ),
      child: child,
    );
  }

  Widget _notificationItem(IconData icon, String title, String subtitle) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.isLight
                  ? colors.primary.withValues(alpha: .12)
                  : azulOscuro,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _serviceName(Map<String, dynamic> cita) {
    final servicio = cita["servicio"]?.toString().trim();
    if (servicio != null && servicio.isNotEmpty) {
      return servicio;
    }

    return "Consulta Dental";
  }

  String _statusLabel(dynamic value) {
    final raw = value?.toString().toLowerCase() ?? "pendiente";

    if (raw == "confirmada" || raw == "confirmado") return "Confirmada";
    if (raw == "completada" || raw == "completado") return "Completada";
    if (raw == "cancelada" || raw == "cancelado") return "Cancelada";
    return "Pendiente";
  }

  DateTime? _dateFromCita(Map<String, dynamic>? cita) {
    if (cita == null) return null;
    final raw = cita["fecha"]?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _rawDate(Map<String, dynamic> cita) {
    final raw = cita["fecha"]?.toString() ?? "Sin fecha";
    return raw.length > 22 ? raw.substring(0, 22) : raw;
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${_two(date.month)}-${_two(date.day)}";
  }

  String _formatShortDate(DateTime date) {
    const months = [
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
    return "${date.day} ${months[date.month - 1]}";
  }

  String _formatTime(DateTime date) {
    return "${_two(date.hour)}:${_two(date.minute)}";
  }

  String _formatDateTime(DateTime date) {
    return "${_formatDate(date)} ${_formatTime(date)}";
  }

  String _two(int value) {
    return value.toString().padLeft(2, "0");
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
        color: Colors.white.withValues(alpha: .18),
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
