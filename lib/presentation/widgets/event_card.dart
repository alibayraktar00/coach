import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_settings.dart';
import '../../core/utils/glass_morphism.dart';
import '../../core/utils/time_format.dart';
import '../../data/models/event_model.dart';

class EventCard extends ConsumerWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chipColor = event.colorValue != null ? Color(event.colorValue!) : null;
    final use24Hour =
        ref.watch(appSettingsProvider).valueOrNull?.use24HourFormat ?? true;
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
            borderRadius: BorderRadius.circular(24),
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            formatDateTime(event.dateTime, use24Hour),
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
