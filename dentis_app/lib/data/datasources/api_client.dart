import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import 'session_datasource.dart';

class ApiClient {
  static const String baseUrl = ApiConstants.baseUrl;

  // ================= LOGIN =================
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // ================= REGISTER =================
  static Future<bool> registrarUsuario(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/usuarios"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 201;
  }

  // ================= PASSWORD RESET =================
  static Future<bool> requestPasswordResetCode(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> verifyResetCode(
    String email,
    String code,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verify-reset-code"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "code": code,
      }),
    );

    return response.statusCode == 200;
  }

  // ================= RESET PASSWORD =================
  static Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "code": code,
        "new_password": newPassword,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> actualizarPerfil(
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/me"),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // ================= HEADERS CON JWT =================
  static Map<String, String> get _headers {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${SessionDataSource.token}",
    };
  }

  // ================= CITAS =================
  static Future<List<dynamic>> getCitas() async {
    final response = await http.get(
      Uri.parse("$baseUrl/citas"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<List<String>> getHorasDisponibles(String fecha) async {
    final response = await http.get(
      Uri.parse("$baseUrl/disponibilidad/horas?fecha=$fecha"),
      headers: _headers,
    );

    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body);
    final List data = body["horas"] ?? [];

    return data.map((item) => item.toString()).toList();
  }

  static Future<bool> crearCita(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/citas"),
      headers: _headers,
      body: jsonEncode(data),
    );

    return response.statusCode == 201;
  }

  static Future<bool> actualizarCita(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$baseUrl/citas/${data["id"]}"),
      headers: _headers,
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  static Future<bool> eliminarCita(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/citas/$id"),
      headers: _headers,
    );

    return response.statusCode == 200;
  }

  static Future<bool> cancelarCita(int id) async {
    final response = await http.put(
      Uri.parse("$baseUrl/citas/$id/cancelar"),
      headers: _headers,
    );

    return response.statusCode == 200;
  }
}
