import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'core/utils/app_settings.dart';
import 'l10n/app_localizations.dart';
import 'core/utils/notification_service.dart';
import 'data/repositories/local_event_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(
    const ProviderScope(
      child: CoachApp(),
    ),
  );
  // Fire-and-forget so restoring alarms never delays the first frame.
  unawaited(_restoreReminders());
}

/// Reboots clear pending alarms, so rebuild the schedule from stored events on
/// every launch. Also advances recurring reminders past occurrences that fired.
Future<void> _restoreReminders() async {
  try {
    final events = await LocalEventRepository().getEvents();
    await NotificationService.instance.syncEventReminders(events);
  } catch (e) {
    debugPrint('Reminder restore failed: $e');
  }
}

class CoachApp extends ConsumerWidget {
  const CoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    
    return settingsAsync.when(
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: Text('Settings load error: $e')),
        ),
      ),
      data: (settings) => MaterialApp(
        title: 'Coach',
        debugShowCheckedModeBanner: false,
        theme: AntigravityTheme.lightTheme,
        darkTheme: AntigravityTheme.darkTheme,
        themeMode: settings.themeMode,
        locale: settings.locale,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    );
  }
}
