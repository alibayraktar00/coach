import 'package:flutter_test/flutter_test.dart';

import 'package:coach/core/utils/nlp_parser.dart';

void main() {
  // A Wednesday, so weekday maths is easy to reason about.
  final now = DateTime(2026, 7, 15, 10, 0);

  DateTime dateOf(String text) =>
      NLPParser.parse(text, now: now)['dateTime'] as DateTime;
  String titleOf(String text) =>
      NLPParser.parse(text, now: now)['title'] as String;

  group('relative days', () {
    test('bugün, yarın, öbür gün', () {
      expect(dateOf('bugün saat 14 toplantı'), DateTime(2026, 7, 15, 14));
      expect(dateOf('yarın saat 14 toplantı'), DateTime(2026, 7, 16, 14));
      expect(dateOf('öbür gün saat 14 toplantı'), DateTime(2026, 7, 17, 14));
    });

    test('haftaya and gelecek hafta', () {
      expect(dateOf('haftaya saat 9 spor'), DateTime(2026, 7, 22, 9));
      expect(dateOf('gelecek hafta saat 9 spor'), DateTime(2026, 7, 22, 9));
    });

    test('X gün / hafta sonra, digits and words', () {
      expect(dateOf('3 gün sonra saat 9 kontrol'), DateTime(2026, 7, 18, 9));
      expect(dateOf('iki hafta sonra saat 9 kontrol'), DateTime(2026, 7, 29, 9));
    });
  });

  group('weekdays', () {
    test('picks the next matching weekday', () {
      // Wednesday the 15th -> Friday the 17th.
      expect(dateOf('cuma saat 9 toplantı'), DateTime(2026, 7, 17, 9));
      // Monday wraps into the following week.
      expect(dateOf('pazartesi saat 9 toplantı'), DateTime(2026, 7, 20, 9));
    });

    test('pazartesi is not read as pazar', () {
      expect(dateOf('pazartesi saat 9 toplantı'), DateTime(2026, 7, 20, 9));
      expect(dateOf('pazar saat 9 toplantı'), DateTime(2026, 7, 19, 9));
    });

    test('gelecek pushes a further week out', () {
      expect(dateOf('gelecek cuma saat 9 toplantı'), DateTime(2026, 7, 24, 9));
    });

    test('same weekday with a passed time rolls to next week', () {
      // Today is Wednesday; 09:00 already went by at 10:00.
      expect(dateOf('çarşamba saat 9 toplantı'), DateTime(2026, 7, 22, 9));
    });
  });

  group('explicit dates', () {
    test('day plus month name', () {
      expect(dateOf('15 ağustos saat 9 tatil'), DateTime(2026, 8, 15, 9));
    });

    test('a past day/month rolls into next year', () {
      expect(dateOf('3 ocak saat 9 tatil'), DateTime(2027, 1, 3, 9));
    });

    test('slashed numeric date', () {
      expect(dateOf('20/08 saat 9 tatil'), DateTime(2026, 8, 20, 9));
      expect(dateOf('20/08/2027 saat 9 tatil'), DateTime(2027, 8, 20, 9));
    });

    test('dotted pair without a year stays a time, not a date', () {
      // "15.30" must read as half past three, not the 15th of month 30.
      expect(dateOf('yarın 15:30 toplantı'), DateTime(2026, 7, 16, 15, 30));
    });
  });

  group('times', () {
    test('saat prefix and de/da suffix', () {
      expect(dateOf('yarın saat 9 spor'), DateTime(2026, 7, 16, 9));
      expect(dateOf("yarın 9'da spor"), DateTime(2026, 7, 16, 9));
    });

    test('buçuk means half past', () {
      expect(dateOf('yarın saat 8 buçukta spor'), DateTime(2026, 7, 16, 8, 30));
    });

    test('written numbers', () {
      expect(dateOf('yarın saat sekiz buçukta spor'), DateTime(2026, 7, 16, 8, 30));
      expect(dateOf('yarın saat on iki toplantı'), DateTime(2026, 7, 16, 12));
    });

    test('akşam and öğleden sonra shift to PM', () {
      expect(dateOf('yarın akşam 8 yemek'), DateTime(2026, 7, 16, 20));
      expect(dateOf('yarın öğleden sonra 3 toplantı'), DateTime(2026, 7, 16, 15));
    });

    test('gece keeps small hours in the morning', () {
      expect(dateOf('yarın gece 11 uçuş'), DateTime(2026, 7, 16, 23));
      expect(dateOf('yarın gece 2 uçuş'), DateTime(2026, 7, 16, 2));
    });

    test('explicit minutes', () {
      expect(dateOf('yarın saat 14:45 toplantı'), DateTime(2026, 7, 16, 14, 45));
    });

    test('part of day without a number', () {
      expect(dateOf('yarın sabah koşu'), DateTime(2026, 7, 16, 8));
      expect(dateOf('yarın akşam yemek'), DateTime(2026, 7, 16, 20));
    });

    test('a time already past today moves to tomorrow', () {
      // now is 10:00 and no date was given.
      expect(dateOf('saat 9 spor'), DateTime(2026, 7, 16, 9));
      expect(dateOf('saat 14 spor'), DateTime(2026, 7, 15, 14));
    });

    test('defaults to 09:00 when no time is given', () {
      expect(dateOf('yarın diş hekimi'), DateTime(2026, 7, 16, 9));
    });
  });

  group('bare numbers are not times', () {
    test('"bir toplantı" is not one o\'clock', () {
      final result = NLPParser.parse('yarın bir toplantı', now: now);
      expect(result['dateTime'], DateTime(2026, 7, 16, 9));
      expect(result['title'], 'Bir toplantı');
    });
  });

  group('title extraction', () {
    test('strips the date and time tokens', () {
      expect(titleOf('yarın saat 9 diş hekimi'), 'Diş hekimi');
      expect(titleOf('cuma akşam 8 yemek'), 'Yemek');
      expect(titleOf('15 ağustos tatil'), 'Tatil');
    });

    test('falls back when nothing is left', () {
      expect(titleOf('yarın saat 9'), 'Yeni Etkinlik');
    });

    test('capitalises with the Turkish dotted capital', () {
      expect(titleOf('yarın izin'), 'İzin');
    });
  });
}
