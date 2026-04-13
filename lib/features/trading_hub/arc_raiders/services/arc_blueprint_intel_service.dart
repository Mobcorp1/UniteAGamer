import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_drop_intel.dart';

class ArcBlueprintIntelService {
  const ArcBlueprintIntelService();

  ArcDropIntel buildIntel({
    required String blueprintId,
    required List<ArcBlueprintDropReport> reports,
  }) {
    return ArcDropIntel.fromReports(
      blueprintId: blueprintId,
      reports: reports,
    );
  }
}
