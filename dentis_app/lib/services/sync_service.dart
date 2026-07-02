import 'package:connectivity_plus/connectivity_plus.dart';

import  '../data/datasources/api_client.dart';
import '../data/datasources/local_database.dart';

class SyncService {
  static Future<void> sincronizar() async {

    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();

    if (connectivityResult.contains(
      ConnectivityResult.none,
    )) {
      return;
    }

    final pendientes =
        await LocalDatabase.obtenerPendientes();

    for (var usuario in pendientes) {

      bool enviado =
          await ApiClient.registrarUsuario({
        "nombre": usuario["nombre"],
        "email": usuario["email"],
        "password": usuario["password"],
      });

      if (enviado) {
        await LocalDatabase.marcarSincronizado(
          usuario["id"],
        );
      }
    }
  }
}