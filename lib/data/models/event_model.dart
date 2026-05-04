class EventModel {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final String? audioUrl;
  final bool isReminderEnabled;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.audioUrl,
    this.isReminderEnabled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_time': dateTime.toIso8601String(),
      'audio_url': audioUrl,
      'is_reminder_enabled': isReminderEnabled ? 1 : 0,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dateTime: DateTime.parse(map['date_time']),
      audioUrl: map['audio_url'],
      isReminderEnabled: map['is_reminder_enabled'] == 1,
    );
  }
  
  // For Supabase
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['created_at']), // Or a specific date field
      audioUrl: json['audio_url'],
      isReminderEnabled: json['is_reminder_enabled'] ?? false,
    );
  }
}
