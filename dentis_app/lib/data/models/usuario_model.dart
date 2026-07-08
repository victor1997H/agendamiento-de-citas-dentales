class UsuarioModel {
  final int? id;
  final String nombre;
  final String email;
  final String telefono;
  final String? password;
  final String rol;

  UsuarioModel({
    this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    this.password,
    this.rol = "usuario",
  });

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "email": email,
      "telefono": telefono,
      if (password != null) "password": password,
      "rol": rol,
    };
  }

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json["id"],
      nombre: json["nombre"],
      email: json["email"],
      telefono: json["telefono"] ?? "",
      rol: json["rol"] ?? "usuario",
    );
  }
}
