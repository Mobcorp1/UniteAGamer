import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_published_report_pois.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_intelligence_location_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_opportunity_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';

const marker = ArcAdminMapMarker(
  id: 'published_document_id',
  mapId: 'stella_montis',
  layer: ArcRaidMapLayer.surface,
  kind: ArcAdminMapMarkerKind.poi,
  name: 'Town Hall',
  aliases: ['Old Town Hall'],
  point: ArcNormalizedPoint(x: .2, y: .3),
  state: ArcAdminMapMarkerState.published,
  seedReferenceId: 'canonical_town_hall',
  subtypeId: 'future_subtype',
  subtypeLabel: 'Future subtype',
  blueprintId: 'anvil',
  description: 'Keep me',
  sourceRecordId: 'source_record',
);

void main() {
  const resolver = ArcIntelligenceLocationResolver();
  final map = ArcRaidIntelligenceSeedData.mapById('stella_montis');
  test(
    'location choices include published named locations for the selected map only',
    () {
      final choices = ArcPublishedReportPois.forMap('Stella Montis', [
        marker,
        marker.copyWith(id: 'draft', state: ArcAdminMapMarkerState.draft),
        marker.copyWith(id: 'archived', state: ArcAdminMapMarkerState.archived),
        marker.copyWith(id: 'other_map', mapId: 'buried_city'),
        marker.copyWith(id: 'loot', kind: ArcAdminMapMarkerKind.weaponCase),
        marker.copyWith(id: 'enemy', kind: ArcAdminMapMarkerKind.arcSpawn),
      ]);
      expect(choices.map((m) => m.id), ['published_document_id']);
      expect(choices.single.name, 'Town Hall');
    },
  );
  test(
    'cross-layer patch touches layer only, preserving all current and future metadata',
    () {
      final moved = marker.copyWith(layer: ArcRaidMapLayer.underground);
      final patch = ArcAdminMapEditorRepository.markerEditPatch(
        original: marker,
        edited: moved,
      );
      expect(patch, {'layer': 'underground'});
      final stored = {
        ...marker.toMap(),
        'futureCanonicalLink': 'keep',
        ...patch,
      };
      expect(stored['id'], marker.id);
      expect(stored['state'], 'published');
      expect(stored['point'], marker.point.toMap());
      expect(stored['futureCanonicalLink'], 'keep');
      expect(ArcAdminMapMarker.fromMap(stored).toMap(), moved.toMap());
    },
  );
  test('identity changes and unsupported destination layers are rejected', () {
    expect(
      () => ArcAdminMapEditorRepository.markerEditPatch(
        original: marker,
        edited: marker.copyWith(id: 'duplicate'),
      ),
      throwsArgumentError,
    );
    final single = marker.copyWith(mapId: 'buried_city');
    expect(
      () => ArcAdminMapEditorRepository.markerEditPatch(
        original: single,
        edited: single.copyWith(layer: ArcRaidMapLayer.underground),
      ),
      throwsArgumentError,
    );
  });
  final report = ArcBlueprintDropReport(
    id: 'report',
    blueprintId: 'anvil',
    userId: 'reporter',
    mapName: 'Stella Montis',
    sourceType: ArcDropSourceType.poi,
    markerId: marker.id,
    poiId: marker.seedReferenceId,
    poiName: marker.name,
    poiLayer: marker.layer,
    historicalPoint: marker.point,
    mode: ArcRaidMode.dayRaid,
    raidType: ArcRaidType.fullRaid,
    entryTime: ArcEntryTime.unknown,
    timeOfDay: ArcTimeOfDay.midday,
    createdAt: DateTime.utc(2026, 9, 14),
    confirmationCount: 1,
    confirmedByUserIds: ['reporter'],
  );
  test(
    'report retains stable marker identity, readable name, and historical location',
    () {
      final restored = ArcBlueprintDropReport.fromMap(report.toMap());
      expect(restored.markerId, marker.id);
      expect(restored.intelligencePoiName, marker.name);
      expect(
        ArcBlueprintDropReport.fromMap(
          report.copyWith(poiName: 'town hall').toMap(),
        ).intelligencePoiName,
        'town hall',
      );
      expect(restored.intelligencePoiId, marker.seedReferenceId);
      expect(restored.historicalPoint!.toMap(), marker.point.toMap());
      expect(restored.intelligenceLayer, marker.layer);
      expect(restored.countsForMapIntelligence, isTrue);
      expect(
        restored.copyWith(withdrawn: true).countsForMapIntelligence,
        isFalse,
      );
      expect(
        restored.copyWith(disputed: true).countsForMapIntelligence,
        isFalse,
      );
    },
  );
  test(
    'existing report follows current point and layer without a report rewrite',
    () {
      final moved = marker.copyWith(
        layer: ArcRaidMapLayer.underground,
        name: 'Town Hall Corrected',
        point: const ArcNormalizedPoint(x: .8, y: .7),
      );
      for (final current in [marker, moved]) {
        final clusters = const ArcBlueprintOpportunityEngine().build(
          map: map,
          reports: [report],
          canonicalMarkers: [current],
          now: DateTime.utc(2026, 9, 14),
        );
        expect(clusters.single.point.toMap(), current.point.toMap());
        expect(clusters.single.layer, current.layer);
        expect(
          const ArcBlueprintOpportunityEngine().layerForCluster(
            map,
            clusters.single,
          ),
          current.layer,
        );
        expect(clusters.single.label, contains(current.name));
      }
      expect(report.historicalPoint!.x, .2);
    },
  );
  test(
    'actual document ID takes priority over competing seed/name matches',
    () {
      final other = marker.copyWith(
        id: 'other',
        point: const ArcNormalizedPoint(x: .9, y: .9),
      );
      final result = resolver.resolve(
        map: map,
        adminMarkers: [other, marker],
        publishedMarkerId: marker.id,
        canonicalPoiId: marker.seedReferenceId,
      );
      expect(result!.canonicalMarker!.id, marker.id);
    },
  );
  for (final name in [' Town-Hall ', 'OLD town hall']) {
    test(
      'unique normalized name/alias resolves and proposes a safe backfill: $name',
      () {
        final resolved = resolver.resolve(
          map: map,
          adminMarkers: [marker],
          currentPoiName: name,
        )!;
        expect(resolved.canonicalMarker!.id, marker.id);
        expect(
          resolved.canonicalBackfillPatch(existingMarkerId: null)['markerId'],
          marker.id,
        );
        expect(
          resolved.canonicalBackfillPatch(existingMarkerId: 'already_linked'),
          isEmpty,
        );
      },
    );
  }
  test(
    'ambiguous names and aliases never auto-link; historical fallback stays intact',
    () {
      final duplicate = marker.copyWith(id: 'duplicate');
      final resolution = resolver.resolve(
        map: map,
        adminMarkers: [marker, duplicate],
        currentPoiName: 'Old Town Hall',
        legacyPoint: const ArcNormalizedPoint(x: .1, y: .1),
      );
      expect(resolution!.canonicalMarker, isNull);
      expect(resolution.needsAdminReview, isTrue);
      expect(
        resolution.canonicalBackfillPatch(existingMarkerId: null),
        isEmpty,
      );
      expect(resolution.point.x, .1);
    },
  );
  test('unmatched historical coordinates remain available for review', () {
    final resolution = resolver.resolve(
      map: map,
      adminMarkers: [marker],
      currentPoiName: 'Unlisted place',
      legacyPoint: const ArcNormalizedPoint(x: .4, y: .5),
    );
    expect(resolution!.point.toMap(), {'x': .4, 'y': .5});
    expect(resolution.canonicalMarker, isNull);
    expect(resolution.canonicalBackfillPatch(existingMarkerId: null), isEmpty);
  });
}
