// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Coach';

  @override
  String get listening => 'Dinliyorum...';

  @override
  String confidence(String value) {
    return 'Doğruluk: $value%';
  }

  @override
  String get done => 'Bitti';

  @override
  String get newEvent => 'Yeni Etkinlik';

  @override
  String eventAdded(String title) {
    return 'Etkinlik eklendi: $title';
  }

  @override
  String get noEventsToday => 'Bu gün için etkinlik yok.';

  @override
  String get write => 'Yaz';

  @override
  String get voice => 'Ses';

  @override
  String get note => 'Not';

  @override
  String get settings => 'Ayarlar';

  @override
  String get language => 'Dil';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'İngilizce';

  @override
  String get theme => 'Tema';

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get system => 'Sistem';

  @override
  String get profile => 'Profil';

  @override
  String get name => 'İsim';

  @override
  String get email => 'E-posta';

  @override
  String get weight => 'Kilo';

  @override
  String get height => 'Boy';

  @override
  String get goal => 'Hedef';
}
