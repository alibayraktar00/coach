import 'package:flutter_test/flutter_test.dart';

import 'package:coach/core/utils/recurrence.dart';
import 'package:coach/data/models/event_model.dart';

EventModel _event({
  required DateTime dateTime,
  String? recurrenceType,
  int? recurrenceInterval,
  DateTime? recurrenceUntil,
}) {
  return EventModel(
    id: '1',
    title: 'Gym',
    dateTime: dateTime,
    recurrenceType: recurrenceType,
    recurrenceInterval: recurrenceInterval,
    recurrenceUntil: recurrenceUntil,
  );
}

void main() {
  group('nextOccurrence - non-recurring', () {
    test('returns the event itself when still upcoming', () {
      final event = _event(dateTime: DateTime(2026, 5, 10, 9));
      expect(
        nextOccurrence(event, from: DateTime(2026, 5, 1)),
        DateTime(2026, 5, 10, 9),
      );
    });

    test('returns null once it is in the past', () {
      final event = _event(dateTime: DateTime(2026, 5, 10, 9));
      expect(nextOccurrence(event, from: DateTime(2026, 5, 11)), isNull);
    });

    test('is inclusive of the exact start instant', () {
      final event = _event(dateTime: DateTime(2026, 5, 10, 9));
      expect(
        nextOccurrence(event, from: DateTime(2026, 5, 10, 9)),
        DateTime(2026, 5, 10, 9),
      );
    });
  });

  group('nextOccurrence - recurring', () {
    test('advances past occurrences that already fired', () {
      final event = _event(
        dateTime: DateTime(2026, 1, 1, 7),
        recurrenceType: 'daily',
        recurrenceInterval: 1,
      );
      // Long after the first occurrence: the reminder must move forward.
      expect(
        nextOccurrence(event, from: DateTime(2026, 3, 15, 12)),
        DateTime(2026, 3, 16, 7),
      );
    });

    test('same day before the time returns today', () {
      final event = _event(
        dateTime: DateTime(2026, 1, 1, 7),
        recurrenceType: 'daily',
        recurrenceInterval: 1,
      );
      expect(
        nextOccurrence(event, from: DateTime(2026, 3, 15, 6)),
        DateTime(2026, 3, 15, 7),
      );
    });

    test('honours a daily interval', () {
      final event = _event(
        dateTime: DateTime(2026, 1, 1, 7),
        recurrenceType: 'daily',
        recurrenceInterval: 3,
      );
      // Jan 1, 4, 7, 10... so from Jan 5 the next is Jan 7.
      expect(
        nextOccurrence(event, from: DateTime(2026, 1, 5)),
        DateTime(2026, 1, 7, 7),
      );
    });

    test('honours a weekly interval', () {
      final event = _event(
        dateTime: DateTime(2026, 1, 1, 10),
        recurrenceType: 'weekly',
        recurrenceInterval: 2,
      );
      expect(
        nextOccurrence(event, from: DateTime(2026, 1, 9)),
        DateTime(2026, 1, 15, 10),
      );
    });

    test('honours monthly and yearly rules', () {
      final monthly = _event(
        dateTime: DateTime(2026, 1, 20, 8),
        recurrenceType: 'monthly',
        recurrenceInterval: 1,
      );
      expect(
        nextOccurrence(monthly, from: DateTime(2026, 1, 21)),
        DateTime(2026, 2, 20, 8),
      );

      final yearly = _event(
        dateTime: DateTime(2026, 3, 5, 8),
        recurrenceType: 'yearly',
        recurrenceInterval: 1,
      );
      expect(
        nextOccurrence(yearly, from: DateTime(2026, 3, 6)),
        DateTime(2027, 3, 5, 8),
      );
    });

    test('returns null once recurrenceUntil has passed', () {
      final event = _event(
        dateTime: DateTime(2026, 1, 1, 7),
        recurrenceType: 'daily',
        recurrenceInterval: 1,
        recurrenceUntil: DateTime(2026, 1, 3, 23, 59, 59),
      );
      expect(nextOccurrence(event, from: DateTime(2026, 1, 2)), DateTime(2026, 1, 2, 7));
      expect(nextOccurrence(event, from: DateTime(2026, 1, 4)), isNull);
    });

    test('does not start before the first occurrence', () {
      final event = _event(
        dateTime: DateTime(2026, 6, 1, 7),
        recurrenceType: 'daily',
        recurrenceInterval: 1,
      );
      expect(
        nextOccurrence(event, from: DateTime(2026, 1, 1)),
        DateTime(2026, 6, 1, 7),
      );
    });
  });

  group('occursOn', () {
    test('matches the original day regardless of recurrence', () {
      final event = _event(dateTime: DateTime(2026, 1, 1, 7));
      expect(occursOn(event, DateTime(2026, 1, 1)), isTrue);
      expect(occursOn(event, DateTime(2026, 1, 2)), isFalse);
    });

    test('does not match days before the start', () {
      final event = _event(
        dateTime: DateTime(2026, 1, 10, 7),
        recurrenceType: 'daily',
        recurrenceInterval: 1,
      );
      expect(occursOn(event, DateTime(2026, 1, 9)), isFalse);
      expect(occursOn(event, DateTime(2026, 1, 11)), isTrue);
    });
  });
}
