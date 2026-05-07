import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/glass_morphism.dart';
import '../widgets/floating_calendar.dart';
import '../widgets/voice_input_overlay.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/local_event_repository.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/utils/app_settings.dart';
import '../../core/utils/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final LocalEventRepository _repository = LocalEventRepository();
  List<EventModel> _events = [];
  DateTime _selectedDay = DateTime.now();
  bool _searchOpen = false;
  String _query = '';
  String? _tagFilter;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await _repository.getEvents();
    setState(() => _events = events);
  }

  void _showVoiceInput() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VoiceInputOverlay(
        onResult: (title, dateTime) async {
          final newEvent = EventModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            dateTime: dateTime,
          );
          final messenger = ScaffoldMessenger.of(context);
          await _repository.insertEvent(newEvent);
          _loadEvents();
          
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.eventAdded(title)),
              backgroundColor: AntigravityTheme.primary,
            ),
          );
        },
      ),
    );
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.read(localeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.language, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.turkish, style: const TextStyle(color: Colors.white)),
              trailing: currentLocale.languageCode == 'tr' ? const Icon(LucideIcons.check, color: AntigravityTheme.primary) : null,
              onTap: () {
                ref.read(appSettingsProvider.notifier).setLocale(const Locale('tr'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.english, style: const TextStyle(color: Colors.white)),
              trailing: currentLocale.languageCode == 'en' ? const Icon(LucideIcons.check, color: AntigravityTheme.primary) : null,
              onTap: () {
                ref.read(appSettingsProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBackupDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    final exportJson = jsonEncode(_events.map((e) => e.toMap()).toList());
    final importController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Backup', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Export (copy)', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((255 * 0.25).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha((255 * 0.14).toInt())),
                ),
                child: SelectableText(
                  exportJson,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: exportJson));
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Copied backup JSON')),
                  );
                },
                icon: const Icon(LucideIcons.copy),
                label: const Text('Copy'),
              ),
              const SizedBox(height: 16),
              const Text('Import (paste JSON)', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              TextField(
                controller: importController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Paste JSON here',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AntigravityTheme.primary),
            onPressed: () async {
              try {
                final decoded = jsonDecode(importController.text) as List;
                for (final item in decoded) {
                  final map = Map<String, dynamic>.from(item as Map);
                  final event = EventModel.fromMap(map);
                  await _repository.insertEvent(event);
                }
                await _loadEvents();
                if (!context.mounted) return;
                Navigator.of(context).pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Import complete')),
                );
              } catch (e) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Import failed: $e')),
                );
              }
            },
            child: const Text('Import', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openEventEditor(EventModel event) async {
    final titleController = TextEditingController(text: event.title);
    final descController = TextEditingController(text: event.description ?? '');
    final tagController = TextEditingController(text: event.tag ?? '');
    DateTime selected = event.dateTime;
    int? colorValue = event.colorValue;
    String recurrenceType = event.recurrenceType ?? 'none';
    bool reminderEnabled = event.isReminderEnabled;
    int reminderMinutes = event.reminderMinutesBefore ?? 10;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(24),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final sheetContext = context;
                Future<void> pickDateTime() async {
                  final date = await showDatePicker(
                    context: sheetContext,
                    initialDate: selected,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context),
                      child: child!,
                    ),
                  );
                  if (date == null) return;
                  if (!sheetContext.mounted) return;
                  final time = await showTimePicker(
                    context: sheetContext,
                    initialTime: TimeOfDay.fromDateTime(selected),
                  );
                  if (time == null) return;
                  if (!sheetContext.mounted) return;
                  setModalState(() {
                    selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                }

                Widget colorDot(Color c) => Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha((255 * 0.5).toInt()),
                          width: 1,
                        ),
                      ),
                    );

                final palette = <Color>[
                  AntigravityTheme.primary,
                  AntigravityTheme.secondary,
                  AntigravityTheme.accent,
                  const Color(0xFFF59E0B),
                  const Color(0xFF22C55E),
                  const Color(0xFF06B6D4),
                ];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await _repository.deleteEvent(event.id);
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop(true);
                            _loadEvents();
                          },
                          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: pickDateTime,
                            icon: const Icon(LucideIcons.calendarClock),
                            label: Text(
                              '${selected.day}/${selected.month}/${selected.year}  ${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: recurrenceType,
                      decoration: const InputDecoration(
                        labelText: 'Repeat',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('None')),
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                      ],
                      onChanged: (v) => setModalState(() => recurrenceType = v ?? 'none'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: reminderEnabled,
                            onChanged: (v) => setModalState(() => reminderEnabled = v),
                            title: const Text('Reminder'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<int>(
                            initialValue: reminderMinutes,
                            decoration: const InputDecoration(
                              labelText: 'Minutes',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 5, child: Text('5')),
                              DropdownMenuItem(value: 10, child: Text('10')),
                              DropdownMenuItem(value: 15, child: Text('15')),
                              DropdownMenuItem(value: 30, child: Text('30')),
                              DropdownMenuItem(value: 60, child: Text('60')),
                            ],
                            onChanged: reminderEnabled ? (v) => setModalState(() => reminderMinutes = v ?? 10) : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tagController,
                      decoration: const InputDecoration(
                        labelText: 'Tag',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in palette)
                          InkWell(
                            borderRadius: BorderRadius.circular(99),
                            onTap: () => setModalState(() => colorValue = c.toARGB32()),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                colorDot(c),
                                if (colorValue == c.toARGB32())
                                  const Icon(LucideIcons.check, size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                        InkWell(
                          borderRadius: BorderRadius.circular(99),
                          onTap: () => setModalState(() => colorValue = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withAlpha((255 * 0.25).toInt())),
                            ),
                            child: const Text('Clear'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () async {
                        final updated = EventModel(
                          id: event.id,
                          title: titleController.text.trim().isEmpty ? event.title : titleController.text.trim(),
                          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                          dateTime: selected,
                          audioUrl: event.audioUrl,
                          isReminderEnabled: reminderEnabled,
                          reminderMinutesBefore: reminderEnabled ? reminderMinutes : null,
                          colorValue: colorValue,
                          tag: tagController.text.trim().isEmpty ? null : tagController.text.trim(),
                          recurrenceType: recurrenceType == 'none' ? null : recurrenceType,
                          recurrenceInterval: recurrenceType == 'none' ? null : 1,
                          recurrenceUntil: null,
                        );
                        await _repository.insertEvent(updated);
                        if (reminderEnabled) {
                          await NotificationService.instance.scheduleEventReminder(
                            eventId: updated.id,
                            title: updated.title,
                            eventDateTime: updated.dateTime,
                            minutesBefore: reminderMinutes,
                          );
                        } else {
                          await NotificationService.instance.cancelEventReminder(updated.id);
                        }
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop(true);
                        _loadEvents();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AntigravityTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 6),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (result == true) {
      // already reloaded; keep for clarity
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allForDay = _expandEventsForDay(_events, _selectedDay);
    final tags = allForDay.map((e) => e.tag).whereType<String>().toSet().toList()..sort();
    final selectedDayEvents = allForDay.where((e) {
      final q = _query.trim().toLowerCase();
      if (_tagFilter != null && e.tag != _tagFilter) return false;
      if (q.isEmpty) return true;
      final hay = '${e.title} ${e.description ?? ''} ${e.tag ?? ''}'.toLowerCase();
      return hay.contains(q);
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradients
          Positioned(
            top: -100,
            right: -50,
            child: _GlowCircle(color: AntigravityTheme.primary.withAlpha((255 * 0.3).toInt()), size: 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _GlowCircle(color: AntigravityTheme.secondary.withAlpha((255 * 0.2).toInt()), size: 400),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _IconGlassButton(
                        icon: LucideIcons.settings,
                        onTap: _showLanguageDialog,
                      ),
                      const SizedBox(width: 10),
                      _IconGlassButton(
                        icon: _searchOpen ? LucideIcons.x : LucideIcons.search,
                        onTap: () => setState(() {
                          _searchOpen = !_searchOpen;
                          if (!_searchOpen) _query = '';
                        }),
                      ),
                      const Spacer(),
                      Text(l10n.appTitle, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26)),
                      const Spacer(),
                      _IconGlassButton(
                        icon: LucideIcons.cloudDownload,
                        onTap: _showBackupDialog,
                      ),
                    ],
                  ),
                  if (_searchOpen) ...[
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(LucideIcons.search),
                        filled: true,
                        fillColor: Colors.white.withAlpha((255 * 0.06).toInt()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withAlpha((255 * 0.14).toInt())),
                        ),
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('All'),
                                selected: _tagFilter == null,
                                onSelected: (_) => setState(() => _tagFilter = null),
                              ),
                            ),
                            for (final t in tags)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(t),
                                  selected: _tagFilter == t,
                                  onSelected: (_) => setState(() => _tagFilter = t),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 18),
                  FloatingCalendar(
                    initialSelectedDay: _selectedDay,
                    onSelectedDayChanged: (d) => setState(() => _selectedDay = d),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: selectedDayEvents.isEmpty
                        ? GlassContainer(
                            padding: const EdgeInsets.all(18),
                            child: Center(
                              child: Text(
                                l10n.noEventsToday,
                                style: TextStyle(color: Colors.white.withAlpha((255 * 0.7).toInt())),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: selectedDayEvents.length,
                            itemBuilder: (context, index) => _EventCard(
                              event: selectedDayEvents[index],
                              onTap: () => _openEventEditor(selectedDayEvents[index]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Container(
            decoration: BoxDecoration(boxShadow: AntigravityTheme.floatingShadow),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              borderRadius: BorderRadius.circular(28),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionPill(
                      icon: LucideIcons.penLine,
                      label: l10n.write,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionPill(
                      icon: LucideIcons.mic,
                      label: l10n.voice,
                      onTap: _showVoiceInput,
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionPill(
                      icon: LucideIcons.notebookPen,
                      label: l10n.note,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<EventModel> _expandEventsForDay(List<EventModel> base, DateTime day) {
  final result = <EventModel>[];
  for (final e in base) {
    if (isSameDay(e.dateTime, day)) {
      result.add(e);
      continue;
    }

    final type = e.recurrenceType;
    if (type == null) continue;
    if (day.isBefore(DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))) continue;
    if (e.recurrenceUntil != null && day.isAfter(e.recurrenceUntil!)) continue;

    final interval = (e.recurrenceInterval ?? 1).clamp(1, 365);
    final start = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
    final target = DateTime(day.year, day.month, day.day);

    bool matches = false;
    switch (type) {
      case 'daily':
        matches = target.difference(start).inDays % interval == 0;
        break;
      case 'weekly':
        if (target.weekday == start.weekday) {
          matches = (target.difference(start).inDays ~/ 7) % interval == 0;
        }
        break;
      case 'monthly':
        if (target.day == start.day) {
          final months = (target.year - start.year) * 12 + (target.month - start.month);
          matches = months >= 0 && months % interval == 0;
        }
        break;
      case 'yearly':
        if (target.day == start.day && target.month == start.month) {
          final years = target.year - start.year;
          matches = years >= 0 && years % interval == 0;
        }
        break;
    }

    if (matches) {
      // Generate a "virtual occurrence" for that day, keeping same time of day
      final occurrenceDateTime = DateTime(
        day.year,
        day.month,
        day.day,
        e.dateTime.hour,
        e.dateTime.minute,
      );
      result.add(
        EventModel(
          id: e.id,
          title: e.title,
          description: e.description,
          dateTime: occurrenceDateTime,
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

class _IconGlassButton extends StatelessWidget {
  const _IconGlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(10),
        borderRadius: BorderRadius.circular(18),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary
        ? AntigravityTheme.primary.withAlpha((255 * 0.35).toInt())
        : Colors.white.withAlpha((255 * 0.05).toInt());

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withAlpha((255 * 0.16).toInt())),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const _EventCard({required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chipColor = event.colorValue != null ? Color(event.colorValue!) : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: AntigravityTheme.floatingShadow,
          ),
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (chipColor ?? AntigravityTheme.primary).withAlpha((255 * 0.2).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.calendarDays,
                    color: chipColor ?? AntigravityTheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year} - ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.white.withAlpha((255 * 0.6).toInt()),
                              fontSize: 14,
                            ),
                          ),
                          if (event.tag != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((255 * 0.06).toInt()),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withAlpha((255 * 0.14).toInt()),
                                ),
                              ),
                              child: Text(
                                event.tag!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withAlpha((255 * 0.85).toInt()),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
        ),
      ),
    );
  }
}
