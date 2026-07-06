import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/cita_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Guayaquil'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleAppointmentReminder(CitaModel cita) async {
    final date = DateTime.tryParse(cita.fechaIso);
    if (date == null || date.isBefore(DateTime.now())) return;

    final reminder = date.subtract(const Duration(hours: 2));
    final scheduledAt = reminder.isAfter(DateTime.now())
        ? reminder
        : DateTime.now().add(const Duration(minutes: 1));

    final id = cita.id ?? date.millisecondsSinceEpoch.remainder(100000);

    await _plugin.zonedSchedule(
      id,
      'Recordatorio de cita odontológica',
      '${cita.servicio} con ${cita.doctor} a las ${cita.horaCorta}',
      tz.TZDateTime.from(scheduledAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'citas_recordatorios',
          'Recordatorios de citas',
          channelDescription: 'Avisos antes de tus citas odontológicas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
