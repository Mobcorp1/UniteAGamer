import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';

class ArcAvailabilityOverlap {
  const ArcAvailabilityOverlap({
    required this.bothAvailableNow,
    required this.hasSharedWindow,
    this.dayKey = '',
    this.fromTime = '',
    this.toTime = '',
  });

  final bool bothAvailableNow;
  final bool hasSharedWindow;
  final String dayKey;
  final String fromTime;
  final String toTime;

  bool get noSharedWindow => !hasSharedWindow;
}

class ArcAvailabilityIntelligenceEngine {
  const ArcAvailabilityIntelligenceEngine();

  ArcAvailabilityOverlap twoPlayerOverlap({
    required ArcAvailability first,
    required ArcAvailability second,
    DateTime? now,
  }) {
    final overlap = _firstOverlap(<ArcAvailability>[first, second]);
    final today = _dayKey(now ?? DateTime.now());
    final availableNow =
        overlap != null &&
        overlap.dayKey == today &&
        _timeWithin(overlap.fromTime, overlap.toTime, now ?? DateTime.now());

    return ArcAvailabilityOverlap(
      bothAvailableNow: availableNow,
      hasSharedWindow: overlap != null,
      dayKey: overlap?.dayKey ?? '',
      fromTime: overlap?.fromTime ?? '',
      toTime: overlap?.toTime ?? '',
    );
  }

  ArcAvailabilityOverlap threePlayerOverlap({
    required ArcAvailability first,
    required ArcAvailability second,
    required ArcAvailability third,
    DateTime? now,
  }) {
    final overlap = _firstOverlap(<ArcAvailability>[first, second, third]);
    final today = _dayKey(now ?? DateTime.now());
    final availableNow =
        overlap != null &&
        overlap.dayKey == today &&
        _timeWithin(overlap.fromTime, overlap.toTime, now ?? DateTime.now());

    return ArcAvailabilityOverlap(
      bothAvailableNow: availableNow,
      hasSharedWindow: overlap != null,
      dayKey: overlap?.dayKey ?? '',
      fromTime: overlap?.fromTime ?? '',
      toTime: overlap?.toTime ?? '',
    );
  }

  _Window? _firstOverlap(List<ArcAvailability> availability) {
    if (availability.isEmpty) return null;
    const dayOrder = <String>['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    for (final day in dayOrder) {
      final slots = availability
          .map((item) => _slotForDay(item, day))
          .whereType<ArcAvailabilitySlot>()
          .where((slot) => slot.enabled)
          .toList(growable: false);
      if (slots.length != availability.length) continue;

      final start = slots
          .map((slot) => _minutes(slot.fromTime))
          .reduce((a, b) => a > b ? a : b);
      final end = slots
          .map((slot) => _minutes(slot.toTime))
          .reduce((a, b) => a < b ? a : b);
      if (end <= start) continue;

      return _Window(
        dayKey: day,
        fromTime: _formatMinutes(start),
        toTime: _formatMinutes(end),
      );
    }
    return null;
  }

  ArcAvailabilitySlot? _slotForDay(ArcAvailability availability, String day) {
    for (final week in availability.weeks) {
      for (final slot in week.slots) {
        if (slot.dayKey == day) return slot;
      }
    }
    return null;
  }

  bool _timeWithin(String fromTime, String toTime, DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    return minutes >= _minutes(fromTime) && minutes <= _minutes(toTime);
  }

  int _minutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return (hours.clamp(0, 23) * 60) + minutes.clamp(0, 59);
  }

  String _formatMinutes(int value) {
    final hours = value ~/ 60;
    final minutes = value % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  String _dayKey(DateTime value) {
    return switch (value.weekday) {
      DateTime.monday => 'mon',
      DateTime.tuesday => 'tue',
      DateTime.wednesday => 'wed',
      DateTime.thursday => 'thu',
      DateTime.friday => 'fri',
      DateTime.saturday => 'sat',
      _ => 'sun',
    };
  }
}

class _Window {
  const _Window({
    required this.dayKey,
    required this.fromTime,
    required this.toTime,
  });

  final String dayKey;
  final String fromTime;
  final String toTime;
}
