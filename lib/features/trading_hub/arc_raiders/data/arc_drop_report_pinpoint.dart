import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcDropReportPinpoint {
  const ArcDropReportPinpoint._();

  static String signatureSuffix({
    ArcNormalizedPoint? point,
    String? serverRegion,
  }) {
    final coordinate = point == null
        ? 'none'
        : '${point.x.toStringAsFixed(4)},${point.y.toStringAsFixed(4)}';
    final region = serverRegion?.trim().toLowerCase();
    final resolvedRegion = region == null || region.isEmpty ? 'none' : region;
    return '|pin:$coordinate|region:$resolvedRegion';
  }
}
