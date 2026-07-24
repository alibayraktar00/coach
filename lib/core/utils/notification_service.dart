import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/event_model.dart';
import 'recurrence.dart';

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
    // Android 12+ gates exact alarms behind their own grant; without it the
    // scheduled reminders silently degrade to inexact delivery.
    await androidImpl?.requestExactAlarmsPermission();
  }

  /// Re-arms the reminder for a single event at its next upcoming occurrence,
  /// or cancels it when the event no longer wants one.
  Future<void> syncEventReminder(EventModel event) async {
    final minutesBefore = event.reminderMinutesBefore;
    if (!event.isReminderEnabled || minutesBefore == null) {
      await cancelEventReminder(event.id);
      return;
    }

    // Look for the first occurrence whose lead time hasn't already elapsed.
    final leadTime = Duration(minutes: minutesBefore);
    final next = nextOccurrence(event, from: DateTime.now().add(leadTime));
    if (next == null) {
      await cancelEventReminder(event.id);
      return;
    }

    await scheduleEventReminder(
      eventId: event.id,
      title: event.title,
      eventDateTime: next,
      minutesBefore: minutesBefore,
    );
  }

  /// Rebuilds the whole reminder schedule from stored events.
  ///
  /// Android drops pending alarms on reboot, and a one-shot alarm is consumed
  /// once it fires, so a recurring event would otherwise only ever notify once.
  Future<void> syncEventReminders(List<EventModel> events) async {
    for (final event in events) {
      await syncEventReminder(event);
    }
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
