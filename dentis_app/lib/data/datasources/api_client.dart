import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/cita_model.dart';
import 'session_datasource.dart';

class ApiClient {
  static const String baseUrl = "http://192.168.100.14:5000";

  static Map<String, String> get _jsonHeaders => {
        "Content-Type": "application/json",
      };

  static Map<String, String> get _authHeaders => {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${SessionDataSource.token}",
      };

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: _jsonHeaders,
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

  static Future<bool> registrarUsuario(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/usuarios"),
      headers: _jsonHeaders,
      body: jsonEncode(data),
    );

    return response.statusCode == 201;
  }

  static Future<bool> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: _jsonHeaders,
      body: jsonEncode({"email": email}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> resetPassword(
    String email,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: _jsonHeaders,
      body: jsonEncode({
        "email": email,
        "new_password": newPassword,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<CitaModel>> getMisCitas() async {
    final response = await http.get(
      Uri.parse("$baseUrl/mis-citas"),
      headers: _authHeaders,
    );

    if (response.statusCode != 200) {
      return [];
    }

    final body = jsonDecode(response.body);
    final List data = body["citas"] ?? [];

    return data
        .map((item) => CitaModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<bool> crearCita(CitaModel cita) async {
    final response = await http.post(
      Uri.parse("$baseUrl/citas"),
      headers: _authHeaders,
      body: jsonEncode(cita.toCreateJson()),
    );

    return response.statusCode == 201;
  }

  static Future<bool> cancelarCita(int id) async {
    final response = await http.put(
      Uri.parse("$baseUrl/citas/$id/cancelar"),
      headers: _authHeaders,
    );

    return response.statusCode == 200;
  }
}