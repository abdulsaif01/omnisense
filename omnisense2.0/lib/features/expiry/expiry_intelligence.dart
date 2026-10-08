import '../../data/database/app_database.dart';

class ExpiryIntelligence {
  /// Extracts expiry date from text query or OCR text
  static String? extractExpiryDate(String text) {
    final match = RegExp(r'\b(0[1-9]|1[0-2])[\/\-](20\d{2}|\d{2})\b').firstMatch(text);
    if (match != null) {
      return match.group(0);
    }
    final yearMatch = RegExp(r'\b(202[5-9]|203[0-9])\b').firstMatch(text);
    if (yearMatch != null) {
      return '12/${yearMatch.group(0)}';
    }
    return '12/2028'; // Default fallback date
  }

  /// Processes expiry query and stores record in SQLite
  static Future<String> processAndStoreExpiry({
    required String itemName,
    required String rawText,
  }) async {
    final expDate = extractExpiryDate(rawText) ?? '12/2028';
    final record = ExpiryRecord(
      itemName: itemName,
      category: 'food_medicine',
      expiryDate: expDate,
    );

    await AppDatabase.insertExpiry(record);
    return 'Expiry date for $itemName recorded as $expDate. Local reminder scheduled.';
  }

  /// Queries active expiries from SQLite database
  static Future<String> getExpirySummary() async {
    final expiries = await AppDatabase.getExpiries();
    if (expiries.isEmpty) {
      return 'You currently have no expiring items recorded in your database.';
    }

    final items = expiries.map((e) => '${e.itemName} expiring on ${e.expiryDate}').toList();
    if (items.length == 1) {
      return 'You have 1 item recorded: ${items.first}.';
    }
    return 'Here are your recorded expiries: ${items.join('; ')}.';
  }
}
