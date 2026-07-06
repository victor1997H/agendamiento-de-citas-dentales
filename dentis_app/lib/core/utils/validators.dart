class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  static final RegExp _phoneRegExp = RegExp(
    r'^\+?[0-9]{7,15}$',
  );

  static String? email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return "Correo requerido";
    if (!_emailRegExp.hasMatch(trimmed)) return "Correo inválido";
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return "Contraseña requerida";
    if (value.length < 8) return "Mínimo 8 caracteres";
    if (!RegExp(r'[A-Z]').hasMatch(value)) return "Incluye una mayúscula";
    if (!RegExp(r'[a-z]').hasMatch(value)) return "Incluye una minúscula";
    if (!RegExp(r'[0-9]').hasMatch(value)) return "Incluye un número";
    return null;
  }

  static String? phone(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[\s()-]'), '');
    if (normalized.isEmpty) return "Teléfono requerido";
    if (!_phoneRegExp.hasMatch(normalized)) return "Teléfono inválido";
    return null;
  }

  static String? notEmpty(String value, String field) {
    if (value.trim().isEmpty) return "$field es obligatorio";
    return null;
  }
}
