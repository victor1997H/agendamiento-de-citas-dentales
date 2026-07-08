import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/doctor_repository.dart';

class AvailabilityManager extends StatefulWidget {
  final String doctorName;

  const AvailabilityManager({
    super.key,
    required this.doctorName,
  });

  @override
  State<AvailabilityManager> createState() => _AvailabilityManagerState();
}

class _AvailabilityManagerState extends State<AvailabilityManager> {
  final DoctorRepository repository = DoctorRepository();

  late DateTime selectedDate;
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 12, minute: 0);
  bool loading = true;
  bool saving = false;
  List<Map<String, dynamic>> blocks = [];

  static const Color primary = AppTheme.primary;
  static const Color danger = AppTheme.danger;

  @override
  void initState() {
    super.initState();
    selectedDate = _dateOnly(DateTime.now());
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    final data = await repository.getDisponibilidad();

    if (!mounted) return;

    setState(() {
      blocks = data;
      loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => saving = true);

    final ok = await repository.guardarDisponibilidad(blocks);

    if (!mounted) return;

    setState(() => saving = false);

    if (!ok) {
      _msg("No se pudo guardar la disponibilidad");
      return;
    }

    _msg("Disponibilidad guardada");
    await _load();
  }

  Future<void> _pickDate() async {
    final colors = AppColors.of(context);
    final baseTheme = Theme.of(context);
    final today = _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isBefore(today) ? today : selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: primary,
              surface: colors.panel,
              onSurface: colors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = _dateOnly(picked));
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final colors = AppColors.of(context);
    final baseTheme = Theme.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
      builder: (context, child) {
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: primary,
              surface: colors.panel,
              onSurface: colors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startTime = picked;
      } else {
        endTime = picked;
      }
    });
  }

  void _addBlock() {
    final startMinutes = _minutes(startTime);
    final endMinutes = _minutes(endTime);

    if (endMinutes <= startMinutes) {
      _msg("La hora final debe ser mayor a la inicial");
      return;
    }

    final dateKey = _formatDate(selectedDate);
    final hasOverlap = blocks.any((block) {
      if (block["fecha"]?.toString() != dateKey) return false;

      final blockStart = _timeTextToMinutes(block["hora_inicio"]);
      final blockEnd = _timeTextToMinutes(block["hora_fin"]);
      return startMinutes < blockEnd && endMinutes > blockStart;
    });

    if (hasOverlap) {
      _msg("Ese bloque se cruza con otro horario");
      return;
    }

    setState(() {
      blocks.add({
        "fecha": dateKey,
        "dia_semana": selectedDate.weekday,
        "hora_inicio": _formatTime(startTime),
        "hora_fin": _formatTime(endTime),
        "activo": true,
      });
    });
  }

  void _msg(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Disponibilidad",
          style: TextStyle(
            color: colors.text,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.doctorName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.muted, fontSize: 15),
        ),
        const SizedBox(height: 18),
        _editorCard(),
        const SizedBox(height: 16),
        _blocksList(),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: saving || loading ? null : _save,
            icon: saving
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
              backgroundColor: primary,
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

  Widget _editorCard() {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Calendario de atención",
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _dateButton(),
          const SizedBox(height: 12),
          _quickDates(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _timeButton(
                  "Inicio",
                  startTime.format(context),
                  Icons.schedule,
                  () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _timeButton(
                  "Fin",
                  endTime.format(context),
                  Icons.schedule_outlined,
                  () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _addBlock,
              icon: const Icon(Icons.add),
              label: const Text("Agregar bloque"),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.text,
                side: BorderSide(color: primary.withValues(alpha: .9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateButton() {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.field.withValues(alpha: .85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: .22)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dayName(selectedDate.weekday),
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(selectedDate),
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.muted),
          ],
        ),
      ),
    );
  }

  Widget _quickDates() {
    final colors = AppColors.of(context);
    final today = _dateOnly(DateTime.now());
    final days = List.generate(7, (index) {
      return today.add(Duration(days: index));
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((day) {
          final selected = _sameDay(day, selectedDate);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              label: Text("${_dayShort(day.weekday)} ${_two(day.day)}"),
              selected: selected,
              selectedColor: primary,
              backgroundColor: colors.field.withValues(alpha: .85),
              side: BorderSide(
                color:
                    selected ? primary : colors.primary.withValues(alpha: .22),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : colors.muted,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) => setState(() => selectedDate = day),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _timeButton(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
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

  Widget _blocksList() {
    final colors = AppColors.of(context);

    if (loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    if (blocks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Text(
          "Aún no hay horarios configurados",
          style: TextStyle(color: colors.muted),
        ),
      );
    }

    final sorted = List<Map<String, dynamic>>.from(blocks)..sort(_sortBlocks);

    return Column(
      children: sorted.map((block) {
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
                  color: primary.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.event_available, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _blockTitle(block),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${block["hora_inicio"]} - ${block["hora_fin"]}",
                      style: TextStyle(color: colors.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => blocks.remove(block)),
                icon: const Icon(Icons.delete_outline, color: danger),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  BoxDecoration _box() {
    final colors = AppColors.of(context);

    return BoxDecoration(
      color: colors.panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: colors.border),
      boxShadow: colors.softShadow == null ? null : [colors.softShadow!],
    );
  }

  int _sortBlocks(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aDate = a["fecha"]?.toString() ?? "9999-12-31";
    final bDate = b["fecha"]?.toString() ?? "9999-12-31";
    final dateCompare = aDate.compareTo(bDate);
    if (dateCompare != 0) return dateCompare;

    final dayCompare = _asInt(a["dia_semana"]).compareTo(
      _asInt(b["dia_semana"]),
    );
    if (dayCompare != 0) return dayCompare;

    return _timeTextToMinutes(a["hora_inicio"]).compareTo(
      _timeTextToMinutes(b["hora_inicio"]),
    );
  }

  String _blockTitle(Map<String, dynamic> block) {
    final date = block["fecha"]?.toString();
    final day = _dayShort(_asInt(block["dia_semana"]));

    if (date == null || date.isEmpty) {
      return "$day · semanal";
    }

    return "$day · $date";
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;

  int _timeTextToMinutes(dynamic value) {
    final parts = value.toString().split(":");
    if (parts.length < 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 1;
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${_two(date.month)}-${_two(date.day)}";
  }

  String _formatTime(TimeOfDay time) {
    return "${_two(time.hour)}:${_two(time.minute)}";
  }

  String _two(int value) => value.toString().padLeft(2, "0");

  String _dayName(int day) {
    const days = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo",
    ];
    if (day < 1 || day > 7) return "Día";
    return days[day - 1];
  }

  String _dayShort(int day) {
    const days = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    if (day < 1 || day > 7) return "Día";
    return days[day - 1];
  }
}
