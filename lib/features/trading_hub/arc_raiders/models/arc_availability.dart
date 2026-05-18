class ArcAvailabilitySlot {
  final String dayKey;
  final bool enabled;
  final String fromTime;
  final String toTime;

  const ArcAvailabilitySlot({
    required this.dayKey,
    required this.enabled,
    required this.fromTime,
    required this.toTime,
  });

  factory ArcAvailabilitySlot.empty(String dayKey) {
    return ArcAvailabilitySlot(
      dayKey: dayKey,
      enabled: false,
      fromTime: '19:00',
      toTime: '21:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayKey': dayKey,
      'enabled': enabled,
      'fromTime': fromTime,
      'toTime': toTime,
    };
  }

  factory ArcAvailabilitySlot.fromMap(Map<String, dynamic> map) {
    return ArcAvailabilitySlot(
      dayKey: (map['dayKey'] ?? '') as String,
      enabled: (map['enabled'] ?? false) as bool,
      fromTime: (map['fromTime'] ?? '19:00') as String,
      toTime: (map['toTime'] ?? '21:00') as String,
    );
  }

  ArcAvailabilitySlot copyWith({
    String? dayKey,
    bool? enabled,
    String? fromTime,
    String? toTime,
  }) {
    return ArcAvailabilitySlot(
      dayKey: dayKey ?? this.dayKey,
      enabled: enabled ?? this.enabled,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
    );
  }
}

class ArcAvailabilityWeek {
  final String label;
  final List<ArcAvailabilitySlot> slots;

  const ArcAvailabilityWeek({required this.label, required this.slots});

  factory ArcAvailabilityWeek.empty(String label) {
    const dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return ArcAvailabilityWeek(
      label: label,
      slots: dayKeys.map(ArcAvailabilitySlot.empty).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'label': label, 'slots': slots.map((e) => e.toMap()).toList()};
  }

  factory ArcAvailabilityWeek.fromMap(Map<String, dynamic> map) {
    final rawSlots = (map['slots'] as List<dynamic>? ?? const []);
    return ArcAvailabilityWeek(
      label: (map['label'] ?? 'Week 1') as String,
      slots: rawSlots
          .whereType<Map>()
          .map(
            (e) => ArcAvailabilitySlot.fromMap(
              e.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
    );
  }

  ArcAvailabilityWeek copyWith({
    String? label,
    List<ArcAvailabilitySlot>? slots,
  }) {
    return ArcAvailabilityWeek(
      label: label ?? this.label,
      slots: slots ?? this.slots,
    );
  }
}

class ArcAvailability {
  final String scheduleType; // weekly, rotation, flexible
  final bool useEveryWeek;
  final List<ArcAvailabilityWeek> weeks;

  const ArcAvailability({
    required this.scheduleType,
    required this.useEveryWeek,
    required this.weeks,
  });

  factory ArcAvailability.initial() {
    return ArcAvailability(
      scheduleType: 'weekly',
      useEveryWeek: true,
      weeks: const [
        ArcAvailabilityWeek(
          label: 'Week 1',
          slots: [
            ArcAvailabilitySlot(
              dayKey: 'mon',
              enabled: false,
              fromTime: '19:00',
              toTime: '21:00',
            ),
            ArcAvailabilitySlot(
              dayKey: 'tue',
              enabled: false,
              fromTime: '19:00',
              toTime: '21:00',
            ),
            ArcAvailabilitySlot(
              dayKey: 'wed',
              enabled: false,
              fromTime: '19:00',
              toTime: '21:00',
            ),
            ArcAvailabilitySlot(
              dayKey: 'thu',
              enabled: false,
              fromTime: '19:00',
              toTime: '21:00',
            ),
            ArcAvailabilitySlot(
              dayKey: 'fri',
              enabled: false,
              fromTime: '19:00',
              toTime: '21:00',
            ),
            ArcAvailabilitySlot(
              dayKey: 'sat',
              enabled: false,
              fromTime: '19:00',
              toTime: '21:00',
            ),
            ArcAvailabilitySlot(
              dayKey: 'sun',
              enabled: false,
              fromTime: '19:00',
              toTime: '21:00',
            ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleType': scheduleType,
      'useEveryWeek': useEveryWeek,
      'weeks': weeks.map((e) => e.toMap()).toList(),
    };
  }

  factory ArcAvailability.fromMap(Map<String, dynamic> map) {
    final rawWeeks = (map['weeks'] as List<dynamic>? ?? const []);
    final weeks = rawWeeks
        .whereType<Map>()
        .map(
          (e) => ArcAvailabilityWeek.fromMap(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();

    return ArcAvailability(
      scheduleType: (map['scheduleType'] ?? 'weekly') as String,
      useEveryWeek: (map['useEveryWeek'] ?? true) as bool,
      weeks: weeks.isEmpty ? ArcAvailability.initial().weeks : weeks,
    );
  }

  ArcAvailability copyWith({
    String? scheduleType,
    bool? useEveryWeek,
    List<ArcAvailabilityWeek>? weeks,
  }) {
    return ArcAvailability(
      scheduleType: scheduleType ?? this.scheduleType,
      useEveryWeek: useEveryWeek ?? this.useEveryWeek,
      weeks: weeks ?? this.weeks,
    );
  }
}
