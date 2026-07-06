import '../datasources/api_client.dart';
import '../models/cita_model.dart';

class CitaRepository {
  Future<List<CitaModel>> getMisCitas() async {
    return await ApiClient.getMisCitas();
  }

  Future<bool> crearCita(CitaModel cita) async {
    return await ApiClient.crearCita(cita);
  }

  Future<bool> cancelarCita(int id) async {
    return await ApiClient.cancelarCita(id);
  }
}