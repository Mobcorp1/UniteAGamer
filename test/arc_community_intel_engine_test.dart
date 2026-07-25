import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('community reports become shared layer-aware map markers', () {
    final report = ArcCommunityIntelReport(
      id: 'intel-1',
      reporterUid: 'u1',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.underground,
      category: ArcCommunityIntelCategory.lockedRoom,
      point: const ArcNormalizedPoint(x: 0.52, y: 0.48),
      poiName: 'Level 2',
      createdAt: DateTime.utc(2026, 7, 25),
      updatedAt: DateTime.now(),
      confirmationCount: 3,
      confirmedByUserIds: const <String>['u1', 'u2', 'u3'],
      signature: 'signature',
    );

    final state = const ArcRaidIntelligenceEngine().build(
      mapId: 'blue_gate',
      activeLayer: ArcRaidMapLayer.underground,
      communityReports: <ArcCommunityIntelReport>[report],
      filters: const ArcRaidMapFilterState(
        missingBlueprints: false,
        communityIntel: true,
        researchedIntel: true,
        confirmedIntel: true,
      ),
    );

    final marker = state.visibleMarkers.firstWhere(
      (item) => item.payloadId == report.id,
    );
    expect(marker.layer, ArcRaidMapLayer.underground);
    expect(marker.category, ArcRaidMapMarkerCategory.researchedIntel);
    expect(marker.point.x, closeTo(0.52, 0.001));
  });
}
