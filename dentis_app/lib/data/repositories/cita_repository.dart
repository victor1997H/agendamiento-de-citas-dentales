import '../datasources/api_client.dart';

class CitaRepository {

  // 🔥 obtener todas las citas
  Future<List<dynamic>> getCitas() async {
    return await ApiClient.getCitas();
  }

  // 🔥 crear nueva cita
  Future<bool> crearCita(Map<String, dynamic> data) async {
    return await ApiClient.crearCita(data);
  }

  // 🔥 actualizar estado de cita
  Future<bool> actualizarCita(Map<String, dynamic> data) async {
    return await ApiClient.actualizarCita(data);
  }

  // 🔥 eliminar cita (opcional)
  Future<bool> eliminarCita(int id) async {
    return await ApiClient.eliminarCita(id);
  }
}