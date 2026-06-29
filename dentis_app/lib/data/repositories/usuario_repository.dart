import '../datasources/api_client.dart';
import '../models/usuario_model.dart';

class UsuarioRepository {

  Future<bool> registrarUsuario(UsuarioModel usuario) async {
    return await ApiClient.registrarUsuario(usuario.toJson());
  }

  Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    return await ApiClient.login(email, password);
  }
}