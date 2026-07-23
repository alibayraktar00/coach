class NLPParser {
  static Map<String, dynamic> parse(String text) {
    text = text.toLowerCase();
    DateTime now = DateTime.now();
    DateTime targetDate = now;
    
    // Turkish Written Numbers Mapping
    final turkishNumbers = {
      'sıfır': 0, 'bir': 1, 'iki': 2, 'üç': 3, 'dört': 4, 'beş': 5,
      'altı': 6, 'yedi': 7, 'sekiz': 8, 'dokuz': 9, 'on': 10,
      'on bir': 11, 'on iki': 12, 'yirmi': 20,
    };

    String processedText = text;
    turkishNumbers.forEach((word, value) {
      processedText = processedText.replaceAll(word, value.toString());
    });

    // Date Logic
    if (processedText.contains('yarın')) {
      targetDate = now.add(const Duration(days: 1));
    } else if (processedText.contains('bugün')) {
      targetDate = now;
    }
    
    int hour = 9; // Default 9 AM
    int minute = 0;
    
    // Improved Regex
    // 1: period before (sabah|öğle|akşam|gece)
    // 2: hour
    // 3: minute
    // 4: buçuk
    // 5: period after
    final timeRegex = RegExp(
      '(sabah|öğle|akşam|gece|öğleden sonra)?\\s*(?:saat\\s+)?(\\d{1,2})(?:[:.](\\d{1,2}))?\\s*(?:[\'"]?\\s*(?:de|da|te|ta))?\\s*(buçuk)?\\s*(?:[\'"]?\\s*(?:de|da|te|ta))?\\s*(pm|am|öğleden sonra|akşam|gece)?',
      caseSensitive: false
    );
    
    final match = timeRegex.firstMatch(processedText);
    
    if (match != null) {
      hour = int.parse(match.group(2)!);
      if (match.group(3) != null && match.group(3)!.isNotEmpty) {
        minute = int.parse(match.group(3)!);
      }
      
      if (match.group(4) != null && match.group(4)!.contains('buçuk')) {
        minute = 30;
      }
      
      String periodBefore = match.group(1) ?? '';
      String periodAfter = match.group(5) ?? '';
      
      if ((periodBefore.contains('akşam') || periodAfter.contains('akşam') || 
           periodBefore.contains('gece') || periodAfter.contains('gece') ||
           periodBefore.contains('öğleden sonra') || periodAfter.contains('öğleden sonra')) && hour < 12) {
        hour += 12;
      }
    } else {
      // Fallback descriptive times
      if (processedText.contains('akşam')) hour = 20;
      if (processedText.contains('öğle')) hour = 13;
      if (processedText.contains('sabah')) hour = 8;
      if (processedText.contains('gece')) hour = 23;
    }
    
    DateTime finalDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );

    // Extract Title
    String title = processedText
        .replaceAll('yarın', '')
        .replaceAll('bugün', '')
        .replaceAll(timeRegex, '')
        .replaceAll(RegExp(r'\s+'), ' ')
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
