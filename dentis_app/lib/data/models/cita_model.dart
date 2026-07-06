class CitaModel {
  final int? id;
  final int? usuarioId;
  final int? doctorId;
  final String paciente;
  final String servicio;
  final String doctor;
  final String fecha;
  final String hora;
  final String estado;
  final String notas;
  final int duracion;

  const CitaModel({
    this.id,
    this.usuarioId,
    this.doctorId,
    this.paciente = "",
    required this.servicio,
    required this.doctor,
    required this.fecha,
    required this.hora,
    this.estado = "pendiente",
    this.notas = "",
    this.duracion = 45,
  });

  factory CitaModel.fromJson(Map<String, dynamic> json) {
    final rawFecha = json["fecha"]?.toString() ?? "";
    final parsedFecha = DateTime.tryParse(rawFecha);
    final rawHora = json["hora"]?.toString();

    return CitaModel(
      id: _toInt(json["id"] ?? json["remoto_id"]),
      usuarioId: _toInt(json["usuario_id"]),
      doctorId: _toInt(json["doctor_id"]),
      paciente: json["paciente"]?.toString() ?? "",
      servicio: json["servicio"]?.toString() ?? "Consulta Dental",
      doctor: json["doctor"]?.toString() ?? "Dr. Roberto Mendez",
      fecha: parsedFecha == null ? rawFecha : _formatDate(parsedFecha),
      hora: _normalizeHora(rawHora, parsedFecha),
      estado: json["estado"]?.toString() ?? "pendiente",
      notas: json["notas"]?.toString() ?? "",
      duracion: _toInt(json["duracion"] ?? json["duracion_minutos"]) ?? 45,
    );
  }

  Map<String, dynamic> toCreateJson({String? pacienteFallback}) {
    return {
      "paciente": paciente.trim().isNotEmpty
          ? paciente.trim()
          : (pacienteFallback ?? "Paciente"),
      "servicio": servicio,
      "doctor_id": doctorId ?? 1,
      "fecha": fechaIso,
      "notas": notas,
    };
  }

  String get fechaIso {
    final date = DateTime.tryParse(fecha);
    final pieces = horaCorta.split(":");
    final hour = pieces.isNotEmpty ? int.tryParse(pieces[0]) ?? 0 : 0;
    final minute = pieces.length > 1 ? int.tryParse(pieces[1]) ?? 0 : 0;

    if (date == null) {
      return fecha;
    }

    return DateTime(date.year, date.month, date.day, hour, minute)
        .toIso8601String();
  }

  String get horaCorta {
    if (hora.length >= 5) return hora.substring(0, 5);
    return hora;
  }

  String get fechaHoraTexto => "$fecha $horaCorta";

  String get fechaResumen {
    final parsed = DateTime.tryParse(fecha);
    if (parsed == null) return fecha;

    const meses = [
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

    return "${parsed.day} ${meses[parsed.month - 1]}";
  }

  bool get estaCancelada => estado.toLowerCase() == "cancelada";
  bool get estaPendiente => estado.toLowerCase() == "pendiente";
  bool get estaConfirmada => estado.toLowerCase() == "confirmada";
  bool get estaCompletada => estado.toLowerCase() == "completada";
  bool get estaNoAsistio => estado.toLowerCase() == "no_asistio";

  String get estadoTexto {
    if (estaNoAsistio) return "No asistió";
    if (estaCancelada) return "Cancelada";
    if (estaConfirmada) return "Aceptada";
    if (estaCompletada) return "Completada";
    return "Pendiente";
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String _formatDate(DateTime date) {
    return "${date.year}-${_two(date.month)}-${_two(date.day)}";
  }

  static String _normalizeHora(String? rawHora, DateTime? parsedFecha) {
    if (rawHora != null && rawHora.isNotEmpty) {
      return rawHora.length >= 5 ? rawHora.substring(0, 5) : rawHora;
    }

    if (parsedFecha == null) {
      return "";
    }

    return "${_two(parsedFecha.hour)}:${_two(parsedFecha.minute)}";
  }

  static String _two(int value) {
    return value.toString().padLeft(2, "0");
  }
}
