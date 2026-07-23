import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/glass_morphism.dart';
import '../../core/utils/notification_service.dart';
import '../../core/utils/event_provider.dart';
import '../../data/models/event_model.dart';

class EventEditorSheet extends ConsumerStatefulWidget {
  final EventModel event;

  const EventEditorSheet({super.key, required this.event});

  @override
  ConsumerState<EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends ConsumerState<EventEditorSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _tagController;
  late DateTime _selectedDate;
  int? _colorValue;
  late String _recurrenceType;
  late bool _reminderEnabled;
  late int _reminderMinutes;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descController = TextEditingController(text: widget.event.description ?? '');
    _tagController = TextEditingController(text: widget.event.tag ?? '');
    _selectedDate = widget.event.dateTime;
    _colorValue = widget.event.colorValue;
    _recurrenceType = widget.event.recurrenceType ?? 'none';
    _reminderEnabled = widget.event.isReminderEnabled;
    _reminderMinutes = widget.event.reminderMinutesBefore ?? 10;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) return;
    if (!mounted) return;
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = <Color>[
      AntigravityTheme.primary,
      AntigravityTheme.secondary,
      AntigravityTheme.accent,
      const Color(0xFFF59E0B),
      const Color(0xFF22C55E),
      const Color(0xFF06B6D4),
    ];

    final l10n = AppLocalizations.of(context)!;
    final isNew = widget.event.title.isEmpty && widget.event.id.startsWith('new_');

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isNew ? l10n.newEvent : widget.event.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isNew)
                  IconButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await ref.read(eventsProvider.notifier).deleteEvent(widget.event.id);
                      navigator.pop(true);
                    },
                    icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(LucideIcons.calendarClock, color: Colors.white70),
                    label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}  ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _recurrenceType,
              dropdownColor: const Color(0xFF1A1A2E),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Repeat',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('None')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (v) => setState(() => _recurrenceType = v ?? 'none'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _reminderEnabled,
                    onChanged: (v) => setState(() => _reminderEnabled = v),
                    title: const Text('Reminder', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<int>(
                    initialValue: _reminderMinutes,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5')),
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 15, child: Text('15')),
                      DropdownMenuItem(value: 30, child: Text('30')),
                      DropdownMenuItem(value: 60, child: Text('60')),
                    ],
                    onChanged: _reminderEnabled ? (v) => setState(() => _reminderMinutes = v ?? 10) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tagController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Tag',
                labelStyle: TextStyle(color: Colors.white70),
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
                    onTap: () => setState(() => _colorValue = c.toARGB32()),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
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
                        ),
                        if (_colorValue == c.toARGB32())
                          const Icon(LucideIcons.check, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => setState(() => _colorValue = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha((255 * 0.25).toInt())),
                    ),
                    child: const Text('Clear', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final updated = EventModel(
                  id: widget.event.id,
                  title: _titleController.text.trim().isEmpty ? widget.event.title : _titleController.text.trim(),
                  description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                  dateTime: _selectedDate,
                  audioUrl: widget.event.audioUrl,
                  isReminderEnabled: _reminderEnabled,
                  reminderMinutesBefore: _reminderEnabled ? _reminderMinutes : null,
                  colorValue: _colorValue,
                  tag: _tagController.text.trim().isEmpty ? null : _tagController.text.trim(),
                  recurrenceType: _recurrenceType == 'none' ? null : _recurrenceType,
                  recurrenceInterval: _recurrenceType == 'none' ? null : 1,
                  recurrenceUntil: null,
                );
                
                await ref.read(eventsProvider.notifier).updateEvent(updated);
                
                if (_reminderEnabled) {
                  await NotificationService.instance.scheduleEventReminder(
                    eventId: updated.id,
                    title: updated.title,
                    eventDateTime: updated.dateTime,
                    minutesBefore: _reminderMinutes,
                  );
                } else {
                  await NotificationService.instance.cancelEventReminder(updated.id);
                }
                
                navigator.pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AntigravityTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
