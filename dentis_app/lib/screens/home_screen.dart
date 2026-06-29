import 'package:flutter/material.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nombre = "";
  String rol = "";

  List<Map<String, dynamic>> citas = [
    {
      "paciente": "María López",
      "fecha": "15 Junio - 10:00 AM",
      "estado": "pendiente",
    },
    {
      "paciente": "Juan Pérez",
      "fecha": "15 Junio - 11:00 AM",
      "estado": "pendiente",
    },
    {
      "paciente": "Ana Torres",
      "fecha": "15 Junio - 12:00 PM",
      "estado": "aceptada",
    },
  ];

  @override
  void initState() {
    super.initState();

    nombre = widget.user["nombre"] ?? "Usuario";
    rol = widget.user["rol"] ?? "usuario";
  }

  void aceptarCita(int index) {
    setState(() {
      citas[index]["estado"] = "aceptada";
    });
  }

  void rechazarCita(int index) {
    setState(() {
      citas[index]["estado"] = "rechazada";
    });
  }

  Color estadoColor(String estado) {
    switch (estado) {
      case "aceptada":
        return Colors.green.shade700;
      case "rechazada":
        return Colors.red.shade700;
      default:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3D2E),
        title: const Text(
          "SMARTTOOTH",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF0B3D2E),
          child: Column(
            children: [
              DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 40, color: Color(0xFF0B3D2E)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      rol.toUpperCase(),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              _drawerItem(Icons.calendar_month, "Citas"),
              _drawerItem(Icons.people, "Pacientes"),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text("Cerrar sesión",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bienvenido $nombre 👋",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B3D2E),
              ),
            ),
            const SizedBox(height: 5),
            Text("Rol: $rol", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: citas.length,
                itemBuilder: (context, index) {
                  final cita = citas[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cita["paciente"],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B3D2E),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text("Fecha: ${cita["fecha"]}"),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: estadoColor(cita["estado"]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                cita["estado"].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const Spacer(),
                            if (cita["estado"] == "pendiente") ...[
                              TextButton(
                                  onPressed: () => aceptarCita(index),
                                  child: const Text("Aceptar")),
                              TextButton(
                                  onPressed: () => rechazarCita(index),
                                  child: const Text("Rechazar",
                                      style: TextStyle(color: Colors.red))),
                            ]
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: () {},
    );
  }
}
