import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_datasource.dart';

class ApiClient {
  // IMPORTANTE: usa IP fija de tu PC
  static const String baseUrl = "http://192.168.100.13:5000";

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

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN BODY: ${response.body}");

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

  // ================= FORGOT PASSWORD =================
  static Future<bool> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
      }),
    );

    print("FORGOT PASSWORD STATUS: ${response.statusCode}");
    print("FORGOT PASSWORD BODY: ${response.body}");

    return response.statusCode == 200;
  }

  // ================= RESET PASSWORD =================
  static Future<bool> resetPassword(
    String email,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "new_password": newPassword,
      }),
    );

    print("RESET PASSWORD STATUS: ${response.statusCode}");
    print("RESET PASSWORD BODY: ${response.body}");

    return response.statusCode == 200;
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
      Uri.parse("$baseUrl/citas"),
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
}