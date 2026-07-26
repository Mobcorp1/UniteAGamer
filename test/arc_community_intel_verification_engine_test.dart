import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('verified reports become confirmed Intel markers', () {
    final report = ArcCommunityIntelReport(
      id: 'verified',
      reporterUid: 'u1',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      category: ArcCommunityIntelCategory.highValueLoot,
      point: const ArcNormalizedPoint(x: 0.5, y: 0.5),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      confirmationCount: 4,
      confirmedByUserIds: const <String>['u1', 'u2', 'u3', 'u4'],
      disputeCount: 0,
      disputedByUserIds: const <String>[],
      signature: 'verified',
    );

    final state = const ArcRaidIntelligenceEngine().build(
      mapId: 'blue_gate',
      communityReports: <ArcCommunityIntelReport>[report],
      filters: const ArcRaidMapFilterState(
        missingBlueprints: false,
        communityIntel: true,
        researchedIntel: true,
        confirmedIntel: true,
      ),
    );

    final marker = state.visibleMarkers.firstWhere(
      (item) => item.payloadId == 'verified',
    );
    expect(marker.category, ArcRaidMapMarkerCategory.confirmedIntel);
    expect(marker.tags, contains('Community Verified'));
  });
}
