import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_cluster_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('clusters nearby compatible markers without mixing layers', () {
    const engine = ArcMapMarkerClusterEngine();
    const markers = <ArcRaidMapMarker>[
      ArcRaidMapMarker(
        id: 'a',
        mapId: 'blue_gate',
        category: ArcRaidMapMarkerCategory.blueprintOpportunity,
        label: 'A',
        point: ArcNormalizedPoint(x: 0.50, y: 0.50),
      ),
      ArcRaidMapMarker(
        id: 'b',
        mapId: 'blue_gate',
        category: ArcRaidMapMarkerCategory.blueprintOpportunity,
        label: 'B',
        point: ArcNormalizedPoint(x: 0.52, y: 0.51),
      ),
      ArcRaidMapMarker(
        id: 'underground',
        mapId: 'blue_gate',
        category: ArcRaidMapMarkerCategory.blueprintOpportunity,
        label: 'Underground',
        point: ArcNormalizedPoint(x: 0.51, y: 0.51),
        layer: ArcRaidMapLayer.underground,
      ),
    ];

    final clustered = engine.cluster(markers);

    expect(clustered, hasLength(2));
    final surface = clustered.singleWhere(
      (marker) => marker.layer == ArcRaidMapLayer.surface,
    );
    expect(surface.isCluster, isTrue);
    expect(surface.count, 2);
    expect(surface.clusterMemberIds, containsAll(<String>['a', 'b']));
    expect(
      clustered
          .singleWhere((marker) => marker.layer == ArcRaidMapLayer.underground)
          .isCluster,
      isFalse,
    );
  });

  test('does not cluster categories that are disabled by contract', () {
    const engine = ArcMapMarkerClusterEngine();
    const markers = <ArcRaidMapMarker>[
      ArcRaidMapMarker(
        id: 'spawn_a',
        mapId: 'blue_gate',
        category: ArcRaidMapMarkerCategory.spawn,
        label: 'Spawn A',
        point: ArcNormalizedPoint(x: 0.50, y: 0.50),
      ),
      ArcRaidMapMarker(
        id: 'spawn_b',
        mapId: 'blue_gate',
        category: ArcRaidMapMarkerCategory.spawn,
        label: 'Spawn B',
        point: ArcNormalizedPoint(x: 0.51, y: 0.51),
      ),
    ];

    expect(engine.cluster(markers), hasLength(2));
  });
}
