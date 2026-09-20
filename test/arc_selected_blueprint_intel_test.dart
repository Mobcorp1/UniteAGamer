import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_selected_blueprint_intel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_opportunity_carousel.dart';

ArcRaidIntelCluster cluster(
  String id,
  String blueprint,
  String area, {
  bool report = false,
}) => ArcRaidIntelCluster(
  id: id,
  mapId: 'blue_gate',
  label: area,
  point: const ArcNormalizedPoint(x: .3, y: .4),
  blueprintIds: [blueprint],
  reportCount: 99,
  independentReporterCount: 77,
  evidence: [
    ArcRaidIntelEvidence(
      id: 'e-$id',
      blueprintId: blueprint,
      mapId: 'blue_gate',
      approximateArea: area,
      sourceReference: report ? 'Real report' : 'Seed reference',
      sourceCategory: report ? 'community_drop_report' : 'seed',
      containerSource: 'Weapon Case',
    ),
  ],
);
const marker = ArcRaidMapMarker(
  id: 'merged',
  mapId: 'blue_gate',
  category: ArcRaidMapMarkerCategory.blueprintOpportunity,
  label: 'Merged marker',
  point: ArcNormalizedPoint(x: .3, y: .4),
  payloadId: 'a',
  clusterMemberIds: ['a_marker', 'b_marker'],
  blueprintIds: ['tempest', 'bobcat', 'wolfpack'],
);
void main() {
  final clusters = [
    cluster('a', 'tempest', 'Seed area A'),
    cluster('b', 'bobcat', 'Report area B', report: true),
    cluster('unrelated', 'wolfpack', 'Unrelated area'),
  ];
  test('member identity never borrows evidence by proximity', () {
    expect(
      resolveBlueprintMemberClusters(marker, 'bobcat', clusters).single.id,
      'b',
    );
    expect(
      resolveBlueprintMemberClusters(marker, 'wolfpack', clusters),
      isEmpty,
    );
  });
  testWidgets('swipe changes member evidence and replacement resets safely', (
    tester,
  ) async {
    Widget view(ArcRaidMapMarker m) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ArcSelectedBlueprintIntel(
            marker: m,
            clusters: clusters,
            map: ArcRaidIntelligenceSeedData.mapById('blue_gate'),
            onCentreMap: () {},
            onAddStop: (_) {},
            onOpenBlueprint: () {},
            onOpenRaidPlanner: () {},
          ),
        ),
      ),
    );
    await tester.pumpWidget(view(marker));
    expect(find.text('Seeded guidance: Seed area A'), findsOneWidget);
    expect(find.textContaining('99'), findsNothing);
    expect(find.textContaining('77'), findsNothing);
    final carousel = find.byType(ArcBlueprintOpportunityCarousel);
    await tester.ensureVisible(carousel);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Reported at Report area B'), findsOneWidget);
    expect(find.text('Seeded guidance: Seed area A'), findsNothing);
    expect(find.text('1 community reports'), findsOneWidget);
    await tester.ensureVisible(carousel);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next Blueprint'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Context unavailable'), findsOneWidget);
    expect(find.textContaining('Unrelated area'), findsNothing);
    const replacement = ArcRaidMapMarker(
      id: 'replacement',
      mapId: 'blue_gate',
      category: ArcRaidMapMarkerCategory.blueprintOpportunity,
      label: 'Replacement',
      point: ArcNormalizedPoint(x: .3, y: .4),
      payloadId: 'a',
      blueprintIds: ['tempest'],
    );
    await tester.pumpWidget(view(replacement));
    await tester.pumpAndSettle();
    expect(find.text('Seeded guidance: Seed area A'), findsOneWidget);
    expect(find.textContaining('Context unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
