class ArcTextSanitizer {
  const ArcTextSanitizer._();

  static String get bullet => String.fromCharCode(0x2022);
  static String get pound => String.fromCharCode(0x00A3);
  static String get multiplication => String.fromCharCode(0x00D7);
  static String get check => String.fromCharCode(0x2713);
  static String get arrowBoth => String.fromCharCode(0x2194);

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
      _chars([0x00C2, 0x00A3]): pound,
      _chars([0x00E2, 0x20AC, 0x00A2]): bullet,
      _chars([0x00E2, 0x20AC, 0x00A6]): '...',
      _chars([0x00E2, 0x20AC, 0x2122]): "'",
      _chars([0x00E2, 0x20AC, 0x0153]): '"',
      _chars([0x00E2, 0x20AC, 0x009D]): '"',
      _chars([0x00E2, 0x20AC, 0x201C]): '-',
      _chars([0x00E2, 0x20AC, 0x201D]): '-',
      _chars([0x00E2, 0x2020, 0x201D]): arrowBoth,
      _chars([0x00E2, 0x0153, 0x201C]): check,
      _chars([0x00C3, 0x2014]): multiplication,
      _chars([0x00C3, 0x0192, 0x00C2, 0x00A9]): 'e',
      _chars([0x00EF, 0x00BF, 0x00BD]): '',
      _chars([0x00C2, 0x00A0]): ' ',
      _chars([0xFEFF]): '',
      _chars([0x200B]): '',
      _chars([0x200C]): '',
      _chars([0x200D]): '',
    };

    for (final entry in replacements.entries) {
      output = output.replaceAll(entry.key, entry.value);
    }

    output = output
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' $bullet  $bullet ', ' $bullet ')
        .replaceAll('$bullet$bullet', bullet)
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
    return [
      _chars([0x00C2, 0x00A3]),
      _chars([0x00E2, 0x20AC]),
      _chars([0x00C3]),
      _chars([0x00EF, 0x00BF, 0x00BD]),
      String.fromCharCode(0xFFFD),
    ].any(value.contains);
  }

  static String _chars(List<int> codes) => String.fromCharCodes(codes);
}
