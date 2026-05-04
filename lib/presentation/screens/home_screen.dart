import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/glass_morphism.dart';
import '../widgets/floating_calendar.dart';
import '../widgets/voice_input_overlay.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/local_event_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalEventRepository _repository = LocalEventRepository();
  List<EventModel> _events = [];

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
              content: Text('Etkinlik eklendi: $title'),
              backgroundColor: AntigravityTheme.primary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hoş Geldin,',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  'Coach',
                                  style: Theme.of(context).textTheme.displayLarge,
                                ),
                              ],
                            ),
                            const GlassContainer(
                              padding: EdgeInsets.all(12),
                              child: Icon(LucideIcons.user, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        const FloatingCalendar(),
                        const SizedBox(height: 30),
                        const Text(
                          'Yaklaşan Etkinlikler',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = _events[index];
                        return _EventCard(event: event);
                      },
                      childCount: _events.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AntigravityTheme.primary.withAlpha((255 * 0.4).toInt()),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.large(
          onPressed: _showVoiceInput,
          backgroundColor: AntigravityTheme.primary,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(LucideIcons.mic, size: 32, color: Colors.white),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                  color: AntigravityTheme.primary.withAlpha((255 * 0.2).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.calendarDays, color: AntigravityTheme.primary),
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
                    const SizedBox(height: 4),
                    Text(
                      '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year} - ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.white.withAlpha((255 * 0.6).toInt()), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
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
