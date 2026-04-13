import 'package:flutter/foundation.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_intel_hotspot.dart';

@immutable
class ArcIntelExplorerSnapshot {
  const ArcIntelExplorerSnapshot({
    required this.filteredReports,
    required this.hotspots,
    required this.mapOptions,
    required this.containerOptions,
    required this.conditionOptions,
  });

  final List<ArcBlueprintDropReport> filteredReports;
  final List<ArcIntelHotspot> hotspots;
  final List<String> mapOptions;
  final List<String> containerOptions;
  final List<String> conditionOptions;

  bool get hasReports => filteredReports.isNotEmpty;
}
