import 'package:flutter/foundation.dart';

import 'arc_map_conditions.dart';
import 'arc_poi_data.dart';

@immutable
class ArcDropReportOptions {
  const ArcDropReportOptions({
    required this.mapName,
    required this.poiOptions,
    required this.enemyOptions,
    required this.mapEventOptions,
  });

  final String mapName;
  final List<ArcPoiData> poiOptions;
  final List<ArcEnemySource> enemyOptions;
  final List<ArcMapCondition> mapEventOptions;
}

class ArcDropReportOptionsResolver {
  ArcDropReportOptionsResolver._();

  static ArcDropReportOptions forMap(String mapName) {
    return ArcDropReportOptions(
      mapName: mapName,
      poiOptions: ArcPoiDataStore.blueprintReportPoisForMap(mapName),
      enemyOptions: ArcPoiDataStore.commonEnemySources
          .where((enemy) => enemy.includeInBlueprintReports)
          .toList(growable: false),
      mapEventOptions: ArcMapConditions.combinedOptionsForMap(mapName),
    );
  }
}
