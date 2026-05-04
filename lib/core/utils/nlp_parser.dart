class NLPParser {
  static Map<String, dynamic> parse(String text) {
    text = text.toLowerCase();
    DateTime now = DateTime.now();
    DateTime targetDate = now;
    
    // Simple Date Logic
    if (text.contains('yarın')) {
      targetDate = now.add(const Duration(days: 1));
    } else if (text.contains('bugün')) {
      targetDate = now;
    }
    
    // Simple Time Logic
    int hour = 9; // Default 9 AM
    int minute = 0;
    
    final timeRegex = RegExp(r'(\d{1,2})[:.]?(\d{0,2})\s*(pm|am|öğleden sonra|akşam|gece)?');
    final match = timeRegex.firstMatch(text);
    
    if (match != null) {
      hour = int.parse(match.group(1)!);
      if (match.group(2) != null && match.group(2)!.isNotEmpty) {
        minute = int.parse(match.group(2)!);
      }
      
      String period = match.group(3) ?? '';
      if ((period == 'pm' || period == 'akşam' || period == 'gece' || period == 'öğleden sonra') && hour < 12) {
        hour += 12;
      }
    } else {
      // Descriptive times
      if (text.contains('akşam')) hour = 20;
      if (text.contains('öğle')) hour = 13;
      if (text.contains('sabah')) hour = 8;
      if (text.contains('gece')) hour = 23;
    }
    
    DateTime finalDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );

    // Extract Title (Simple: text minus keywords)
    String title = text
        .replaceAll('yarın', '')
        .replaceAll('bugün', '')
        .replaceAll('akşam', '')
        .replaceAll('sabah', '')
        .replaceAll('gece', '')
        .replaceAll('saat', '')
        .replaceAll(timeRegex, '')
        .trim();
    
    if (title.isEmpty) title = 'Yeni Etkinlik';
    
    // Capitalize first letter
    title = title[0].toUpperCase() + title.substring(1);

    return {
      'title': title,
      'dateTime': finalDateTime,
    };
  }
}
