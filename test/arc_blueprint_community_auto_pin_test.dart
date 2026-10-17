import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_community_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('community seed contains no player-facing external source data', () {
    for (final report in ArcBlueprintCommunitySeed.reports) {
      expect(report.acquisitionEvidence, isEmpty, reason: report.id);
      expect(report.notes, isEmpty, reason: report.id);
      expect(report.signature, isEmpty, reason: report.id);
      expect(report.poiName?.toLowerCase(), isNot(contains('reddit.com')));
    }
  });

  test('compiled community seed contains only canonical Blueprint IDs', () {
    final ids = ArcBlueprintSeedData.blueprints
        .map((blueprint) => blueprint.id)
        .toSet();
    for (final report in ArcBlueprintCommunitySeed.reports) {
      expect(ids, contains(report.blueprintId), reason: report.id);
    }
  });

  test(
    'community seed resolves named reported area to published POI coordinate',
    () {
      final map = ArcRaidIntelligenceSeedData.mapById('buried_city');
      const point = ArcNormalizedPoint(x: 0.31, y: 0.42);
      const marker = ArcAdminMapMarker(
        id: 'admin-town-hall',
        mapId: 'buried_city',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.poi,
        name: 'Town Hall',
        point: point,
        state: ArcAdminMapMarkerState.published,
        adminVerified: true,
      );

      final states = <String, ArcBlueprintState>{
        for (final blueprint in ArcBlueprintSeedData.blueprints)
          blueprint.id: ArcBlueprintState.empty(
            blueprint.id,
          ).copyWith(owned: blueprint.id != 'tempest'),
      };

      final clusters = const ArcRaidIntelligenceEngine().opportunityClusters(
        map: map,
        blueprintStates: states,
        canonicalMarkers: <ArcAdminMapMarker>[marker],
      );
      final tempest = clusters.firstWhere(
        (cluster) => cluster.blueprintIds.contains('tempest'),
      );

      expect(tempest.point.x, point.x);
      expect(tempest.point.y, point.y);
      expect(tempest.label, contains('Town Hall'));
      final seededEvidence = tempest.evidence.firstWhere(
        (item) => item.sourceCategory == 'community_research_seed',
      );
      expect(seededEvidence.sourceReference, isEmpty);
      expect(seededEvidence.notes, isEmpty);
      expect(seededEvidence.publishedAt, isNull);
      expect(seededEvidence.reviewedAt, isNull);
    },
  );

  test('community seed stays dormant before Blueprint state hydration', () {
    final map = ArcRaidIntelligenceSeedData.mapById('buried_city');
    final clusters = const ArcRaidIntelligenceEngine().opportunityClusters(
      map: map,
      blueprintStates: const <String, ArcBlueprintState>{},
      canonicalMarkers: const <ArcAdminMapMarker>[],
    );
    expect(
      clusters
          .expand((cluster) => cluster.evidence)
          .any((item) => item.sourceCategory == 'community_research_seed'),
      isFalse,
    );
  });
}
