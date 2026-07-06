class CitaModel {
  final int? id;
  final int? usuarioId;
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
    return CitaModel(
      id: _toInt(json["id"]),
      usuarioId: _toInt(json["usuario_id"]),
      paciente: json["paciente"]?.toString() ?? "",
      servicio: json["servicio"]?.toString() ?? "Consulta Dental",
      doctor: json["doctor"]?.toString() ?? "Dr. Roberto Mendez",
      fecha: json["fecha"]?.toString() ?? "",
      hora: json["hora"]?.toString() ?? "",
      estado: json["estado"]?.toString() ?? "pendiente",
      notas: json["notas"]?.toString() ?? "",
      duracion: _toInt(json["duracion"]) ?? 45,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      "servicio": servicio,
      "doctor": doctor,
      "fecha": fecha,
      "hora": horaCorta,
      "notas": notas,
      "duracion": duracion,
    };
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

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
