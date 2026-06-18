class UsuarioModel {
  final int? id;
  final String nombre;
  final String email;
  final String telefono;
  final String password;

  UsuarioModel({
    this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "email": email,
      "telefono": telefono,
      "password": password,
    };
  }
}