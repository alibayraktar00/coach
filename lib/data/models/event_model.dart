class EventModel {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final String? audioUrl;
  final bool isReminderEnabled;
  final int? reminderMinutesBefore;
  final int? colorValue;
  final String? tag;
  /// null = no recurrence. Values: daily, weekly, monthly, yearly
  final String? recurrenceType;
  final int? recurrenceInterval;
  final DateTime? recurrenceUntil;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.audioUrl,
    this.isReminderEnabled = false,
    this.reminderMinutesBefore,
    this.colorValue,
    this.tag,
    this.recurrenceType,
    this.recurrenceInterval,
    this.recurrenceUntil,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_time': dateTime.toIso8601String(),
      'audio_url': audioUrl,
      'is_reminder_enabled': isReminderEnabled ? 1 : 0,
      'reminder_minutes_before': reminderMinutesBefore,
      'color_value': colorValue,
      'tag': tag,
      'recurrence_type': recurrenceType,
      'recurrence_interval': recurrenceInterval,
      'recurrence_until': recurrenceUntil?.toIso8601String(),
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
      reminderMinutesBefore: map['reminder_minutes_before'],
      colorValue: map['color_value'],
      tag: map['tag'],
      recurrenceType: map['recurrence_type'],
      recurrenceInterval: map['recurrence_interval'],
      recurrenceUntil: map['recurrence_until'] != null ? DateTime.tryParse(map['recurrence_until']) : null,
    );
  }
  
  // For Supabase
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['date_time'] ?? json['created_at']),
      audioUrl: json['audio_url'],
      isReminderEnabled: json['is_reminder_enabled'] ?? false,
      reminderMinutesBefore: json['reminder_minutes_before'],
      colorValue: json['color_value'],
      tag: json['tag'],
      recurrenceType: json['recurrence_type'],
      recurrenceInterval: json['recurrence_interval'],
      recurrenceUntil: json['recurrence_until'] != null ? DateTime.tryParse(json['recurrence_until']) : null,
    );
  }
}
