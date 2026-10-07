import 'package:timezone/timezone.dart' as tz;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';

class ArcPlaytimeWindow {
  const ArcPlaytimeWindow({required this.startUtc, required this.endUtc});

  final DateTime startUtc;
  final DateTime endUtc;

  bool contains(DateTime now) =>
      !now.isBefore(startUtc) && now.isBefore(endUtc);

  bool overlaps(DateTime start, DateTime end, {required DateTime now}) =>
      end.isAfter(now) &&
      end.isAfter(startUtc) &&
      endUtc.isAfter(now) &&
      start.isBefore(endUtc);
}

/// Calendar arithmetic is deliberately separate from elapsed-time arithmetic:
/// local days and rotating weeks must survive 23/25-hour DST days.
class ArcAvailabilityWindowResolver {
  const ArcAvailabilityWindowResolver({this.location});

  /// Null uses the device timezone. An explicit zone supports deterministic tests.
  final tz.Location? location;

  DateTime localTime(DateTime instant) => location == null
      ? instant.toLocal()
      : tz.TZDateTime.from(instant, location!);

  DateTime _date(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
  ]) => location == null
      ? DateTime(year, month, day, hour, minute)
      : tz.TZDateTime(location!, year, month, day, hour, minute);

  bool hasUsableAvailability(ArcAvailability availability) =>
      (availability.useEveryWeek
              ? availability.weeks.take(1)
              : availability.weeks)
          .any((week) => week.slots.any(_usable));

  List<ArcPlaytimeWindow> todayWindows(
    ArcAvailability availability, {
    required DateTime now,
  }) {
    final local = localTime(now);
    final today = _date(local.year, local.month, local.day);
    final yesterday = _date(local.year, local.month, local.day - 1);
    final windows = <ArcPlaytimeWindow>[
      // Only an ongoing session from yesterday may extend into today's feed.
      ...windowsForDate(availability, yesterday).where((w) => w.contains(now)),
      ...windowsForDate(
        availability,
        today,
      ).where((w) => w.endUtc.isAfter(now)),
    ]..sort((a, b) => a.startUtc.compareTo(b.startUtc));
    return List.unmodifiable(windows);
  }

  List<ArcPlaytimeWindow> windowsForDate(
    ArcAvailability availability,
    DateTime localDate,
  ) {
    if (availability.weeks.isEmpty) return const [];
    final week = availability.weeks[weekIndexForDate(availability, localDate)];
    final windows = <ArcPlaytimeWindow>[];
    for (final slot in week.slots) {
      if (!_usable(slot) || slot.dayKey != _dayKeys[localDate.weekday - 1]) {
        continue;
      }
      final from = _minutes(slot.fromTime)!;
      final to = _minutes(slot.toTime)!;
      final start = _date(
        localDate.year,
        localDate.month,
        localDate.day,
        from ~/ 60,
        from % 60,
      );
      final end = _date(
        localDate.year,
        localDate.month,
        localDate.day + (to <= from ? 1 : 0),
        to ~/ 60,
        to % 60,
      );
      if (end.isAfter(start)) {
        windows.add(
          ArcPlaytimeWindow(startUtc: start.toUtc(), endUtc: end.toUtc()),
        );
      }
    }
    return windows;
  }

  int weekIndexForDate(ArcAvailability availability, DateTime localDate) {
    if (availability.useEveryWeek || availability.weeks.length <= 1) return 0;
    // Preserve the regional planner's existing Monday rotation anchor.
    final civilDay = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
    );
    final weeks = (civilDay.difference(DateTime.utc(2026, 1, 5)).inDays / 7)
        .floor();
    return weeks % availability.weeks.length;
  }

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  bool _usable(ArcAvailabilitySlot slot) =>
      slot.enabled &&
      _dayKeys.contains(slot.dayKey) &&
      _minutes(slot.fromTime) != null &&
      _minutes(slot.toTime) != null;

  int? _minutes(String time) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(time.trim());
    if (match == null) return null;
    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    return hour < 24 && minute < 60 ? hour * 60 + minute : null;
  }
}
