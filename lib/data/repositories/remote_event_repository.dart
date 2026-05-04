import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

class RemoteEventRepository {
  final _supabase = Supabase.instance.client;

  Future<void> syncEvent(EventModel event) async {
    try {
      await _supabase.from('events').upsert(event.toMap());
    } catch (e) {
      debugPrint('Supabase Sync Error: $e');
    }
  }

  Future<List<EventModel>> fetchEvents() async {
    try {
      final response = await _supabase.from('events').select().order('date_time');
      return (response as List).map((json) => EventModel.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Supabase Fetch Error: $e');
      return [];
    }
  }
}
