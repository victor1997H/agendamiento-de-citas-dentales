import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/cita_model.dart';
import '../data/repositories/cita_repository.dart';

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  final CitaRepository repository = CitaRepository();

  List<CitaModel> citas = [];
  bool loading = true;

  static const azulOscuro = AppTheme.primaryDark;
  static const rojo = AppTheme.danger;
  static const naranja = Color(0xffF1B64B);
  static const verde = Color(0xff2FA884);
  static const cancelado = Color(0xff6FA8B8);

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void _msg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> cargar() async {
    setState(() => loading = true);

    final data = await repository.getMisCitas();

    if (!mounted) return;

    setState(() {
      citas = data;
      loading = false;
    });
  }

  Future<void> cancelar(CitaModel cita) async {
    if (cita.id == null) return;

    final ok = await repository.cancelarCita(cita.id!);

    if (!mounted) return;

    if (ok) {
      _msg("Cita cancelada");
      cargar();
    } else {
      _msg("No se pudo cancelar");
    }
  }

  Color estadoColor(CitaModel cita) {
    if (cita.estaNoAsistio) return rojo;
    if (cita.estaCancelada) return cancelado;
    if (cita.estaConfirmada || cita.estaCompletada) return verde;
    return naranja;
  }

  IconData estadoIcon(CitaModel cita) {
    if (cita.estaNoAsistio) return Icons.timer_off_outlined;
    if (cita.estaCancelada) return Icons.cancel_outlined;
    if (cita.estaConfirmada || cita.estaCompletada) {
      return Icons.check_circle_outline;
    }
    return Icons.hourglass_empty;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("Mis citas"),
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : citas.isEmpty
              ? Center(
                  child: Text(
                    "Todavia no tienes citas",
                    style: TextStyle(color: colors.muted),
                  ),
                )
              : RefreshIndicator(
                  color: colors.primary,
                  onRefresh: cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: citas.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _legend();
                      final cita = citas[index - 1];
                      final color = estadoColor(cita);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: colors.panel,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colors.border),
                          boxShadow: colors.softShadow == null
                              ? null
                              : [colors.softShadow!],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: colors.isLight
                                        ? colors.primary.withValues(alpha: .12)
                                        : azulOscuro,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.medical_services,
                                    color: colors.isLight
                                        ? colors.primary
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cita.servicio,
                                        style: TextStyle(
                                          color: colors.text,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        cita.doctor,
                                        style: TextStyle(color: colors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: .18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(estadoIcon(cita),
                                          color: color, size: 15),
                                      const SizedBox(width: 4),
                                      Text(
                                        cita.estadoTexto,
                                        style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              cita.fechaHoraTexto,
                              style: TextStyle(color: colors.subtle),
                            ),
                            if (cita.notas.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                cita.notas,
                                style: TextStyle(color: colors.muted),
                              ),
                            ],
                            if (!cita.estaCancelada &&
                                !cita.estaNoAsistio &&
                                !cita.estaCompletada) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => cancelar(cita),
                                  icon: const Icon(Icons.close),
                                  label: const Text("Cancelar"),
                                  style: TextButton.styleFrom(
                                      foregroundColor: rojo),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _legend() {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: colors.softShadow == null ? null : [colors.softShadow!],
      ),
      child: const Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          _LegendItem(
              color: naranja, icon: Icons.hourglass_empty, text: "Pendiente"),
          _LegendItem(
              color: verde, icon: Icons.check_circle_outline, text: "Aceptada"),
          _LegendItem(
              color: cancelado, icon: Icons.cancel_outlined, text: "Cancelada"),
          _LegendItem(
              color: rojo, icon: Icons.timer_off_outlined, text: "No asistió"),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
