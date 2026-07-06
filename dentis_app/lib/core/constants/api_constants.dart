class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "https://smarttooth-api.onrender.com",
  );

  static const String login = "/login";
  static const String usuarios = "/usuarios";
  static const String citas = "/citas";
}
