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

  Future<bool> forgotPassword(String email) async {
    return await ApiClient.forgotPassword(email);
  }

  Future<bool> resetPassword(
    String email,
    String newPassword,
  ) async {
    return await ApiClient.resetPassword(email, newPassword);
  }

  Future<Map<String, dynamic>?> actualizarPerfil(
    Map<String, dynamic> data,
  ) async {
    return await ApiClient.actualizarPerfil(data);
  }
}
