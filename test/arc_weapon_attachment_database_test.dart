import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_weapon_attachment_database.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

void main() {
  group('ArcWeaponAttachmentDatabase', () {
    test('uses unique stable IDs and non-empty names', () {
      final ids = ArcWeaponAttachmentDatabase.attachments
          .map((attachment) => attachment.id)
          .toSet();

      expect(ArcWeaponAttachmentDatabase.attachments, hasLength(37));
      expect(ids, hasLength(ArcWeaponAttachmentDatabase.attachments.length));
      for (final attachment in ArcWeaponAttachmentDatabase.attachments) {
        expect(attachment.id.trim(), isNotEmpty, reason: attachment.name);
        expect(attachment.name.trim(), isNotEmpty, reason: attachment.id);
      }
    });

    test('bench levels are valid for craftable and find-only attachments', () {
      for (final attachment in ArcWeaponAttachmentDatabase.attachments) {
        if (attachment.findOnly) {
          expect(attachment.benchLevel, 0, reason: attachment.name);
        } else {
          expect(attachment.benchLevel, inInclusiveRange(1, 3));
        }
      }
    });

    test('TBA attachments are find-only and do not expose fake recipes', () {
      final findOnly = ArcWeaponAttachmentDatabase.attachments
          .where((attachment) => attachment.findOnly)
          .toList(growable: false);

      expect(findOnly.map((attachment) => attachment.name), [
        'Kinetic Converter',
        'Anvil Splitter',
      ]);
      for (final attachment in findOnly) {
        expect(attachment.craftable, isFalse, reason: attachment.name);
        expect(
          attachment.craftingRequirements,
          isEmpty,
          reason: attachment.name,
        );
        expect(attachment.materials, isEmpty, reason: attachment.name);
        expect(attachment.materialSummary, 'No bench recipe');
      }
    });

    test('craftable attachments have recipes with positive quantities', () {
      final craftable = ArcWeaponAttachmentDatabase.attachments
          .where((attachment) => attachment.craftable)
          .toList(growable: false);

      expect(craftable, hasLength(35));
      for (final attachment in craftable) {
        expect(
          attachment.craftingRequirements,
          isNotEmpty,
          reason: attachment.name,
        );
        expect(attachment.materials, isNotEmpty, reason: attachment.name);
        for (final requirement in attachment.craftingRequirements) {
          expect(
            requirement.itemName.trim(),
            isNotEmpty,
            reason: attachment.name,
          );
          expect(requirement.quantity, greaterThan(0), reason: attachment.name);
        }
      }
    });

    test('all compatible weapon names exist in the weapon matrix', () {
      final knownWeapons = ArcLoadoutSeedData.weapons
          .map((weapon) => weapon.name)
          .toSet();

      for (final attachment in ArcWeaponAttachmentDatabase.attachments) {
        for (final weaponName in attachment.compatibleWeapons) {
          expect(knownWeapons, contains(weaponName), reason: attachment.name);
        }
      }
    });

    test('slot types resolve for representative attachment families', () {
      expect(
        ArcWeaponAttachmentDatabase.attachmentForName(
          'Compensator I',
        )?.slotType,
        ArcAttachmentSlotType.muzzle,
      );
      expect(
        ArcWeaponAttachmentDatabase.attachmentForName(
          'Shotgun Choke III',
        )?.slotType,
        ArcAttachmentSlotType.shotgunMuzzle,
      );
      expect(
        ArcWeaponAttachmentDatabase.attachmentForName(
          'Horizontal Grip',
        )?.slotType,
        ArcAttachmentSlotType.underbarrel,
      );
      expect(
        ArcWeaponAttachmentDatabase.attachmentForName(
          'Extended Barrel',
        )?.slotType,
        ArcAttachmentSlotType.barrel,
      );
      expect(
        ArcWeaponAttachmentDatabase.attachmentForName(
          'Kinetic Converter',
        )?.slotType,
        ArcAttachmentSlotType.converter,
      );
      expect(
        ArcWeaponAttachmentDatabase.attachmentForName(
          'Anvil Splitter',
        )?.slotType,
        ArcAttachmentSlotType.special,
      );
    });

    test('Favourite Loadout compatibility reads the master database', () {
      expect(
        ArcLoadoutSeedData.attachments,
        same(ArcWeaponAttachmentDatabase.attachments),
      );
      expect(
        ArcLoadoutCompatibilityRegistry.attachmentSpecForName(
          'Kinetic Converter',
        ),
        same(
          ArcWeaponAttachmentDatabase.attachmentForName('Kinetic Converter'),
        ),
      );

      final rattlerConverterOptions =
          ArcLoadoutCompatibilityRegistry.compatibleAttachmentsForSlot(
            weaponName: 'Rattler',
            slotLabel: 'Converter',
          );

      expect(
        rattlerConverterOptions.map((attachment) => attachment.name),
        contains('Kinetic Converter'),
      );
    });

    test('Kinetic Converter and Anvil Splitter are find-only', () {
      final kinetic = ArcWeaponAttachmentDatabase.attachmentForName(
        'Kinetic Converter',
      )!;
      final splitter = ArcWeaponAttachmentDatabase.attachmentForName(
        'Anvil Splitter',
      )!;

      expect(kinetic.findOnly, isTrue);
      expect(kinetic.craftable, isFalse);
      expect(splitter.findOnly, isTrue);
      expect(splitter.craftable, isFalse);
    });

    test('asset resolver returns stable attachment paths', () {
      for (final attachment in ArcWeaponAttachmentDatabase.attachments) {
        final resolved = ArcLoadoutAssetRegistry.assetFor(
          itemName: attachment.name,
          kind: ArcLoadoutAssetKind.attachment,
        );

        expect(resolved, attachment.imageAssetPath, reason: attachment.name);
        expect(File(resolved!).existsSync(), isTrue, reason: attachment.name);
      }
    });

    test('expected Blueprint Grid artwork gaps are explicit', () {
      final missingExpectedBlueprints = ArcWeaponAttachmentDatabase.attachments
          .where(
            (attachment) => !File(
              ArcWeaponAttachmentDatabase.expectedBlueprintAssetPath(
                attachment,
              ),
            ).existsSync(),
          )
          .map((attachment) => attachment.name)
          .toList(growable: false);

      expect(missingExpectedBlueprints, [
        'Compensator I',
        'Muzzle Brake I',
        'Shotgun Choke I',
        'Angled Grip I',
        'Vertical Grip I',
        'Extended Light Mag I',
        'Extended Medium Mag I',
        'Extended Shotgun Mag I',
        'Stable Stock I',
        'Silencer III',
        'Horizontal Grip',
      ]);
    });

    test('saved loadout serialization remains backward compatible', () {
      final legacy = ArcSavedLoadout.fromMap(
        'legacy-loadout',
        <String, dynamic>{
          'name': 'Legacy Loadout',
          'category': 'saved',
          'playStyle': 'balanced',
          'augment': 'Survivor',
          'primaryWeapon': 'Rattler',
          'primaryAttachments': ['Kinetic Converter'],
          'secondaryWeapon': 'Anvil',
          'secondaryAttachments': ['Anvil Splitter'],
          'equipment': ['Snap Hook'],
          'consumables': ['Vita Shot'],
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        },
      );

      expect(legacy.primaryAttachments, ['Kinetic Converter']);
      expect(legacy.secondaryAttachments, ['Anvil Splitter']);
      expect(legacy.quickUse, isEmpty);
      expect(legacy.toMap()['primaryAttachments'], ['Kinetic Converter']);
    });
  });
}
