import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:coach/core/utils/event_provider.dart';
import 'package:coach/data/models/event_model.dart';
import 'package:coach/data/repositories/local_event_repository.dart';

/// In-memory stand-in so the providers can be exercised without sqflite.
class _FakeEventRepository implements LocalEventRepository {
  _FakeEventRepository(this._events);

  final List<EventModel> _events;

  @override
  Future<Database> get database => throw UnimplementedError();

  @override
  Future<List<EventModel>> getEvents() async => _events;

  @override
  Future<void> insertEvent(EventModel event) async {
    _events.removeWhere((e) => e.id == event.id);
    _events.add(event);
  }

  @override
  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
  }
}

EventModel _event({
  required String id,
  required String title,
  required DateTime dateTime,
  String? tag,
  String? recurrenceType,
  int? recurrenceInterval,
  DateTime? recurrenceUntil,
}) {
  return EventModel(
    id: id,
    title: title,
    dateTime: dateTime,
    tag: tag,
    recurrenceType: recurrenceType,
    recurrenceInterval: recurrenceInterval,
    recurrenceUntil: recurrenceUntil,
  );
}

Future<ProviderContainer> _containerWith(List<EventModel> events) async {
  final container = ProviderContainer(
    overrides: [
      eventRepositoryProvider.overrideWithValue(_FakeEventRepository(events)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(eventsProvider.future);
  return container;
}

void main() {
  group('recurrence expansion', () {
    test('non-recurring event shows only on its own day', () async {
      final container = await _containerWith([
        _event(id: '1', title: 'Dentist', dateTime: DateTime(2026, 1, 1, 9)),
      ]);

      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 1);
      expect(container.read(filteredEventsProvider), hasLength(1));

      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 2);
      expect(container.read(filteredEventsProvider), isEmpty);
    });

    test('daily recurrence honours the interval', () async {
      final container = await _containerWith([
        _event(
          id: '1',
          title: 'Gym',
          dateTime: DateTime(2026, 1, 1, 7),
          recurrenceType: 'daily',
          recurrenceInterval: 2,
        ),
      ]);

      // Day 0 and day 2 match, day 1 and day 3 do not.
      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 1);
      expect(container.read(filteredEventsProvider), hasLength(1));

      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 2);
      expect(container.read(filteredEventsProvider), isEmpty);

      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 3);
      expect(container.read(filteredEventsProvider), hasLength(1));

      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 4);
      expect(container.read(filteredEventsProvider), isEmpty);
    });

    test('weekly recurrence honours the interval', () async {
      final container = await _containerWith([
        _event(
          id: '1',
          title: 'Standup',
          dateTime: DateTime(2026, 1, 1, 10),
          recurrenceType: 'weekly',
          recurrenceInterval: 2,
        ),
      ]);

      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 8);
      expect(container.read(filteredEventsProvider), isEmpty);

      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 15);
      expect(container.read(filteredEventsProvider), hasLength(1));
    });

    test('recurrenceUntil stops expansion and includes the final day', () async {
      final container = await _containerWith([
        _event(
          id: '1',
          title: 'Course',
          dateTime: DateTime(2026, 1, 1, 18),
          recurrenceType: 'daily',
          recurrenceInterval: 1,
          // Stored end-of-day, the way the editor saves it.
          recurrenceUntil: DateTime(2026, 1, 3, 23, 59, 59),
        ),
      ]);

      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 3);
      expect(container.read(filteredEventsProvider), hasLength(1));

      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 4);
      expect(container.read(filteredEventsProvider), isEmpty);
    });

    test('expanded occurrence keeps the original time of day', () async {
      final container = await _containerWith([
        _event(
          id: '1',
          title: 'Gym',
          dateTime: DateTime(2026, 1, 1, 7, 30),
          recurrenceType: 'daily',
          recurrenceInterval: 1,
        ),
      ]);

      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 5);
      final occurrence = container.read(filteredEventsProvider).single;
      expect(occurrence.dateTime, DateTime(2026, 1, 5, 7, 30));
    });
  });

  group('global search', () {
    test('finds events outside the selected day', () async {
      final container = await _containerWith([
        _event(id: '1', title: 'Dentist', dateTime: DateTime(2026, 3, 20, 9)),
        _event(id: '2', title: 'Groceries', dateTime: DateTime(2026, 1, 2, 9)),
      ]);

      container.read(selectedDayProvider.notifier).state = DateTime(2026, 1, 1);
      container.read(searchQueryProvider.notifier).state = 'dentist';

      // The day-scoped list sees nothing on Jan 1...
      expect(container.read(filteredEventsProvider), isEmpty);
      // ...while the global search still finds the March event.
      final results = container.read(globalSearchResultsProvider);
      expect(results, hasLength(1));
      expect(results.single.title, 'Dentist');
    });

    test('matches description and tag, and respects the tag filter', () async {
      final container = await _containerWith([
        _event(id: '1', title: 'Call', dateTime: DateTime(2026, 1, 5), tag: 'work'),
        _event(id: '2', title: 'Call', dateTime: DateTime(2026, 1, 6), tag: 'home'),
      ]);

      container.read(searchQueryProvider.notifier).state = 'call';
      expect(container.read(globalSearchResultsProvider), hasLength(2));

      container.read(tagFilterProvider.notifier).state = 'work';
      final results = container.read(globalSearchResultsProvider);
      expect(results, hasLength(1));
      expect(results.single.tag, 'work');
    });

    test('empty query returns no results', () async {
      final container = await _containerWith([
        _event(id: '1', title: 'Call', dateTime: DateTime(2026, 1, 5)),
      ]);

      container.read(searchQueryProvider.notifier).state = '   ';
      expect(container.read(globalSearchResultsProvider), isEmpty);
    });

    test('results are sorted chronologically', () async {
      final container = await _containerWith([
        _event(id: '1', title: 'Call late', dateTime: DateTime(2026, 5, 1)),
        _event(id: '2', title: 'Call early', dateTime: DateTime(2026, 2, 1)),
      ]);

      container.read(searchQueryProvider.notifier).state = 'call';
      final results = container.read(globalSearchResultsProvider);
      expect(results.map((e) => e.title), ['Call early', 'Call late']);
    });
  });

  group('allTagsProvider', () {
    test('collects unique tags across all days, sorted', () async {
      final container = await _containerWith([
        _event(id: '1', title: 'A', dateTime: DateTime(2026, 1, 1), tag: 'work'),
        _event(id: '2', title: 'B', dateTime: DateTime(2026, 6, 1), tag: 'apple'),
        _event(id: '3', title: 'C', dateTime: DateTime(2026, 7, 1), tag: 'work'),
        _event(id: '4', title: 'D', dateTime: DateTime(2026, 8, 1)),
      ]);

      expect(container.read(allTagsProvider), ['apple', 'work']);
    });
  });
}
