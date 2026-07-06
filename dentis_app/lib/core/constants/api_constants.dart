class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://192.168.100.70:5000",
  );

  static const String login = "/login";
  static const String usuarios = "/usuarios";
  static const String citas = "/citas";
}
