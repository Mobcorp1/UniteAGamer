import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_admin_marker_subtype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_container_types.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_icon_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_upgrade_resource_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_map_filter_icon.dart';

ArcAdminMapMarker markerFor({
  String? itemId,
  String? subtypeId,
  String? label,
}) => ArcAdminMapMarker(
  id: 'resource_test',
  mapId: 'buried_city',
  layer: ArcRaidMapLayer.surface,
  kind: itemId == null
      ? ArcAdminMapMarkerKind.lootContainer
      : ArcAdminMapMarkerKind.upgrade,
  name: label ?? 'Resource location',
  subtypeId: subtypeId,
  subtypeLabel: label,
  itemId: itemId,
  point: const ArcNormalizedPoint(x: .123, y: .876),
  state: ArcAdminMapMarkerState.published,
);

void main() {
  test(
    'every canonical upgrade requirement has one selectable resource and a real asset',
    () {
      final resources = ArcMapUpgradeResourceCatalog.items;
      final requirements = ArcBenchUpgradeSeedData.requirements
          .cast<ArcBenchUpgradeRequirement>();
      expect(
        resources.map((r) => r.itemId).toSet(),
        requirements.map((r) => r.itemId).toSet(),
      );
      expect(resources.map((r) => r.itemId).toSet().length, resources.length);
      final options = ArcAdminMapMarkerSubtypeCatalog.forKind(
        ArcAdminMapMarkerKind.upgrade,
      );
      for (final resource in resources) {
        final option = options.singleWhere(
          (s) => s.upgradeResource?.itemId == resource.itemId,
        );
        expect(option.label, resource.name);
        expect(
          ArcAdminMapMarkerSubtypeCatalog.resolve(
            ArcAdminMapMarkerKind.upgrade,
            option.id,
          )?.upgradeResource,
          resource,
        );
        expect(
          File(resource.imageAsset).existsSync(),
          isTrue,
          reason: resource.imageAsset,
        );
        expect(
          ArcMapFilterIconRegistry.assetPathForSubtype(option.id),
          resource.imageAsset,
        );
        expect(
          resource.requirements,
          requirements.where((r) => r.itemId == resource.itemId).toList(),
        );
      }
      for (final item in ArcScrappySeedData.items.cast<ArcScrappyItem>()) {
        final resource = resources.singleWhere((r) => r.name == item.name);
        expect(resource.usedForScrappy, isTrue);
        expect(resource.imageAsset, item.imageAsset);
        expect(
          resource.requirements.any(
            (r) =>
                r.quantity == item.neededCount &&
                r.level == item.tier.index + 2,
          ),
          isTrue,
        );
      }
      expect(
        resources.singleWhere((r) => r.itemId == 'apricots').requirements,
        hasLength(2),
      );
    },
  );

  test(
    'one resource associates both systems when requirements share an item ID',
    () {
      final requirements = [
        const ArcBenchUpgradeRequirement(
          station: 'Scrappy',
          level: 2,
          itemId: 'shared',
          itemName: 'Shared item',
          quantity: 1,
        ),
        const ArcBenchUpgradeRequirement(
          station: 'Refiner',
          level: 2,
          itemId: 'shared',
          itemName: 'Shared item',
          quantity: 3,
        ),
      ];
      final resource = ArcMapUpgradeResourceCatalog.fromRequirements(
        requirements,
      ).single;
      expect(resource.usedForBench, isTrue);
      expect(resource.usedForScrappy, isTrue);
      expect(resource.usageLabel, 'Scrappy + Bench');
      expect(resource.requirements, requirements);
    },
  );

  test(
    'all upgrade markers survive repository preparation, Firestore and JSON round trips',
    () {
      for (final resource in ArcMapUpgradeResourceCatalog.items) {
        final original = markerFor(
          itemId: resource.itemId,
          subtypeId: resource.subtypeId,
          label: resource.name,
        );
        final prepared = ArcAdminMapEditorRepository.prepareDraftMarkersForSave(
          mapId: original.mapId,
          layer: original.layer,
          markers: [original],
          uid: 'editor',
          savedAt: DateTime.utc(2026),
        ).single;
        for (final data in [prepared.toMap(), prepared.toJsonMap()]) {
          final restored = ArcAdminMapMarker.fromMap(data);
          expect(restored.kind, ArcAdminMapMarkerKind.upgrade);
          expect(data['kind'], 'upgrade');
          expect(restored.itemId, resource.itemId);
          expect(restored.subtypeId, resource.subtypeId);
          expect(restored.point.toMap(), original.point.toMap());
          expect(restored.copyWith(name: 'Edited').itemId, resource.itemId);
          expect(restored.copyWith(clearItemId: true).itemId, isNull);
        }
      }
      final legacy = markerFor().toMap()..remove('itemId');
      expect(ArcAdminMapMarker.fromMap(legacy).itemId, isNull);
    },
  );

  test(
    'editing an Upgrade resource persists its canonical item ID in the repository patch',
    () {
      final originalResource = ArcMapUpgradeResourceCatalog.byItemId(
        'dog-collar',
      )!;
      final editedResource = ArcMapUpgradeResourceCatalog.byItemId(
        'rusted-tools',
      )!;
      final original = markerFor(
        itemId: originalResource.itemId,
        subtypeId: originalResource.subtypeId,
        label: originalResource.name,
      );
      final edited = original.copyWith(
        name: editedResource.name,
        subtypeId: editedResource.subtypeId,
        subtypeLabel: editedResource.name,
        itemId: editedResource.itemId,
      );

      final patch = ArcAdminMapEditorRepository.markerEditPatch(
        original: original,
        edited: edited,
      );

      expect(patch['itemId'], editedResource.itemId);
      expect(patch['subtypeId'], editedResource.subtypeId);
      expect(patch['subtypeLabel'], editedResource.name);
      final restored = ArcAdminMapMarker.fromMap({
        ...original.toMap(),
        ...patch,
      });
      expect(restored.itemId, editedResource.itemId);
      expect(restored.upgradeResource, editedResource);
    },
  );

  test(
    'Wheelie Bin and every existing container retain identity after reload',
    () {
      final options = ArcAdminMapMarkerSubtypeCatalog.forKind(
        ArcAdminMapMarkerKind.lootContainer,
      );
      expect(
        options.singleWhere((s) => s.id == 'wheelie_bin').label,
        'Wheelie Bin',
      );
      for (final container in ArcContainerTypes.reportable) {
        final restored = ArcAdminMapMarker.fromMap(
          markerFor(subtypeId: container.id, label: container.label).toMap(),
        );
        expect(ArcContainerTypes.byId(restored.subtypeId), container);
        expect(restored.subtypeLabel, container.label);
      }
    },
  );

  test(
    'published upgrade and Wheelie Bin markers reach the player map with icons and details',
    () {
      final resource = ArcMapUpgradeResourceCatalog.byItemId('dog-collar')!;
      for (final marker in [
        markerFor(
          itemId: resource.itemId,
          subtypeId: resource.subtypeId,
          label: resource.name,
        ),
        markerFor(subtypeId: 'wheelie_bin', label: 'Wheelie Bin'),
      ]) {
        final reloaded = ArcAdminMapMarker.fromMap(marker.toMap());
        const engine = ArcRaidIntelligenceEngine();
        final state = engine.build(
          mapId: marker.mapId,
          adminMarkers: [reloaded],
          filters: ArcRaidMapFilterState.defaults.copyWith(
            lootSources: true,
            upgrades: true,
          ),
        );
        final publicMarker = state.visibleMarkers.singleWhere(
          (m) => m.id == 'admin_${marker.id}',
        );
        expect(publicMarker.label, marker.name);
        expect(publicMarker.point.toMap(), marker.point.toMap());
        expect(
          publicMarker.iconKey,
          marker.itemId == null ? 'loot_wheelie_bin' : resource.subtypeId,
        );
        if (marker.itemId != null) {
          expect(publicMarker.tags, contains('Scrappy'));
          expect(publicMarker.detail, contains(resource.usageDetails));
        }
        expect(
          engine
              .build(mapId: marker.mapId, adminMarkers: [reloaded])
              .visibleMarkers
              .any((m) => m.id == publicMarker.id),
          isFalse,
        );
      }
    },
  );

  testWidgets('Wheelie Bin renders a bin visual after reload', (tester) async {
    final marker = ArcAdminMapMarker.fromMap(
      markerFor(subtypeId: 'wheelie_bin', label: 'Wheelie Bin').toMap(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ArcMapFilterIcon(
          iconKey: ArcMapFilterIconRegistry.iconKeyForSubtype(marker.subtypeId),
          category: ArcRaidMapMarkerCategory.fieldCrate,
          semanticLabel: marker.subtypeLabel,
        ),
      ),
    );
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
