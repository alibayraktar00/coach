import 'package:intl/intl.dart';

/// Clock time honouring the user's 12/24-hour preference.
String formatClock(DateTime dateTime, bool use24HourFormat) {
  return (use24HourFormat ? DateFormat.Hm() : DateFormat.jm()).format(dateTime);
}

/// Short date, e.g. 16/07/2026.
String formatDate(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy').format(dateTime);
}

/// Date and time together, for rows that show both.
String formatDateTime(DateTime dateTime, bool use24HourFormat) {
  return '${formatDate(dateTime)} · ${formatClock(dateTime, use24HourFormat)}';
}
