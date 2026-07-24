/// Turns a spoken Turkish phrase into an event title and date/time.
///
/// Recognised date forms: bugün, yarın, öbür gün, haftaya / gelecek hafta,
/// weekday names (optionally prefixed with gelecek/önümüzdeki), "3 gün sonra",
/// "15 ağustos", "15/08/2026" and "15.08.2026".
///
/// Recognised time forms: "saat 9", "9'da", "akşam 8", "sekiz buçukta",
/// "14:30", "öğleden sonra 3". A bare number with no time marker is left alone
/// so "bir toplantı" is not read as one o'clock.
class NLPParser {
  static const Map<String, int> _numberWords = {
    'sıfır': 0,
    'bir': 1,
    'iki': 2,
    'üç': 3,
    'dört': 4,
    'beş': 5,
    'altı': 6,
    'yedi': 7,
    'sekiz': 8,
    'dokuz': 9,
    'on': 10,
    'on bir': 11,
    'on iki': 12,
    'yirmi': 20,
    'otuz': 30,
  };

  /// Longest-first so "on bir" wins over "on".
  static const List<String> _numberWordsByLength = [
    'on bir', 'on iki', 'sıfır', 'dört', 'yedi', 'sekiz', 'dokuz',
    'yirmi', 'otuz', 'altı', 'beş', 'üç', 'bir', 'iki', 'on',
  ];

  static const Map<String, int> _months = {
    'ocak': 1,
    'şubat': 2,
    'mart': 3,
    'nisan': 4,
    'mayıs': 5,
    'haziran': 6,
    'temmuz': 7,
    'ağustos': 8,
    'eylül': 9,
    'ekim': 10,
    'kasım': 11,
    'aralık': 12,
  };

  /// Longest-first so "pazartesi" wins over "pazar".
  static const Map<String, int> _weekdays = {
    'pazartesi': DateTime.monday,
    'salı': DateTime.tuesday,
    'çarşamba': DateTime.wednesday,
    'perşembe': DateTime.thursday,
    'cumartesi': DateTime.saturday,
    'cuma': DateTime.friday,
    'pazar': DateTime.sunday,
  };

  /// Turkish letters, so a word boundary does not fire inside "birlikte".
  static const String _letter = 'a-zçğıioöşüâîû';

  static String get _numberAlternation =>
      '\\d{1,2}|${_numberWordsByLength.join('|')}';

  static int? _toNumber(String? raw) {
    if (raw == null) return null;
    final text = raw.trim().toLowerCase();
    return int.tryParse(text) ?? _numberWords[text];
  }

  static Map<String, dynamic> parse(String text, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final source = text.toLowerCase().trim();

    // Spans consumed by date/time matches, stripped from the title afterwards.
    final consumed = <_Span>[];

    final date = _parseDate(source, reference, consumed);
    final time = _parseTime(source, consumed);

    final base = date ?? DateTime(reference.year, reference.month, reference.day);
    var result = DateTime(
      base.year,
      base.month,
      base.day,
      time?.hour ?? 9,
      time?.minute ?? 0,
    );

    // With no explicit date, a time that already passed means the next day.
    if (date == null && result.isBefore(reference)) {
      result = result.add(const Duration(days: 1));
    }
    // "cuma" spoken on a Friday whose time has passed means the next Friday.
    else if (date != null && result.isBefore(reference) && _weekdayOnly) {
      result = result.add(const Duration(days: 7));
    }

    return {
      'title': _buildTitle(source, consumed),
      'dateTime': result,
    };
  }

  /// Set while parsing when the date came from a bare weekday name.
  static bool _weekdayOnly = false;

  static DateTime? _parseDate(String source, DateTime now, List<_Span> consumed) {
    _weekdayOnly = false;
    final today = DateTime(now.year, now.month, now.day);

    // "15 ağustos" / "15 ağustos 2026"
    final monthName = RegExp(
      '(\\d{1,2})\\s+(${_months.keys.join('|')})(?:\\s+(\\d{4}))?',
    ).firstMatch(source);
    if (monthName != null) {
      final day = int.parse(monthName.group(1)!);
      final month = _months[monthName.group(2)!]!;
      final year = int.tryParse(monthName.group(3) ?? '') ?? now.year;
      final candidate = DateTime(year, month, day);
      consumed.add(_Span(monthName.start, monthName.end));
      // A bare day/month that already passed refers to next year.
      if (monthName.group(3) == null && candidate.isBefore(today)) {
        return DateTime(year + 1, month, day);
      }
      return candidate;
    }

    // "15/08", "15/08/2026", "15.08.2026" — a dotted pair without a year stays
    // a time, since "15.30" is a common way to write half past three.
    final numeric = RegExp(
      r'(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?|(\d{1,2})\.(\d{1,2})\.(\d{2,4})',
    ).firstMatch(source);
    if (numeric != null) {
      final slashed = numeric.group(1) != null;
      final day = int.parse(numeric.group(slashed ? 1 : 4)!);
      final month = int.parse(numeric.group(slashed ? 2 : 5)!);
      final rawYear = numeric.group(slashed ? 3 : 6);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        var year = int.tryParse(rawYear ?? '') ?? now.year;
        if (year < 100) year += 2000;
        consumed.add(_Span(numeric.start, numeric.end));
        final candidate = DateTime(year, month, day);
        if (rawYear == null && candidate.isBefore(today)) {
          return DateTime(year + 1, month, day);
        }
        return candidate;
      }
    }

