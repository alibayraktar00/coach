import 'package:table_calendar/table_calendar.dart';

import '../../data/models/event_model.dart';

/// Whole days between two dates, compared in UTC so daylight-saving shifts
/// can't turn a 23-hour day into a zero-day difference.
int _wholeDaysBetween(DateTime start, DateTime target) {
  final startUtc = DateTime.utc(start.year, start.month, start.day);
  final targetUtc = DateTime.utc(target.year, target.month, target.day);
  return targetUtc.difference(startUtc).inDays;
}

/// Whether [event] has an occurrence on [day], honouring its recurrence rule.
bool occursOn(EventModel event, DateTime day) {
  if (isSameDay(event.dateTime, day)) return true;

  final type = event.recurrenceType;
  if (type == null) return false;

  final start = DateTime(event.dateTime.year, event.dateTime.month, event.dateTime.day);
  final target = DateTime(day.year, day.month, day.day);

  if (target.isBefore(start)) return false;
  if (event.recurrenceUntil != null && target.isAfter(event.recurrenceUntil!)) return false;

  final interval = (event.recurrenceInterval ?? 1).clamp(1, 365);
  final days = _wholeDaysBetween(start, target);

  switch (type) {
    case 'daily':
      return days % interval == 0;
    case 'weekly':
      if (target.weekday != start.weekday) return false;
      return (days ~/ 7) % interval == 0;
    case 'monthly':
      if (target.day != start.day) return false;
      final months = (target.year - start.year) * 12 + (target.month - start.month);
      return months >= 0 && months % interval == 0;
    case 'yearly':
      if (target.day != start.day || target.month != start.month) return false;
      final years = target.year - start.year;
      return years >= 0 && years % interval == 0;
    default:
      return false;
  }
}

/// How far ahead [nextOccurrence] will look before giving up. Ten years covers
/// yearly rules with a large interval without ever scanning unbounded.
const int _maxLookaheadDays = 366 * 10;

/// The first occurrence of [event] at or after [from], or null if the rule has
/// already run out. Keeps the event's time of day.
DateTime? nextOccurrence(EventModel event, {required DateTime from}) {
  final time = event.dateTime;

  if (event.recurrenceType == null) {
    return time.isBefore(from) ? null : time;
  }

  final start = DateTime(time.year, time.month, time.day);
  var cursor = DateTime(from.year, from.month, from.day);
  if (cursor.isBefore(start)) cursor = start;

  for (var i = 0; i < _maxLookaheadDays; i++) {
    final ahead = cursor.add(Duration(days: i));
    // Re-normalise: adding days across a DST boundary can drift off midnight.
    final day = DateTime(ahead.year, ahead.month, ahead.day);

    if (event.recurrenceUntil != null && day.isAfter(event.recurrenceUntil!)) return null;
    if (!occursOn(event, day)) continue;

    final candidate = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    if (!candidate.isBefore(from)) return candidate;
  }

  return null;
}
