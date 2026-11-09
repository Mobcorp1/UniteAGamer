import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_loadout_bridge.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_layout_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

void main() {
  group('ArcBlueprintLoadoutBridge', () {
    test('classifies only loadout-eligible blueprint items', () {
      final bobcat = _blueprint('Bobcat');
      final silencer = _blueprint('Silencer II');
      final wolfpack = _blueprint('Wolfpack');
      final mediumGunParts = _blueprint('Medium Gun Parts');

      expect(
        ArcBlueprintLoadoutBridge.candidateFor(bobcat)?.kind,
        ArcBlueprintLoadoutKind.weapon,
      );
      expect(
        ArcBlueprintLoadoutBridge.candidateFor(silencer)?.kind,
        ArcBlueprintLoadoutKind.attachment,
      );
      expect(
        ArcBlueprintLoadoutBridge.candidateFor(wolfpack)?.kind,
        ArcBlueprintLoadoutKind.quickUse,
      );
      expect(ArcBlueprintLoadoutBridge.candidateFor(mediumGunParts), isNull);
    });

    test('creates a safe default favourite loadout when none exists', () {
      final loadout = ArcBlueprintLoadoutBridge.baseLoadout(null);

      expect(loadout.id, 'favourite-loadout');
      expect(loadout.primaryWeapon, 'Anvil');
      expect(loadout.secondaryWeapon, 'Stitcher');
      expect(loadout.quickUse, hasLength(6));
    });

    test('weapon blueprints can target primary or secondary slots', () {
      final bobcat = _blueprint('Bobcat');
      final loadout = ArcBlueprintLoadoutBridge.baseLoadout(null);
      final destinations = ArcBlueprintLoadoutBridge.destinationsFor(
        blueprint: bobcat,
        loadout: loadout,
      );

      expect(
        destinations.map((destination) => destination.type),
        containsAll(<ArcBlueprintLoadoutDestinationType>[
          ArcBlueprintLoadoutDestinationType.primaryWeapon,
          ArcBlueprintLoadoutDestinationType.secondaryWeapon,
        ]),
      );

      final next = ArcBlueprintLoadoutBridge.applyDestination(
        blueprint: bobcat,
        loadout: loadout,
        destination: destinations.firstWhere(
          (destination) =>
              destination.type ==
              ArcBlueprintLoadoutDestinationType.primaryWeapon,
        ),
      );

      expect(next.primaryWeapon, 'Bobcat');
      expect(
        ArcBlueprintLoadoutBridge.isSelected(blueprint: bobcat, loadout: next),
        isTrue,
      );
    });

    test('attachment destinations respect current weapon compatibility', () {
      final silencer = _blueprint('Silencer II');
      final loadout = ArcBlueprintLoadoutBridge.baseLoadout(null);
      final destinations = ArcBlueprintLoadoutBridge.destinationsFor(
        blueprint: silencer,
        loadout: loadout,
      );

      expect(destinations, isNotEmpty);
      expect(
        destinations.map((destination) => destination.label),
        contains('Primary Muzzle Mod'),
      );
      expect(
        destinations.every(
          (destination) =>
              destination.type ==
                  ArcBlueprintLoadoutDestinationType.primaryAttachment ||
              destination.type ==
                  ArcBlueprintLoadoutDestinationType.secondaryAttachment,
        ),
        isTrue,
      );
    });

    test(
      'quick-use items fill empty slots before replacing occupied slots',
      () {
        final wolfpack = _blueprint('Wolfpack');
        final loadout = ArcBlueprintLoadoutBridge.baseLoadout(null);
        final destinations = ArcBlueprintLoadoutBridge.destinationsFor(
          blueprint: wolfpack,
          loadout: loadout,
        );

        expect(destinations, isNotEmpty);
        expect(destinations.first.replacesOccupiedSlot, isFalse);

        final next = ArcBlueprintLoadoutBridge.applyDestination(
          blueprint: wolfpack,
          loadout: loadout,
          destination: destinations.first,
        );

        expect(next.quickUse, contains('Wolfpack'));
        expect(next.equipment, contains('Wolfpack'));

        final removed = ArcBlueprintLoadoutBridge.remove(
          blueprint: wolfpack,
          loadout: next,
        );
        expect(removed.quickUse, isNot(contains('Wolfpack')));
      },
    );

    test('full quick-use bars expose replacement destinations', () {
      final wolfpack = _blueprint('Wolfpack');
      final base = ArcBlueprintLoadoutBridge.baseLoadout(null);

      // This fixture must be full before checking replacement destinations.
      const fullQuickUse = <String>[
        'Survivor',
        'Snap Hook',
        'Vita Shot',
        'Lure Grenade',
        'Wolfpack',
        'Pulse Mine',
      ];
      for (final itemName in fullQuickUse) {
        expect(
          ArcLoadoutLayoutEngine.quickUseOptionForName(itemName),
          isNotNull,
          reason: '${itemName} must be a supported quick-use option',
        );
      }
      final normalised = ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
        savedItems: fullQuickUse,
      ).quickUse;
      expect(normalised, hasLength(6));
      expect(
        normalised,
        everyElement(isNot(ArcLoadoutLayoutEngine.emptySlot)),
      );

      final filled = ArcSavedLoadout(
        id: base.id,
        name: base.name,
        category: base.category,
        playStyle: base.playStyle,
        augment: base.augment,
        shield: base.shield,
        primaryWeapon: base.primaryWeapon,
        primaryAttachments: base.primaryAttachments,
        secondaryWeapon: base.secondaryWeapon,
        secondaryAttachments: base.secondaryAttachments,
        equipment: const <String>['Snap Hook', 'Wolfpack', 'Pulse Mine'],
        consumables: const <String>['Vita Shot', 'Lure Grenade'],
        quickUse: normalised,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
      );

      final replacements = ArcBlueprintLoadoutBridge.destinationsFor(
        blueprint: wolfpack,
        loadout: filled,
      );

      expect(replacements, hasLength(6));
      expect(
        replacements.map((destination) => destination.index).toSet(),
        <int>{0, 1, 2, 3, 4, 5},
      );
      expect(
        replacements.every((destination) => destination.replacesOccupiedSlot),
        isTrue,
      );
    });

    test(
      'lists every assigned loadout item backed by a blueprint grid record',
      () {
        final silencer = _blueprint('Silencer II');
        final loadout = ArcBlueprintLoadoutBridge.applyDestination(
          blueprint: silencer,
          loadout: ArcBlueprintLoadoutBridge.baseLoadout(null),
          destination:
              ArcBlueprintLoadoutBridge.destinationsFor(
                blueprint: silencer,
                loadout: ArcBlueprintLoadoutBridge.baseLoadout(null),
              ).firstWhere(
                (destination) =>
                    destination.type ==
                    ArcBlueprintLoadoutDestinationType.primaryAttachment,
              ),
        );

        final requirements = ArcBlueprintLoadoutBridge.blueprintRequirementsFor(
          loadout,
        );

        expect(
          requirements.map((requirement) => requirement.blueprintId),
          containsAll(<String>['anvil', 'silencer-ii']),
        );
        expect(
          requirements.map((requirement) => requirement.itemName),
          isNot(contains('Stitcher')),
        );
      },
    );
  });
}

ArcBlueprint _blueprint(String name) {
  return ArcBlueprintSeedData.blueprints.firstWhere(
    (blueprint) => blueprint.name == name,
  );
}
