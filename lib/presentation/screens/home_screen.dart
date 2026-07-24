import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/glass_morphism.dart';
import '../widgets/floating_calendar.dart';
import '../widgets/voice_input_overlay.dart';
import '../widgets/icon_glass_button.dart';
import '../widgets/action_pill.dart';
import '../widgets/glow_circle.dart';
import '../widgets/event_card.dart';
import '../widgets/event_editor_sheet.dart';
import 'settings_screen.dart';
import '../../data/models/event_model.dart';
import '../../core/utils/event_provider.dart';
import '../../core/utils/app_settings.dart';
import '../../core/utils/time_format.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _searchOpen = false;

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
          await ref.read(eventsProvider.notifier).addEvent(newEvent);
          
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

  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Future<void> _showBackupDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    final events = ref.read(eventsProvider).valueOrNull ?? [];
    final exportJson = jsonEncode(events.map((e) => e.toMap()).toList());
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
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Paste JSON here',
                  hintStyle: TextStyle(color: Colors.white38),
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
                  await ref.read(eventsProvider.notifier).addEvent(event);
                }
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

  void _openEventEditor(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventEditorSheet(event: event),
    );
  }

  void _createNewEvent({String? tag}) {
    final selectedDay = ref.read(selectedDayProvider);
    final now = DateTime.now();
    
    // Use selected day but current time if it's today
    final eventTime = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      now.hour,
      now.minute,
    );

    final newEvent = EventModel(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      title: '',
      dateTime: eventTime,
      tag: tag,
    );
    
    _openEventEditor(newEvent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDay = ref.watch(selectedDayProvider);
    final filteredEvents = ref.watch(filteredEventsProvider);
    final tagFilter = ref.watch(tagFilterProvider);

    // While searching, look across all days instead of only the selected one.
    final isSearching = _searchOpen && ref.watch(searchQueryProvider).trim().isNotEmpty;
    final searchResults = ref.watch(globalSearchResultsProvider);
    final tags = ref.watch(_searchOpen ? allTagsProvider : availableTagsProvider);
    final visibleEvents = isSearching ? searchResults : filteredEvents;

    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final weekStartDay = settings?.weekStartDay ?? DateTime.monday;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: GlowCircle(color: AntigravityTheme.primary.withAlpha((255 * 0.3).toInt()), size: 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: GlowCircle(color: AntigravityTheme.secondary.withAlpha((255 * 0.2).toInt()), size: 400),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconGlassButton(
                        icon: LucideIcons.settings,
                        onTap: _showSettings,
                      ),
                      const SizedBox(width: 10),
                      IconGlassButton(
                        icon: _searchOpen ? LucideIcons.x : LucideIcons.search,
                        onTap: () => setState(() {
                          _searchOpen = !_searchOpen;
                          if (!_searchOpen) {
                            ref.read(searchQueryProvider.notifier).state = '';
                            ref.read(tagFilterProvider.notifier).state = null;
                          }
                        }),
                      ),
                      const Spacer(),
                      Text(l10n.appTitle, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26)),
                      const Spacer(),
                      IconGlassButton(
                        icon: LucideIcons.cloudDownload,
                        onTap: _showBackupDialog,
                      ),
                    ],
                  ),
                  if (_searchOpen) ...[
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(LucideIcons.search, color: Colors.white70),
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
                                selected: tagFilter == null,
                                onSelected: (_) => ref.read(tagFilterProvider.notifier).state = null,
                              ),
                            ),
                            for (final t in tags)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(t),
                                  selected: tagFilter == t,
                                  onSelected: (_) => ref.read(tagFilterProvider.notifier).state = t,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 18),
                  FloatingCalendar(
                    initialSelectedDay: selectedDay,
                    weekStartDay: weekStartDay,
                    onSelectedDayChanged: (d) => ref.read(selectedDayProvider.notifier).state = d,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isSearching
                          ? '${searchResults.length} results'
                          : formatDate(selectedDay),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: visibleEvents.isEmpty
                        ? GlassContainer(
                            padding: const EdgeInsets.all(18),
                            child: Center(
                              child: Text(
                                isSearching ? 'No matching events' : l10n.noEventsToday,
                                style: TextStyle(color: Colors.white.withAlpha((255 * 0.7).toInt())),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: visibleEvents.length,
                            itemBuilder: (context, index) => EventCard(
                              event: visibleEvents[index],
                              onTap: () => _openEventEditor(visibleEvents[index]),
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
                    child: ActionPill(
                      icon: LucideIcons.penLine,
                      label: l10n.write,
                      onTap: () => _createNewEvent(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ActionPill(
                      icon: LucideIcons.mic,
                      label: l10n.voice,
                      onTap: _showVoiceInput,
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ActionPill(
                      icon: LucideIcons.notebookPen,
                      label: l10n.note,
                      onTap: () => _createNewEvent(tag: 'Note'),
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
