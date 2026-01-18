/// Utility class for cleaning text data from various sources
class TextCleaner {
  TextCleaner._();

  /// Clean bond amount text by removing garbage data
  /// 
  /// Examples:
  /// - "$0.00 PRINT CONTACT: &AMP;..." → "$0.00"
  /// - "$5000.00 VERSION:3.0" → "$5000.00"
  /// - "NO BOND" → "NO BOND"
  static String cleanBondAmount(String? bondText) {
    if (bondText == null || bondText.isEmpty) return '';

    String cleaned = bondText.trim();

    // Remove common garbage patterns
    cleaned = cleaned
        .replaceAll(RegExp(r'\s*PRINT\s+CONTACT:.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*&AMP;.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*&NBSP;.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*VERSION:.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*&[A-Z]+;.*$'), '') // Any HTML entity followed by text
        .trim();

    return cleaned;
  }

  /// Clean general text by removing HTML entities
  static String cleanHtmlEntities(String? text) {
    if (text == null || text.isEmpty) return '';

    String cleaned = text;

    // Common HTML entities
    final Map<String, String> entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&nbsp;': ' ',
    };

    entities.forEach((entity, replacement) {
      cleaned = cleaned.replaceAll(entity, replacement);
    });

    // Remove any remaining HTML entities
    cleaned = cleaned.replaceAll(RegExp(r'&[a-zA-Z]+;'), '');

    return cleaned.trim();
  }

  /// Clean address text
  static String cleanAddress(String? address) {
    if (address == null || address.isEmpty) return '';
    return cleanHtmlEntities(address);
  }
}

