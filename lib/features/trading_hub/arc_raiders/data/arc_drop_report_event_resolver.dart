import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';

class ArcDropReportEventResolver {
  const ArcDropReportEventResolver._();

  static List<ArcMapCondition> optionsFor({
    required String mapName,
    required ArcServerRegion region,
    required DateTime capturedAtUtc,
    ArcRegionalMapConditionsSnapshot? snapshot,
    ArcMapCondition? forcedCondition,
  }) {
    final canonical = ArcMapConditions.combinedOptionsForMap(mapName);
    final byLabel = <String, ArcMapCondition>{
      for (final condition in canonical) _normalize(condition.label): condition,
    };

    final scheduled = <ArcMapCondition>[];
    final active = <ArcMapCondition>[];
    if (snapshot != null) {
      for (final entry in snapshot.entries) {
        if (_normalize(entry.mapDisplayName) != _normalize(mapName)) continue;
        final condition = byLabel[_normalize(entry.conditionName)];
        if (condition == null) continue;
        if (!scheduled.any((item) => item.id == condition.id)) {
          scheduled.add(condition);
        }
        final window = entry.windowFor(region);
        if (window != null && window.isActiveAt(capturedAtUtc)) {
          if (!active.any((item) => item.id == condition.id)) {
            active.add(condition);
          }
        }
      }
    }

    final output = <ArcMapCondition>[ArcMapConditions.noSpecialCondition];
    void add(ArcMapCondition? condition) {
      if (condition == null) return;
      if (output.any((item) => item.id == condition.id)) return;
      output.add(condition);
    }

    for (final condition in active) {
      add(condition);
    }
    add(forcedCondition);
    for (final condition in scheduled) {
      add(condition);
    }

    if (output.length == 1) {
      for (final condition in canonical.where((item) => item.isMapSpecific)) {
        add(condition);
      }
    }

    return output;
  }

  static ArcMapCondition suggestedFor({
    required String mapName,
    required ArcServerRegion region,
    required DateTime capturedAtUtc,
    ArcRegionalMapConditionsSnapshot? snapshot,
    ArcMapCondition? forcedCondition,
  }) {
    if (forcedCondition != null) return forcedCondition;
    if (snapshot != null) {
      final canonical = ArcMapConditions.combinedOptionsForMap(mapName);
      final byLabel = <String, ArcMapCondition>{
        for (final condition in canonical)
          _normalize(condition.label): condition,
      };
      for (final entry in snapshot.entries) {
        if (_normalize(entry.mapDisplayName) != _normalize(mapName)) continue;
        final window = entry.windowFor(region);
        if (window == null || !window.isActiveAt(capturedAtUtc)) continue;
        final condition = byLabel[_normalize(entry.conditionName)];
        if (condition != null) return condition;
      }
    }
    return ArcMapConditions.noSpecialCondition;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
