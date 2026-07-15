import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_weapon_attachment_database.dart';

void main() {
  group('loadout asset integrity', () {
    test('canonical weapon image paths exist', () {
      for (final weapon in ArcLoadoutSeedData.weapons) {
        final path = ArcLoadoutAssetRegistry.assetFor(
          itemName: weapon.name,
          kind: ArcLoadoutAssetKind.primaryWeapon,
        );

        expect(path, isNotNull, reason: weapon.name);
        expect(File(path!).existsSync(), isTrue, reason: weapon.name);
      }
    });

    test('canonical attachment image paths exist', () {
      for (final attachment in ArcWeaponAttachmentDatabase.attachments) {
        final path = ArcLoadoutAssetRegistry.assetFor(
          itemName: attachment.name,
          kind: ArcLoadoutAssetKind.attachment,
        );

        expect(path, isNotNull, reason: attachment.name);
        expect(File(path!).existsSync(), isTrue, reason: attachment.name);
      }
    });

    test(
      'migrated Hairpin and attachment assets resolve to kebab-case files',
      () {
        final hairpin = ArcLoadoutAssetRegistry.assetFor(
          itemName: 'Hairpin',
          kind: ArcLoadoutAssetKind.primaryWeapon,
        );
        final blueprintHairpin = ArcBlueprintAssetRegistry.assetFor('Hairpin');
        final kinetic = ArcLoadoutAssetRegistry.assetFor(
          itemName: 'Kinetic Converter',
          kind: ArcLoadoutAssetKind.attachment,
        );
        final splitter = ArcLoadoutAssetRegistry.assetFor(
          itemName: 'Anvil Splitter',
          kind: ArcLoadoutAssetKind.attachment,
        );

        expect(
          hairpin,
          'assets/images/arc_raiders/loadouts/weapons/hairpin.webp',
        );
        expect(blueprintHairpin, 'assets/arc_raiders/blueprints/hairpin.webp');
        expect(kinetic, 'assets/arc_raiders/blueprints/kinetic-converter.webp');
        expect(splitter, 'assets/arc_raiders/blueprints/anvil-splitter.webp');
      },
    );

    test('canonical runtime paths avoid migrated legacy filename patterns', () {
      final paths = <String>[
        for (final weapon in ArcLoadoutSeedData.weapons)
          ArcLoadoutAssetRegistry.assetFor(
            itemName: weapon.name,
            kind: ArcLoadoutAssetKind.primaryWeapon,
          )!,
        for (final attachment in ArcWeaponAttachmentDatabase.attachments)
          ArcLoadoutAssetRegistry.assetFor(
            itemName: attachment.name,
            kind: ArcLoadoutAssetKind.attachment,
          )!,
        ArcBlueprintAssetRegistry.assetFor('Hairpin')!,
        ArcBlueprintAssetRegistry.assetFor('Kinetic Converter')!,
        ArcBlueprintAssetRegistry.assetFor('Anvil Splitter')!,
      ];

      for (final path in paths) {
        expect(path, isNot(contains(_legacy('ha', 'rpin'))), reason: path);
        expect(
          path,
          isNot(contains(_legacy('anvil_', 'splitter'))),
          reason: path,
        );
        expect(
          path,
          isNot(contains(_legacy('kinetic_', 'converter'))),
          reason: path,
        );
        expect(path, isNot(contains(' (1)')), reason: path);
      }
    });
  });
}

String _legacy(String prefix, String suffix) => '$prefix$suffix';
