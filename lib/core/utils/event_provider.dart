import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/local_event_repository.dart';
import 'recurrence.dart';

final eventRepositoryProvider = Provider((ref) => LocalEventRepository());

class EventsNotifier extends AsyncNotifier<List<EventModel>> {
  @override
  Future<List<EventModel>> build() async {
    return ref.read(eventRepositoryProvider).getEvents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(eventRepositoryProvider).getEvents());
  }

  Future<void> addEvent(EventModel event) async {
    await ref.read(eventRepositoryProvider).insertEvent(event);
    await refresh();
  }

  Future<void> updateEvent(EventModel event) async {
    await ref.read(eventRepositoryProvider).insertEvent(event);
    await refresh();
  }

  Future<void> deleteEvent(String id) async {
    await ref.read(eventRepositoryProvider).deleteEvent(id);
    await refresh();
  }
}

final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<EventModel>>(EventsNotifier.new);

final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

final searchQueryProvider = StateProvider<String>((ref) => '');

final tagFilterProvider = StateProvider<String?>((ref) => null);

final filteredEventsProvider = Provider<List<EventModel>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final selectedDay = ref.watch(selectedDayProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final tagFilter = ref.watch(tagFilterProvider);

  return eventsAsync.when(
    data: (events) {
      final allForDay = _expandEventsForDay(events, selectedDay);
      return allForDay.where((e) {
        if (tagFilter != null && e.tag != tagFilter) return false;
        if (query.isEmpty) return true;
        final haystack = '${e.title} ${e.description ?? ''} ${e.tag ?? ''}'.toLowerCase();
        return haystack.contains(query);
      }).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    },
    loading: () => [],
    error: (e, st) => [],
  );
});

/// Searches every stored event instead of only the selected day.
/// Returns the base events (not per-day occurrences) so a match is listed once.
/// An empty query yields an empty list — the caller falls back to the day view.
final globalSearchResultsProvider = Provider<List<EventModel>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final tagFilter = ref.watch(tagFilterProvider);

  if (query.isEmpty) return [];

  return eventsAsync.maybeWhen(
    data: (events) => events.where((e) {
      if (tagFilter != null && e.tag != tagFilter) return false;
      final haystack = '${e.title} ${e.description ?? ''} ${e.tag ?? ''}'.toLowerCase();
      return haystack.contains(query);
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime)),
    orElse: () => [],
  );
});

/// Tags across all events, for filtering while searching globally.
final allTagsProvider = Provider<List<String>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);

  return eventsAsync.maybeWhen(
    data: (events) => events
        .map((e) => e.tag)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort(),
    orElse: () => [],
  );
});

final availableTagsProvider = Provider<List<String>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final selectedDay = ref.watch(selectedDayProvider);

  return eventsAsync.maybeWhen(
    data: (events) {
      final allForDay = _expandEventsForDay(events, selectedDay);
      return allForDay
          .map((e) => e.tag)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
    },
    orElse: () => [],
  );
});

List<EventModel> _expandEventsForDay(List<EventModel> base, DateTime day) {
  final result = <EventModel>[];
  for (final e in base) {
    if (isSameDay(e.dateTime, day)) {
      result.add(e);
      continue;
    }

    if (occursOn(e, day)) {
      result.add(
        EventModel(
          id: e.id,
          title: e.title,
          description: e.description,
          dateTime: DateTime(day.year, day.month, day.day, e.dateTime.hour, e.dateTime.minute),
          audioUrl: e.audioUrl,
          isReminderEnabled: e.isReminderEnabled,
          reminderMinutesBefore: e.reminderMinutesBefore,
          colorValue: e.colorValue,
          tag: e.tag,
          recurrenceType: e.recurrenceType,
          recurrenceInterval: e.recurrenceInterval,
          recurrenceUntil: e.recurrenceUntil,
        ),
      );
    }
  }
  return result;
}
