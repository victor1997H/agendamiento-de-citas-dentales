import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/datasources/api_client.dart';
import '../data/datasources/local_database.dart';

class SyncService {
  static Future<void> sincronizar() async {
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return;
    }

    await _sincronizarUsuarios();
    await _sincronizarCitas();
  }

  static Future<void> _sincronizarUsuarios() async {
    final pendientes = await LocalDatabase.obtenerPendientes();

    for (var usuario in pendientes) {
      final enviado = await ApiClient.registrarUsuario({
        "nombre": usuario["nombre"],
        "email": usuario["email"],
        "telefono": usuario["telefono"],
        "password": usuario["password"],
      });

      if (enviado) {
        await LocalDatabase.marcarSincronizado(usuario["id"]);
      }
    }
  }

  static Future<void> _sincronizarCitas() async {
    final pendientes = await LocalDatabase.obtenerCitasPendientes();

    for (var cita in pendientes) {
      final enviada = await ApiClient.crearCita({
        "paciente": cita["paciente"],
        "servicio": cita["servicio"],
        "fecha": cita["fecha"],
        "notas": cita["notas"],
        "doctor_id": 1,
      });

      if (enviada) {
        await LocalDatabase.marcarCitaSincronizada(cita["id"]);
      }
    }
  }
}
