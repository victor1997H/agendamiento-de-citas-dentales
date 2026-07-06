import 'dart:convert';

import 'package:http/http.dart' as http;

import '../datasources/api_client.dart';
import '../datasources/session_datasource.dart';
import '../models/cita_model.dart';

class DoctorRepository {
  Map<String, String> get _headers {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${SessionDataSource.token}",
    };
  }

  Future<Map<String, dynamic>> getResumen() async {
    final response = await http.get(
      Uri.parse("${ApiClient.baseUrl}/doctor/resumen"),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      return {
        "citas_hoy": 0,
        "completadas": 0,
        "pendientes": 0,
        "este_mes": 0,
      };
    }

    final body = jsonDecode(response.body);
    return Map<String, dynamic>.from(body["resumen"] ?? {});
  }

  Future<List<CitaModel>> getCitasHoy() async {
    final response = await http.get(
      Uri.parse("${ApiClient.baseUrl}/doctor/citas-hoy"),
      headers: _headers,
    );

    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body);
    final List data = body["citas"] ?? [];

    return data
        .map((item) => CitaModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<CitaModel>> getCitas() async {
    final response = await http.get(
      Uri.parse("${ApiClient.baseUrl}/doctor/citas"),
      headers: _headers,
    );

    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body);
    final List data = body["citas"] ?? [];

    return data
        .map((item) => CitaModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getDisponibilidad() async {
    final response = await http.get(
      Uri.parse("${ApiClient.baseUrl}/doctor/disponibilidad"),
      headers: _headers,
    );

    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body);
    final List data = body["bloques"] ?? [];

    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<bool> guardarDisponibilidad(List<Map<String, dynamic>> bloques) async {
    final response = await http.put(
      Uri.parse("${ApiClient.baseUrl}/doctor/disponibilidad"),
      headers: _headers,
      body: jsonEncode({"bloques": bloques}),
    );

    return response.statusCode == 200;
  }

  Future<bool> actualizarEstado(int id, String estado) async {
    final response = await http.put(
      Uri.parse("${ApiClient.baseUrl}/doctor/citas/$id/estado"),
      headers: _headers,
      body: jsonEncode({"estado": estado}),
    );

    return response.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> getPacientes() async {
    final response = await http.get(
      Uri.parse("${ApiClient.baseUrl}/doctor/pacientes"),
      headers: _headers,
    );

    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body);
    final List data = body["pacientes"] ?? [];

    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }
}
