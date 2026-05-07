import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  int _stableIdFromString(String input) {
    // Keep it inside 32-bit signed int range.
    return input.codeUnits.fold<int>(0, (p, c) => (p * 31 + c) & 0x7fffffff);
  }

  Future<void> cancelEventReminder(String eventId) async {
    await _plugin.cancel(_stableIdFromString(eventId));
  }

  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime eventDateTime,
    required int minutesBefore,
  }) async {
    final scheduled = eventDateTime.subtract(Duration(minutes: minutesBefore));
    if (scheduled.isBefore(DateTime.now())) {
      // Don't schedule past reminders.
      return;
    }

    final id = _stableIdFromString(eventId);

    const androidDetails = AndroidNotificationDetails(
      'event_reminders',
      'Event reminders',
      channelDescription: 'Reminders for scheduled events',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        'Upcoming event',
        tz.TZDateTime.from(scheduled, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Notification schedule error: $e');
    }
  }
}
