import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = "http://192.168.100.13:5000";

  // ================= LOGIN =================
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // ================= REGISTER =================
  static Future<bool> registrarUsuario(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/usuarios");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 201;
  }
}
