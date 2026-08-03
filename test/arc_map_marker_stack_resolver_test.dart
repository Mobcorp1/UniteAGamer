import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_stack_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('resolves nearby same-layer markers into a selectable stack', () {
    const resolver = ArcMapMarkerStackResolver();
    const selected = ArcRaidMapMarker(
      id: 'resource',
      mapId: 'blue_gate',
      category: ArcRaidMapMarkerCategory.generalLoot,
      label: 'Great Mullein',
      point: ArcNormalizedPoint(x: 0.50, y: 0.50),
    );
    const container = ArcRaidMapMarker(
      id: 'container',
      mapId: 'blue_gate',
      category: ArcRaidMapMarkerCategory.raiderCache,
      label: 'Raider Cache',
      point: ArcNormalizedPoint(x: 0.506, y: 0.502),
    );
    const underground = ArcRaidMapMarker(
      id: 'underground',
      mapId: 'blue_gate',
      category: ArcRaidMapMarkerCategory.raiderCache,
      label: 'Level 2 Cache',
      point: ArcNormalizedPoint(x: 0.501, y: 0.501),
      layer: ArcRaidMapLayer.underground,
    );

    final stack = resolver.stackFor(
      selected: selected,
      markers: const <ArcRaidMapMarker>[underground, container, selected],
    );

    expect(stack.map((marker) => marker.id), <String>['resource', 'container']);
  });
}
