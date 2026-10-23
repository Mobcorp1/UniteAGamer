import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_stencil_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_locations_panel.dart';

void main() {
  // Compile the actual Favourite Loadout screen in the FIRST PASS 21 gate.
  // Preset seeds are not saved user builds and do not expose Stencil fields.
  test(
    'preset loadouts remain compatible with the Stencil-enabled loadout screen',
    () {
      final preset = ArcLoadoutSeedData.starterLoadouts.first;
      expect(preset.primaryWeapon, isNotEmpty);
      expect(preset.secondaryWeapon, isNotEmpty);
      expect(const FavouriteLoadoutScreen(), isA<FavouriteLoadoutScreen>());
    },
  );

  test('same blueprint allows separate maps, drawers and sources', () {
    const first = ArcAdminMapMarker(
      id: 'first',
      mapId: 'buried_city',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.blueprint,
      name: 'Medical drawer',
      description: 'Drawer 1',
      blueprintId: 'bp-1',
      point: ArcNormalizedPoint(x: .3, y: .4),
    );
    const otherMap = ArcAdminMapMarker(
      id: 'other-map',
      mapId: 'spaceport',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.blueprint,
      name: 'Medical drawer',
      description: 'Drawer 1',
      blueprintId: 'bp-1',
      point: ArcNormalizedPoint(x: .3, y: .4),
    );
    final otherDrawer = first.copyWith(description: 'Drawer 2');
    final otherPoint = first.copyWith(
      point: const ArcNormalizedPoint(x: .31, y: .4),
    );
    final otherSource = first.copyWith(sourceLabel: 'Verified Room');
    final otherCondition = first.copyWith(conditionLabel: 'Night Raid');
    final exactRepeat = first.copyWith(id: 'new-id');
    expect(
      ArcAdminMapEditorRepository.isExactBlueprintLocationDuplicate(
        first,
        otherMap,
      ),
      false,
    );
    expect(
      ArcAdminMapEditorRepository.isExactBlueprintLocationDuplicate(
        first,
        otherDrawer,
      ),
      false,
    );
    expect(
      ArcAdminMapEditorRepository.isExactBlueprintLocationDuplicate(
        first,
        otherPoint,
      ),
      false,
    );
    expect(
      ArcAdminMapEditorRepository.isExactBlueprintLocationDuplicate(
        first,
        otherSource,
      ),
      false,
    );
    expect(
      ArcAdminMapEditorRepository.isExactBlueprintLocationDuplicate(
        first,
        otherCondition,
      ),
      false,
    );
    expect(
      ArcAdminMapMarker.fromMap(otherCondition.toMap()).conditionLabel,
      'Night Raid',
    );
    expect(
      ArcAdminMapEditorRepository.isExactBlueprintLocationDuplicate(
        first,
        exactRepeat,
      ),
      true,
    );
    expect(
      ArcAdminMapEditorRepository.isExactBlueprintLocationDuplicate(
        first,
        first,
      ),
      false,
    );
    final recorded = <ArcAdminMapMarker>[
      first,
      otherMap,
      otherDrawer,
      otherPoint,
      otherSource,
      otherCondition,
    ];
    expect(ArcBlueprintLocationFilter.apply(recorded).length, 6);
    expect(
      ArcBlueprintLocationFilter.apply(recorded, mapId: 'spaceport').length,
      1,
    );
    expect(
      ArcBlueprintLocationFilter.apply(
        recorded,
        sourceLabel: 'Verified Room',
      ).length,
      1,
    );
    expect(
      ArcBlueprintLocationFilter.apply(
        recorded,
        conditionLabel: 'Night Raid',
      ).length,
      1,
    );
  });

  test(
    'per-weapon stencil slots survive legacy-compatible save and restore',
    () {
      final now = DateTime.utc(2026, 10, 22);
      final loadout = ArcSavedLoadout(
        id: 'favourite-loadout',
        name: 'My Build',
        category: ArcLoadoutCategory.saved,
        playStyle: ArcPlayerPlayStyle.balanced,
        augment: 'Survivor',
        primaryWeapon: 'Anvil',
        primaryAttachments: const <String>['Empty Slot'],
        secondaryWeapon: 'Stitcher',
        secondaryAttachments: const <String>['Empty Slot'],
        equipment: const <String>[],
        consumables: const <String>[],
        primaryStencilSlot: 1,
        secondaryStencilSlot: 4,
        createdAt: now,
        updatedAt: now,
      );
      final data = loadout.toMap();
      final restored = ArcSavedLoadout.fromMap(loadout.id, data);
      expect(restored.primaryStencilSlot, 1);
      expect(restored.secondaryStencilSlot, 4);
      expect(
        ArcStencilCatalogue.nameAt(restored.primaryStencilSlot!),
        'Verdigris',
      );
      expect(
        ArcStencilCatalogue.nameAt(restored.secondaryStencilSlot!),
        'Sacrifice',
      );
      data.remove('primaryStencilSlot');
      data.remove('secondaryStencilSlot');
      final legacy = ArcSavedLoadout.fromMap(loadout.id, data);
      expect(legacy.primaryStencilSlot, isNull);
      expect(legacy.secondaryStencilSlot, isNull);
      data['primaryStencilSlot'] = 999;
      expect(
        ArcSavedLoadout.fromMap(loadout.id, data).primaryStencilSlot,
        isNull,
      );
      expect(loadout.primaryAttachments.single, 'Empty Slot');
    },
  );
}
