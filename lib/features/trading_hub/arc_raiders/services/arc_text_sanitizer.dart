class ArcTextSanitizer {
  const ArcTextSanitizer._();

  static String get bullet => String.fromCharCode(0x2022);

  static String separator() => ' $bullet ';

  static String metadataLine(List<String?> parts) {
    return parts
        .whereType<String>()
        .map((part) => sanitize(part).trim())
        .where((part) => part.isNotEmpty)
        .join(separator());
  }

  static String sanitize(String value) {
    var output = value;

    final replacements = <String, String>{
      'Ã¢â‚¬Â¢': 'Ã¢â‚¬Â¢',
      'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬': 'Ã¢â‚¬Â¢',
      'Ã‚-': 'Ã¢â‚¬Â¢',
      'ÃƒÆ’Ã¢â‚¬Å¡Ã‚-': 'Ã¢â‚¬Â¢',
      ' ': ' ',
      'ÃƒÆ’Ã¢â‚¬Å¡': '',
      '': '',
      'Ã¯Â¿Â½': '',
      '\uFEFF': '',
      '\u200B': '',
      '\u200C': '',
      '\u200D': '',
    };

    for (final entry in replacements.entries) {
      output = output.replaceAll(entry.key, entry.value);
    }

    output = output
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' Ã¢â‚¬Â¢  Ã¢â‚¬Â¢ ', ' Ã¢â‚¬Â¢ ')
        .replaceAll('Ã¢â‚¬Â¢Ã¢â‚¬Â¢', 'Ã¢â‚¬Â¢')
        .trim();

    return output;
  }

  static String normalizeId(String value) {
    return sanitize(value)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static bool hasMojibake(String value) {
    return value.contains('ÃƒÆ’') ||
        value.contains('') ||
        value.contains('Ã¢â‚¬Â¢') ||
        value.contains('Ã¯Â¿Â½');
  }
}
