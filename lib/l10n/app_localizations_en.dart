// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Coach';

  @override
  String get listening => 'Listening...';

  @override
  String confidence(String value) {
    return 'Confidence: $value%';
  }

  @override
  String get done => 'Done';

  @override
  String eventAdded(String title) {
    return 'Event added: $title';
  }

  @override
  String get noEventsToday => 'No events for today.';

  @override
  String get write => 'Write';

  @override
  String get voice => 'Voice';

  @override
  String get note => 'Note';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get turkish => 'Turkish';

  @override
  String get english => 'English';
}
