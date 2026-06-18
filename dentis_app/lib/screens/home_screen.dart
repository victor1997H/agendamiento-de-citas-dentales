import 'package:flutter/material.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 👇 Usuario logueado (luego lo conectamos a backend real)
  final String doctorName = "Luis";

  // 👇 Simulación de citas (después vendrán de API o SQLite)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFD4AF37),
        centerTitle: true,
        title: const Text(
          "DENTIS APP",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFFD4AF37)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Dr. $doctorName",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text("Citas"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Pacientes"),
              onTap: () {},
            ),

            const Spacer(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Cerrar sesión"),
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bienvenido Dr. $doctorName 👋",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            const Text(
              "Aquí están las citas del día",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // 🔥 LISTA DE CITAS
            Expanded(
              child: ListView.builder(
                itemCount: citas.length,
                itemBuilder: (context, index) {
                  final cita = citas[index];

                  Color color;
                  if (cita["estado"] == "aceptada") {
                    color = Colors.green;
                  } else if (cita["estado"] == "rechazada") {
                    color = Colors.red;
                  } else {
                    color = Colors.orange;
                  }

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
                          "Paciente: ${cita["paciente"]}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text("Fecha: ${cita["fecha"]}"),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                cita["estado"].toString().toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),

                            const Spacer(),

                            if (cita["estado"] == "pendiente") ...[
                              TextButton(
                                onPressed: () => aceptarCita(index),
                                child: const Text("Aceptar"),
                              ),
                              TextButton(
                                onPressed: () => rechazarCita(index),
                                child: const Text(
                                  "Rechazar",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ],
                        ),
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
}
