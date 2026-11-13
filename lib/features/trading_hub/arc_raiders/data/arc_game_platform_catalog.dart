class ArcGamePlatformCatalog {
  const ArcGamePlatformCatalog._();

  static const String playStation = 'PlayStation';
  static const String xbox = 'Xbox';
  static const String pc = 'PC';

  static const List<String> values = <String>[playStation, xbox, pc];

  static List<String> normalize(
    Iterable<Object?> rawValues, {
    Object? fallback,
  }) {
    final output = <String>[];

    void add(Object? raw) {
      final normalized = normalizeOne(raw);
      if (normalized != null && !output.contains(normalized)) {
        output.add(normalized);
      }
    }

    for (final value in rawValues) {
      add(value);
    }
    if (output.isEmpty) add(fallback);
    return List<String>.unmodifiable(output);
  }

  static String? normalizeOne(Object? rawValue) {
    final raw = rawValue?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    final value = raw.toLowerCase();

    if (value == 'ps' ||
        value == 'ps4' ||
        value == 'ps5' ||
        value.contains('playstation') ||
        value.contains('sony')) {
      return playStation;
    }
    if (value.contains('xbox') || value == 'xbsx' || value == 'xb1') {
      return xbox;
    }
    if (value == 'pc' ||
        value.contains('steam') ||
        value.contains('epic') ||
        value.contains('windows')) {
      return pc;
    }
    return null;
  }

  static String primary(Iterable<String> platforms) {
    final normalized = normalize(platforms);
    return normalized.isEmpty ? '' : normalized.first;
  }

  static bool contains(Iterable<String> platforms, String platform) {
    return normalize(platforms).contains(platform);
  }
}