    // "3 gün sonra", "iki hafta sonra", "1 ay sonra"
    final relative = RegExp(
      '(?<![$_letter])($_numberAlternation)\\s+(gün|hafta|ay)\\s+sonra',
    ).firstMatch(source);
    if (relative != null) {
      final amount = _toNumber(relative.group(1)) ?? 1;
      consumed.add(_Span(relative.start, relative.end));
      switch (relative.group(2)) {
        case 'gün':
          return today.add(Duration(days: amount));
        case 'hafta':
          return today.add(Duration(days: amount * 7));
        case 'ay':
          return DateTime(today.year, today.month + amount, today.day);
      }
    }

    // Weekday, optionally pushed a week out by "gelecek"/"önümüzdeki".
    final weekday = RegExp(
      '(gelecek|önümüzdeki|haftaya)?\\s*(?<![$_letter])(${_weekdays.keys.join('|')})(?![$_letter])',
    ).firstMatch(source);
    if (weekday != null) {
      final target = _weekdays[weekday.group(2)!]!;
      var delta = (target - today.weekday + 7) % 7;
      if (weekday.group(1) != null) delta += 7;
      consumed.add(_Span(weekday.start, weekday.end));
      _weekdayOnly = delta == 0;
      return today.add(Duration(days: delta));
    }

    // "haftaya" / "gelecek hafta" on its own.
    final nextWeek = RegExp('(haftaya|(?:gelecek|önümüzdeki)\\s+hafta)').firstMatch(source);
    if (nextWeek != null) {
      consumed.add(_Span(nextWeek.start, nextWeek.end));
      return today.add(const Duration(days: 7));
    }

    const dayOffsets = {
      'bugün': 0,
      'yarın': 1,
      'öbür gün': 2,
      'ertesi gün': 2,
    };
    for (final entry in dayOffsets.entries) {
      final match = RegExp('(?<![$_letter])${entry.key}(?![$_letter])').firstMatch(source);
      if (match != null) {
        consumed.add(_Span(match.start, match.end));
        return today.add(Duration(days: entry.value));
      }
    }

    return null;
  }

  static _Time? _parseTime(String source, List<_Span> consumed) {
    const periods = 'sabah|öğleden sonra|öğlen|öğle|akşam|gece';

    final regex = RegExp(
      '(?:($periods)\\s+)?'
      '(saat\\s+)?'
      '(?<![$_letter])($_numberAlternation)(?![$_letter])'
      '(?::(\\d{1,2}))?'
      "(?:\\s*['’\"]?\\s*(?:de|da|te|ta))?"
      '(?:\\s*(buçuk))?'
      "(?:\\s*['’\"]?\\s*(?:de|da|te|ta))?"
      '(?:\\s*($periods|am|pm))?',
    );

    final match = regex.firstMatch(source);
    if (match != null) {
      final periodBefore = match.group(1);
      final hasSaat = match.group(2) != null;
      final minutes = match.group(4);
      final buCuk = match.group(5);
      final periodAfter = match.group(6);
      // Only treat it as a time when something marks it as one; a bare number
      // is far more likely to be a quantity ("bir toplantı").
      final marked = periodBefore != null ||
          hasSaat ||
          minutes != null ||
          buCuk != null ||
          periodAfter != null ||
          RegExp("['’\"]?\\s*(?:de|da|te|ta)\$").hasMatch(match.group(0)!.trim());

      if (marked) {
        var hour = _toNumber(match.group(3)) ?? 9;
        var minute = int.tryParse(minutes ?? '') ?? 0;
        if (buCuk != null) minute = 30;

        final period = periodAfter ?? periodBefore ?? '';
        if (hour < 12) {
          if (period == 'akşam' || period == 'öğleden sonra' || period == 'pm' || period == 'öğlen' || period == 'öğle') {
            hour += 12;
          } else if (period == 'gece' && hour >= 8) {
            hour += 12;
          }
        }

        consumed.add(_Span(match.start, match.end));
        return _Time(hour % 24, minute % 60);
      }
    }

    // No number, just a part of the day.
    const descriptive = {'sabah': 8, 'öğlen': 13, 'öğle': 13, 'akşam': 20, 'gece': 23};
    for (final entry in descriptive.entries) {
      final found = RegExp('(?<![$_letter])${entry.key}(?![$_letter])').firstMatch(source);
      if (found != null) {
        consumed.add(_Span(found.start, found.end));
        return _Time(entry.value, 0);
      }
    }

    return null;
  }

  static String _buildTitle(String source, List<_Span> consumed) {
    final buffer = StringBuffer();
    for (var i = 0; i < source.length; i++) {
      if (consumed.any((span) => i >= span.start && i < span.end)) continue;
      buffer.write(source[i]);
    }

    var title = buffer
        .toString()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'''^[\s,.'’"-]+|[\s,.'’"-]+$'''), '')
        .trim();

    if (title.isEmpty) return 'Yeni Etkinlik';

    // Turkish dotted capital, so "izin" becomes "İzin" rather than "Izin".
    final first = title[0];
    final upper = first == 'i' ? 'İ' : first.toUpperCase();
    return '$upper${title.substring(1)}';
  }
}

class _Span {
  const _Span(this.start, this.end);
  final int start;
  final int end;
}

class _Time {
  const _Time(this.hour, this.minute);
  final int hour;
  final int minute;
}
