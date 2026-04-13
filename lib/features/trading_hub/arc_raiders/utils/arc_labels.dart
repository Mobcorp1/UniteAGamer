class ArcLabels {
  static String sourceType(dynamic sourceType) {
    final raw = sourceType.toString().split('.').last;

    switch (raw) {
      case 'poi':
        return 'POI';
      case 'enemy':
        return 'Enemy';
      case 'other':
        return 'Other';
      default:
        return raw.isEmpty ? 'Unknown' : _titleCase(raw);
    }
  }

  static String raidType(dynamic raidType) {
    final raw = raidType.toString().split('.').last;

    switch (raw) {
      case 'fullRaid':
        return 'Full Raid';
      case 'quickRaid':
        return 'Quick Raid';
      case 'lateRaid':
        return 'Late Raid';
      default:
        return raw.isEmpty ? 'Unknown' : _titleCase(raw);
    }
  }

  static String timeOfDay(dynamic timeOfDay) {
    final raw = timeOfDay.toString().split('.').last;

    switch (raw) {
      case 'day':
        return 'Day';
      case 'night':
        return 'Night';
      case 'dawn':
        return 'Dawn';
      case 'dusk':
        return 'Dusk';
      case 'unknown':
        return 'Unknown';
      default:
        return raw.isEmpty ? 'Unknown' : _titleCase(raw);
    }
  }

  static String fallbackWeather(String? weatherLabel) {
    final trimmed = weatherLabel?.trim();
    return trimmed == null || trimmed.isEmpty ? 'No Special Weather' : trimmed;
  }

  static String fallbackMapEvent(String? mapEventLabel) {
    final trimmed = mapEventLabel?.trim();
    return trimmed == null || trimmed.isEmpty ? 'No Map Event' : trimmed;
  }

  static String _titleCase(String value) {
    final cleaned = value
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .trim();

    if (cleaned.isEmpty) return 'Unknown';

    return cleaned
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
