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
      'ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢': 'â€¢',
      'ÃƒÂ¢Ã¢â€šÂ¬': 'â€¢',
      'Ã¢â‚¬Â¢': 'â€¢',
      'Ã‚Â·': 'â€¢',
      'Ãƒâ€šÃ‚Â·': 'â€¢',
      'Ã‚ ': ' ',
      'Ãƒâ€š': '',
      'Ã‚': '',
      'ï¿½': '',
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
        .replaceAll(' â€¢  â€¢ ', ' â€¢ ')
        .replaceAll('â€¢â€¢', 'â€¢')
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
    return value.contains('Ãƒ') ||
        value.contains('Ã‚') ||
        value.contains('Ã¢â‚¬Â¢') ||
        value.contains('ï¿½');
  }
}
