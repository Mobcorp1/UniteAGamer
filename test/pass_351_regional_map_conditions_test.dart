import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_opportunity_engine.dart';

void main() {
  test(
    'official parser reads Europe and all four regional timestamp pairs',
    () {
      const payload = '''
<html><script>
self.__next_f.push([1, "{\\"liveEntries\\":[{\\"conditionName\\":\\"Matriarch\\",\\"mapDisplayName\\":\\"The Blue Gate\\",\\"durationInSeconds\\":3600,\\"startTimestamp\\":1787295600000,\\"endTimestamp\\":1787299200000,\\"regionTimestamps\\":{\\"north-america\\":[1787320800000,1787324400000],\\"brazil\\":[1787317200000,1787320800000],\\"east-asia\\":[1787277600000,1787281200000],\\"oceania\\":[1787263200000,1787266800000]}}],\\"lookAheadMs\\":86400000,\\"serverNow\\":1787176305742}"]);
</script></html>
''';

      final snapshot = ArcRegionalMapConditionsParser.parseOfficialPage(
        payload,
      );
      expect(snapshot.entries, hasLength(1));
      final entry = snapshot.entries.single;
      expect(entry.conditionName, 'Matriarch');
      expect(entry.mapDisplayName, 'The Blue Gate');
      expect(entry.regionWindows.keys.toSet(), ArcServerRegion.values.toSet());
      expect(
        entry.windowFor(ArcServerRegion.northAmerica)!.startUtc,
        DateTime.fromMillisecondsSinceEpoch(1787320800000, isUtc: true),
      );
      expect(
        entry.windowFor(ArcServerRegion.oceania)!.endUtc,
        DateTime.fromMillisecondsSinceEpoch(1787266800000, isUtc: true),
      );
    },
  );

  test('region labels match official tracker region model', () {
    expect(ArcServerRegion.europe.label, 'Europe');
    expect(ArcServerRegion.northAmerica.key, 'north-america');
    expect(ArcServerRegion.brazil.label, 'Brazil');
    expect(ArcServerRegion.eastAsia.key, 'east-asia');
    expect(ArcServerRegion.oceania.label, 'Oceania');
  });

  test('condition-linked objective catalogue includes key ARC targets', () {
    final ids = ArcRegionalOpportunityEngine.itemRules
        .map((item) => item.id)
        .toSet();
    expect(ids, contains('matriarch-reactor'));
    expect(ids, contains('queen-reactor'));
    expect(ids, contains('harvester-rewards'));
    expect(ids, contains('arc-assessor-loot'));
  });
}
