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
  String get newEvent => 'New Event';

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

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get profile => 'Profile';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get weight => 'Weight';

  @override
  String get height => 'Height';

  @override
  String get goal => 'Goal';

  @override
  String get notSet => 'Not set';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get timeFormat => 'Time format';

  @override
  String get hour24 => '24-hour';

  @override
  String get hour12 => '12-hour';

  @override
  String get weekStart => 'Week starts on';

  @override
  String get monday => 'Monday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';
}
