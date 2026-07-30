import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_opportunity_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  ArcBlueprintDropReport report({
    String poiId = 'blue_gate_warehouse_complex',
    String poiName = 'Warehouse Complex',
  }) {
    return ArcBlueprintDropReport(
      id: 'historic_drop',
      blueprintId: 'anvil',
      userId: 'reporter',
      mapName: ArcPoiDataStore.blueGate,
      sourceType: ArcDropSourceType.poi,
      poiId: poiId,
      poiName: poiName,
      mode: ArcRaidMode.dayRaid,
      raidType: ArcRaidType.fullRaid,
      entryTime: ArcEntryTime.unknown,
      timeOfDay: ArcTimeOfDay.midday,
      createdAt: DateTime.utc(2026, 7, 1),
      confirmationCount: 1,
      confirmedByUserIds: const <String>['reporter'],
    );
  }

  const movedAnchor = ArcAdminMapMarker(
    id: 'admin_blue_gate_warehouse',
    mapId: 'blue_gate',
    layer: ArcRaidMapLayer.underground,
    kind: ArcAdminMapMarkerKind.poi,
    name: 'Warehouse Complex - Corrected',
    aliases: <String>['Warehouse Complex'],
    point: ArcNormalizedPoint(x: 0.81, y: 0.22),
    confidence: ArcRaidIntelConfidence.confirmed,
    state: ArcAdminMapMarkerState.published,
    adminVerified: true,
    seedReferenceId: 'blue_gate_warehouse_complex',
    sourceRecordId: 'blue_gate_warehouse_complex',
  );

  test('historical Blueprint reports follow a moved canonical POI anchor', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');

    final clusters = const ArcBlueprintOpportunityEngine().build(
      map: map,
      reports: <ArcBlueprintDropReport>[report()],
      canonicalMarkers: const <ArcAdminMapMarker>[movedAnchor],
      now: DateTime.utc(2026, 7, 30),
    );

    expect(clusters, hasLength(1));
    expect(clusters.single.point.x, closeTo(0.81, 0.0001));
    expect(clusters.single.point.y, closeTo(0.22, 0.0001));
    expect(clusters.single.layer, ArcRaidMapLayer.underground);
    expect(clusters.single.evidence.single.point?.x, closeTo(0.81, 0.0001));
    expect(clusters.single.evidence.single.point?.y, closeTo(0.22, 0.0001));
  });

  test('historical POI names resolve through current marker aliases', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');

    final clusters = const ArcBlueprintOpportunityEngine().build(
      map: map,
      reports: <ArcBlueprintDropReport>[
        report(poiId: '', poiName: 'Warehouse Complex'),
      ],
      canonicalMarkers: const <ArcAdminMapMarker>[movedAnchor],
      now: DateTime.utc(2026, 7, 30),
    );

    expect(clusters, hasLength(1));
    expect(clusters.single.point.x, closeTo(0.81, 0.0001));
    expect(clusters.single.point.y, closeTo(0.22, 0.0001));
    expect(clusters.single.layer, movedAnchor.layer);
  });

  test(
    'Raid Intelligence passes live admin anchors into Blueprint clusters',
    () {
      const engine = ArcRaidIntelligenceEngine();

      final state = engine.build(
        mapId: 'blue_gate',
        dropReports: <ArcBlueprintDropReport>[report()],
        adminMarkers: const <ArcAdminMapMarker>[movedAnchor],
        activeLayer: ArcRaidMapLayer.underground,
      );

      final cluster = state.opportunityClusters.singleWhere(
        (item) =>
            item.evidence.any((evidence) => evidence.id == 'historic_drop'),
      );
      expect(cluster.point.x, closeTo(0.81, 0.0001));
      expect(cluster.point.y, closeTo(0.22, 0.0001));
      expect(cluster.layer, movedAnchor.layer);
    },
  );

  group('Buried City historical Blueprint report resolution', () {
    final map = ArcRaidIntelligenceSeedData.mapById('buried_city');
    const anchors = <ArcAdminMapMarker>[
      ArcAdminMapMarker(
        id: 'admin_buried_city_town_hall',
        mapId: 'buried_city',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.poi,
        name: 'Town Hall',
        point: ArcNormalizedPoint(x: 0.41, y: 0.36),
        confidence: ArcRaidIntelConfidence.confirmed,
        state: ArcAdminMapMarkerState.published,
        adminVerified: true,
        seedReferenceId: 'buried_city_town_hall',
      ),
      ArcAdminMapMarker(
        id: 'admin_buried_city_hospital',
        mapId: 'buried_city',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.poi,
        name: 'Hospital',
        point: ArcNormalizedPoint(x: 0.70, y: 0.29),
        confidence: ArcRaidIntelConfidence.confirmed,
        state: ArcAdminMapMarkerState.published,
        adminVerified: true,
        seedReferenceId: 'buried_city_hospital',
      ),
      ArcAdminMapMarker(
        id: 'admin_buried_city_main_street',
        mapId: 'buried_city',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.poi,
        name: 'Main Street',
        point: ArcNormalizedPoint(x: 0.31, y: 0.56),
        confidence: ArcRaidIntelConfidence.confirmed,
        state: ArcAdminMapMarkerState.published,
        adminVerified: true,
        seedReferenceId: 'buried_city_main_street',
      ),
      ArcAdminMapMarker(
        id: 'admin_buried_city_gas_station',
        mapId: 'buried_city',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.poi,
        name: 'Gas Station',
        point: ArcNormalizedPoint(x: 0.87, y: 0.13),
        confidence: ArcRaidIntelConfidence.confirmed,
        state: ArcAdminMapMarkerState.published,
        adminVerified: true,
        seedReferenceId: 'buried_city_gas_station',
      ),
      ArcAdminMapMarker(
        id: 'admin_buried_city_warehouse',
        mapId: 'buried_city',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.poi,
        name: 'Warehouse',
        point: ArcNormalizedPoint(x: 0.52, y: 0.68),
        confidence: ArcRaidIntelConfidence.confirmed,
        state: ArcAdminMapMarkerState.published,
        adminVerified: true,
        seedReferenceId: 'buried_city_warehouse',
      ),
      ArcAdminMapMarker(
        id: 'admin_buried_city_abandoned_highway_camp',
        mapId: 'buried_city',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.poi,
        name: 'Abandoned Highway Camp',
        point: ArcNormalizedPoint(x: 0.15, y: 0.42),
        confidence: ArcRaidIntelConfidence.confirmed,
        state: ArcAdminMapMarkerState.published,
        adminVerified: true,
        seedReferenceId: 'buried_city_abandoned_highway_camp',
      ),
    ];

    ArcRaidIntelCluster? clusterForPayload(Map<String, dynamic> payload) {
      final clusters = const ArcBlueprintOpportunityEngine().build(
        map: map,
        reports: <ArcBlueprintDropReport>[
          ArcBlueprintDropReport.fromMap(payload),
        ],
        canonicalMarkers: anchors,
        now: DateTime.utc(2026, 7, 30),
      );
      return clusters.isEmpty ? null : clusters.single;
    }

    test('reported location labels resolve to matching published anchors', () {
      final cases = <String, ArcNormalizedPoint>{
        'Town Hall': const ArcNormalizedPoint(x: 0.41, y: 0.36),
        'Main Street': const ArcNormalizedPoint(x: 0.31, y: 0.56),
        'Gas Station': const ArcNormalizedPoint(x: 0.87, y: 0.13),
        'Abandoned Highway Camp': const ArcNormalizedPoint(x: 0.15, y: 0.42),
      };

      for (final entry in cases.entries) {
        final cluster = clusterForPayload(<String, dynamic>{
          'id': 'report_${entry.key}',
          'blueprintId': 'patina',
          'userId': 'raider',
          'mapId': 'buried_city',
          'reportedLocation': entry.key,
          'coordinates': const <String, dynamic>{'x': 0.50, 'y': 0.50},
        });

        expect(cluster, isNotNull, reason: '${entry.key} should resolve.');
        expect(cluster!.point.x, closeTo(entry.value.x, 0.0001));
        expect(cluster.point.y, closeTo(entry.value.y, 0.0001));
      }
    });

    test('reported locations do not cross-resolve to nearby wrong POIs', () {
      final townHall = clusterForPayload(const <String, dynamic>{
        'id': 'report_town_hall',
        'blueprintId': 'patina',
        'userId': 'raider',
        'mapId': 'buried_city',
        'locationName': 'Town Hall',
      });
      final gasStation = clusterForPayload(const <String, dynamic>{
        'id': 'report_gas_station',
        'blueprintId': 'extended_barrel_ii',
        'userId': 'raider',
        'mapId': 'buried_city',
        'locationName': 'Gas Station',
      });
      final highwayCamp = clusterForPayload(const <String, dynamic>{
        'id': 'report_highway_camp',
        'blueprintId': 'bobcat',
        'userId': 'raider',
        'mapId': 'buried_city',
        'locationName': 'Abandoned Highway Camp',
      });

      expect(townHall!.point.x, isNot(closeTo(0.70, 0.0001)));
      expect(gasStation!.point.x, isNot(closeTo(0.41, 0.0001)));
      expect(highwayCamp!.point.x, isNot(closeTo(0.52, 0.0001)));
    });

    test('First Wave Cache remains unresolved without explicit support', () {
      final cluster = clusterForPayload(const <String, dynamic>{
        'id': 'report_first_wave_cache',
        'blueprintId': 'alto',
        'userId': 'raider',
        'mapId': 'buried_city',
        'reportedLocation': 'First Wave Cache',
        'coordinates': <String, dynamic>{'x': 0.52, 'y': 0.68},
      });

      expect(cluster, isNull);
    });

    test('one Blueprint reported at three POIs remains three clusters', () {
      final clusters = const ArcRaidIntelligenceEngine().opportunityClusters(
        map: map,
        dropReports: <ArcBlueprintDropReport>[
          ArcBlueprintDropReport.fromMap(<String, dynamic>{
            'id': 'report_tempest_town_hall',
            'blueprintId': 'tempest',
            'userId': 'raider-a',
            'mapId': 'buried_city',
            'locationName': 'Town Hall',
          }),
          ArcBlueprintDropReport.fromMap(<String, dynamic>{
            'id': 'report_tempest_main_street',
            'blueprintId': 'tempest',
            'userId': 'raider-b',
            'mapId': 'buried_city',
            'locationName': 'Main Street',
          }),
          ArcBlueprintDropReport.fromMap(<String, dynamic>{
            'id': 'report_tempest_gas_station',
            'blueprintId': 'tempest',
            'userId': 'raider-c',
            'mapId': 'buried_city',
            'locationName': 'Gas Station',
          }),
        ],
        canonicalMarkers: anchors,
      );

      final reportClusters = clusters
          .where(
            (cluster) => cluster.evidence.any(
              (evidence) => evidence.sourceCategory == 'community_drop_report',
            ),
          )
          .toList(growable: false);
      final labels = reportClusters.map((cluster) => cluster.label).join('\n');
      expect(reportClusters.length, 3);
      expect(labels, contains('Town Hall'));
      expect(labels, contains('Main Street'));
      expect(labels, contains('Gas Station'));
    });

    test('published marker moves update historical report rendering', () {
      final moved = anchors
          .map(
            (marker) => marker.name == 'Town Hall'
                ? marker.copyWith(
                    point: const ArcNormalizedPoint(x: 0.24, y: 0.24),
                  )
                : marker,
          )
          .toList(growable: false);
      final cluster = const ArcBlueprintOpportunityEngine()
          .build(
            map: map,
            reports: <ArcBlueprintDropReport>[
              ArcBlueprintDropReport.fromMap(<String, dynamic>{
                'id': 'report_moved_town_hall',
                'blueprintId': 'patina',
                'userId': 'raider',
                'mapId': 'buried_city',
                'locationName': 'Town Hall',
              }),
            ],
            canonicalMarkers: moved,
            now: DateTime.utc(2026, 7, 30),
          )
          .single;

      expect(cluster.point.x, closeTo(0.24, 0.0001));
      expect(cluster.point.y, closeTo(0.24, 0.0001));
    });
  });
}
