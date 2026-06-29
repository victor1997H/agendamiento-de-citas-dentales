class UsuarioModel {
  final int? id;
  final String nombre;
  final String email;
  final String telefono;
  final String password;
  final String rol;

  UsuarioModel({
    this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.password,
    this.rol = "usuario",
  });

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "email": email,
      "telefono": telefono,
      "password": password,
      "rol": rol,
    };
  }

  // 🔥 OPCIONAL (recomendado): para leer desde backend
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json["id"],
      nombre: json["nombre"],
      email: json["email"],
      telefono: json["telefono"] ?? "",
      password: json["password"] ?? "",
      rol: json["rol"] ?? "usuario",
    );
  }
}