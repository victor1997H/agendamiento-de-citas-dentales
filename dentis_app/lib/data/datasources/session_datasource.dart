class SessionDataSource {
  static String token = "";
  static String rol = "";
  static Map<String, dynamic> user = {};

  static void saveSession({
    required String newToken,
    required Map<String, dynamic> newUser,
  }) {
    token = newToken;
    user = newUser;
    rol = newUser["rol"] ?? "";
  }

  static void clear() {
    token = "";
    user = {};
    rol = "";
  }

  static bool get isLoggedIn => token.isNotEmpty;
}