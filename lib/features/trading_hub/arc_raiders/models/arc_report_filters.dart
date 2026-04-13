import 'package:flutter/foundation.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';

@immutable
class ArcReportFilters {
  const ArcReportFilters({
    this.query = '',
    this.mapName,
    this.containerLabel,
    this.raidType,
    this.timeOfDay,
    this.conditionLabel,
    this.onlyWithNotes = false,
  });

  final String query;
  final String? mapName;
  final String? containerLabel;
  final ArcRaidType? raidType;
  final ArcTimeOfDay? timeOfDay;
  final String? conditionLabel;
  final bool onlyWithNotes;

  bool get isEmpty {
    return query.trim().isEmpty &&
        (mapName == null || mapName!.trim().isEmpty) &&
        (containerLabel == null || containerLabel!.trim().isEmpty) &&
        raidType == null &&
        timeOfDay == null &&
        (conditionLabel == null || conditionLabel!.trim().isEmpty) &&
        !onlyWithNotes;
  }

  ArcReportFilters copyWith({
    String? query,
    String? mapName,
    bool clearMapName = false,
    String? containerLabel,
    bool clearContainerLabel = false,
    ArcRaidType? raidType,
    bool clearRaidType = false,
    ArcTimeOfDay? timeOfDay,
    bool clearTimeOfDay = false,
    String? conditionLabel,
    bool clearConditionLabel = false,
    bool? onlyWithNotes,
  }) {
    return ArcReportFilters(
      query: query ?? this.query,
      mapName: clearMapName ? null : (mapName ?? this.mapName),
      containerLabel: clearContainerLabel
          ? null
          : (containerLabel ?? this.containerLabel),
      raidType: clearRaidType ? null : (raidType ?? this.raidType),
      timeOfDay: clearTimeOfDay ? null : (timeOfDay ?? this.timeOfDay),
      conditionLabel: clearConditionLabel
          ? null
          : (conditionLabel ?? this.conditionLabel),
      onlyWithNotes: onlyWithNotes ?? this.onlyWithNotes,
    );
  }

  factory ArcReportFilters.empty() => const ArcReportFilters();
}
