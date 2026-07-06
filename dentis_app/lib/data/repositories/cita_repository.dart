import '../datasources/api_client.dart';
import '../datasources/local_database.dart';
import '../datasources/session_datasource.dart';
import '../models/cita_model.dart';

class CitaRepository {
  Future<List<dynamic>> getCitas() async {
    try {
      return await ApiClient.getCitas();
    } catch (_) {
      return await LocalDatabase.obtenerCitasLocales();
    }
  }

  Future<List<CitaModel>> getMisCitas() async {
    final citas = await getCitas();
    return citas
        .whereType<Map>()
        .map((item) => CitaModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<bool> crearCita(Object data) async {
    final payload = _payloadFrom(data);

    try {
      return await ApiClient.crearCita(payload);
    } catch (_) {
      await LocalDatabase.guardarCitaLocal({
        ...payload,
        "estado": "pendiente",
        "sincronizado": 0,
      });
      return true;
    }
  }

  Future<bool> actualizarCita(Map<String, dynamic> data) async {
    return await ApiClient.actualizarCita(data);
  }

  Future<bool> eliminarCita(int id) async {
    return await ApiClient.eliminarCita(id);
  }

  Future<bool> cancelarCita(int id) async {
    return await ApiClient.cancelarCita(id);
  }

  Map<String, dynamic> _payloadFrom(Object data) {
    if (data is CitaModel) {
      return data.toCreateJson(
        pacienteFallback: SessionDataSource.user["nombre"]?.toString(),
      );
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw ArgumentError("Tipo de cita no soportado");
  }
}
