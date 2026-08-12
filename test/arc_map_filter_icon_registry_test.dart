import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_admin_marker_subtype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_icon_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_taxonomy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_cluster_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('every canonical taxonomy icon key resolves to an SVG asset', () {
    final iconKeys = ArcMapFilterTaxonomy.all
        .map((entry) => entry.iconKey)
        .toList(growable: false);

    expect(iconKeys.toSet(), hasLength(iconKeys.length));

    for (final iconKey in iconKeys) {
      final assetPath = ArcMapFilterIconRegistry.assetPathFor(iconKey);
      expect(
        assetPath,
        isNot(ArcMapFilterIconRegistry.fallbackAssetPath),
        reason: iconKey,
      );
      expect(
        assetPath,
        '${ArcMapFilterIconRegistry.assetDirectory}/$iconKey.svg',
        reason: iconKey,
      );
      expect(assetPath, isNot(contains(' (1)')), reason: iconKey);
      expect(assetPath, isNot(contains(' ')), reason: iconKey);
      final file = File(assetPath);
      expect(file.existsSync(), isTrue, reason: assetPath);
      final svg = file.readAsStringSync();
      expect(svg.trimLeft(), startsWith('<svg '), reason: iconKey);
      expect(svg, contains('viewBox="0 0 32 32"'), reason: iconKey);
      expect(svg.trimRight(), endsWith('</svg>'), reason: iconKey);
      expect(
        svg.contains('<path') ||
            svg.contains('<circle') ||
            svg.contains('<rect'),
        isTrue,
        reason: iconKey,
      );
      expect(svg, isNot(contains('<image')), reason: iconKey);
      expect(svg, isNot(contains('base64')), reason: iconKey);
      expect(svg, isNot(contains('href=')), reason: iconKey);
      expect(svg, isNot(contains('xlink:href')), reason: iconKey);
    }
  });

  test('unknown icon keys resolve to deliberate fallback asset', () {
    final assetPath = ArcMapFilterIconRegistry.assetPathFor('custom_signal');

    expect(assetPath, ArcMapFilterIconRegistry.fallbackAssetPath);
    expect(File(assetPath).existsSync(), isTrue);
  });

  test('canonical registry assets have no duplicate filenames', () {
    final paths = ArcMapFilterIconRegistry.canonicalAssetPaths;
    final filenames = paths.map((path) => path.split('/').last).toList();

    expect(ArcMapFilterTaxonomy.all, hasLength(70));
    expect(paths.toSet(), hasLength(paths.length));
    expect(filenames.toSet(), hasLength(filenames.length));
    expect(paths, isNot(contains(ArcMapFilterIconRegistry.fallbackAssetPath)));
    expect(
      paths,
      isNot(
        contains(
          '${ArcMapFilterIconRegistry.assetDirectory}/'
          '${ArcMapFilterIconRegistry.communityReportRatIconKey}.svg',
        ),
      ),
    );
  });

  test('Report A Rat resolves as a UAG community icon', () {
    final assetPath = ArcMapFilterIconRegistry.assetPathFor(
      ArcMapFilterIconRegistry.communityReportRatIconKey,
    );

    expect(assetPath, isNot(ArcMapFilterIconRegistry.fallbackAssetPath));
    expect(
      assetPath,
      'assets/arc_raiders/map_filter_icons/community_report_rat.svg',
    );
    expect(File(assetPath).existsSync(), isTrue);
    expect(
      ArcMapFilterIconRegistry.canonicalIconKeys,
      isNot(contains(ArcMapFilterIconRegistry.communityReportRatIconKey)),
    );
    expect(
      ArcMapFilterIconRegistry.uagCommunityIconKeys,
      contains(ArcMapFilterIconRegistry.communityReportRatIconKey),
    );
  });

  test('canonical subtype resolves to icon key and asset', () {
    expect(
      ArcMapFilterIconRegistry.iconKeyForSubtype('bastion'),
      'arc_bastion',
    );
    expect(
      ArcMapFilterIconRegistry.assetPathForSubtype('raider_hatch'),
      'assets/arc_raiders/map_filter_icons/extract_raider_hatch.svg',
    );
    expect(
      ArcMapFilterIconRegistry.assetPathForSubtype('custom_raider_note'),
      ArcMapFilterIconRegistry.fallbackAssetPath,
    );
  });

  test('admin canonical subtype catalog carries taxonomy icon keys', () {
    for (final entry in ArcMapFilterTaxonomy.all) {
      final options = ArcAdminMapMarkerSubtypeCatalog.forKind(entry.kind);
      final match = options.where((option) => option.id == entry.id);

      expect(match, hasLength(1), reason: entry.id);
      expect(match.single.iconKey, entry.iconKey, reason: entry.id);
    }
  });

  test('admin markers expose canonical subtype icon key to map markers', () {
    final state = const ArcRaidIntelligenceEngine().build(
      mapId: 'dam_battlegrounds',
      filters: ArcRaidMapFilterState(
        missingBlueprints: false,
        mapBasics: true,
        includeLimitedEvidence: true,
      ),
      adminMarkers: [
        ArcAdminMapMarker(
          id: 'bastion_patrol',
          mapId: 'dam_battlegrounds',
          layer: ArcRaidMapLayer.surface,
          kind: ArcAdminMapMarkerKind.arcSpawn,
          name: 'Bastion patrol',
          subtypeId: 'bastion',
          subtypeLabel: 'Bastion',
          point: ArcNormalizedPoint(x: 0.42, y: 0.36),
          state: ArcAdminMapMarkerState.published,
          confidence: ArcRaidIntelConfidence.confirmed,
        ),
      ],
    );

    final marker = state.visibleMarkers.firstWhere(
      (item) => item.label == 'Bastion patrol',
    );
    expect(marker.iconKey, 'arc_bastion');
  });

  test('clusters preserve shared icon key and fall back for mixed icons', () {
    const engine = ArcMapMarkerClusterEngine();
    const first = ArcRaidMapMarker(
      id: 'first',
      mapId: 'dam_battlegrounds',
      category: ArcRaidMapMarkerCategory.containerCluster,
      label: 'Bastion west',
      point: ArcNormalizedPoint(x: 0.4, y: 0.4),
      iconKey: 'arc_bastion',
    );
    const second = ArcRaidMapMarker(
      id: 'second',
      mapId: 'dam_battlegrounds',
      category: ArcRaidMapMarkerCategory.containerCluster,
      label: 'Bastion east',
      point: ArcNormalizedPoint(x: 0.41, y: 0.41),
      iconKey: 'arc_bastion',
    );
    const third = ArcRaidMapMarker(
      id: 'third',
      mapId: 'dam_battlegrounds',
      category: ArcRaidMapMarkerCategory.containerCluster,
      label: 'Probe north',
      point: ArcNormalizedPoint(x: 0.42, y: 0.42),
      iconKey: 'arc_probe',
    );

    final sharedIconCluster = engine.cluster([first, second]);
    expect(sharedIconCluster, hasLength(1));
    expect(sharedIconCluster.single.iconKey, 'arc_bastion');

    final mixedIconCluster = engine.cluster([first, third]);
    expect(mixedIconCluster, hasLength(1));
    expect(mixedIconCluster.single.iconKey, isNull);
  });
}
