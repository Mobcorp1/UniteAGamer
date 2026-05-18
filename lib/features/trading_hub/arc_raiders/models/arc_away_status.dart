class ArcAwayStatus {
  final bool isAway;
  final DateTime? from;
  final DateTime? to;
  final String note;

  const ArcAwayStatus({
    required this.isAway,
    required this.from,
    required this.to,
    required this.note,
  });

  factory ArcAwayStatus.initial() {
    return const ArcAwayStatus(isAway: false, from: null, to: null, note: '');
  }

  Map<String, dynamic> toMap() {
    return {
      'isAway': isAway,
      'from': from?.millisecondsSinceEpoch,
      'to': to?.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory ArcAwayStatus.fromMap(Map<String, dynamic> map) {
    return ArcAwayStatus(
      isAway: (map['isAway'] ?? false) as bool,
      from: map['from'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['from'] as int),
      to: map['to'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['to'] as int),
      note: (map['note'] ?? '') as String,
    );
  }

  ArcAwayStatus copyWith({
    bool? isAway,
    DateTime? from,
    DateTime? to,
    String? note,
  }) {
    return ArcAwayStatus(
      isAway: isAway ?? this.isAway,
      from: from ?? this.from,
      to: to ?? this.to,
      note: note ?? this.note,
    );
  }
}
