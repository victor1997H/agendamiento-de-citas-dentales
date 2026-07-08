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

  Future<bool> requestPasswordResetCode(String email) async {
    return await ApiClient.requestPasswordResetCode(email);
  }

  Future<String?> verifyResetCode(
    String email,
    String code,
  ) async {
    return await ApiClient.verifyResetCode(email, code);
  }

  Future<bool> resetPassword(
    String email,
    String resetToken,
    String newPassword,
  ) async {
    return await ApiClient.resetPassword(email, resetToken, newPassword);
  }

  Future<Map<String, dynamic>?> actualizarPerfil(
    Map<String, dynamic> data,
  ) async {
    return await ApiClient.actualizarPerfil(data);
  }
}
