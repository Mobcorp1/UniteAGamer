import 'package:flutter/foundation.dart';

@immutable
class ArcIntelHotspot {
  const ArcIntelHotspot({
    required this.key,
    required this.mapName,
    required this.areaLabel,
    required this.containerLabel,
    required this.count,
    required this.percentage,
    this.lastReportedAt,
    this.locationPreview,
  });

  final String key;
  final String mapName;
  final String areaLabel;
  final String containerLabel;
  final int count;
  final double percentage;
  final DateTime? lastReportedAt;
  final String? locationPreview;

  String get percentageLabel => '${percentage.toStringAsFixed(0)}%';
}
