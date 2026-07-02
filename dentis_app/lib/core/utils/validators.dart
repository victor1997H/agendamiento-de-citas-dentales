class Validators {

  static String? email(String value) {
    if (value.isEmpty) return "Email requerido";
    if (!value.contains("@")) return "Email inválido";
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return "Contraseña requerida";
    if (value.length < 6) return "Mínimo 6 caracteres";
    return null;
  }

  static String? notEmpty(String value, String field) {
    if (value.isEmpty) return "$field es obligatorio";
    return null;
  }
}