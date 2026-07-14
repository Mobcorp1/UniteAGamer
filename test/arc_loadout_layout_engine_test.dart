import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_layout_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

void main() {
  group('dynamic attachment slots', () {
    test('zero-slot weapon returns zero slots', () {
      expect(
        ArcLoadoutCompatibilityRegistry.slotsForWeapon('Jupiter'),
        isEmpty,
      );
    });

    test('two-slot weapon returns two ordered slots', () {
      expect(ArcLoadoutCompatibilityRegistry.slotsForWeapon('Anvil'), [
        'Muzzle Mod',
        'Tech Mod',
      ]);
    });

    test('three-slot weapon returns three ordered slots', () {
      expect(ArcLoadoutCompatibilityRegistry.slotsForWeapon('Bettina'), [
        'Muzzle Mod',
        'Underbarrel Mod',
        'Stock Mod',
      ]);
    });

    test('four-slot weapon returns four ordered slots', () {
      expect(ArcLoadoutCompatibilityRegistry.slotsForWeapon('Bobcat'), [
        'Muzzle Mod',
        'Underbarrel Mod',
        'Light Magazine Mod',
        'Stock Mod',
      ]);
    });

    test('changing primary affects only primary attachments', () {
      final secondary = ['Vertical Grip II', 'Empty Slot', 'Padded Stock'];
      final primary = ArcLoadoutLayoutEngine.attachmentsForWeaponChange(
        previousWeaponName: 'Anvil',
        nextWeaponName: 'Arpeggio',
        previousAttachments: ['Muzzle Brake II', 'Anvil Splitter'],
      );

      expect(primary, [
        'Muzzle Brake II',
        'Empty Slot',
        'Empty Slot',
        'Empty Slot',
      ]);
      expect(secondary, ['Vertical Grip II', 'Empty Slot', 'Padded Stock']);
    });

    test('changing secondary affects only secondary attachments', () {
      final primary = ['Muzzle Brake II', 'Anvil Splitter'];
      final secondary = ArcLoadoutLayoutEngine.attachmentsForWeaponChange(
        previousWeaponName: 'Stitcher',
        nextWeaponName: 'Bobcat',
        previousAttachments: [
          'Empty Slot',
          'Vertical Grip II',
          'Empty Slot',
          'Empty Slot',
        ],
      );

      expect(primary, ['Muzzle Brake II', 'Anvil Splitter']);
      expect(secondary, [
        'Empty Slot',
        'Empty Slot',
        'Empty Slot',
        'Empty Slot',
      ]);
    });

    test('valid attachments survive compatible changes', () {
      final attachments = ArcLoadoutLayoutEngine.attachmentsForWeaponChange(
        previousWeaponName: 'Anvil',
        nextWeaponName: 'Arpeggio',
        previousAttachments: ['Muzzle Brake II', 'Empty Slot'],
      );

      expect(attachments.first, 'Muzzle Brake II');
    });

    test('invalid attachments are cleared', () {
      final attachments = ArcLoadoutLayoutEngine.attachmentsForWeaponChange(
        previousWeaponName: 'Anvil',
        nextWeaponName: 'Bobcat',
        previousAttachments: ['Empty Slot', 'Anvil Splitter'],
      );

      expect(attachments, [
        'Empty Slot',
        'Empty Slot',
        'Empty Slot',
        'Empty Slot',
      ]);
    });

    test('zero-slot weapons normalise to no fake placeholders', () {
      final attachments = ArcLoadoutLayoutEngine.normalisedAttachmentList(
        weaponName: 'Jupiter',
        savedAttachments: ['Compensator II'],
      );

      expect(attachments, isEmpty);
    });
  });

  group('quick use migration', () {
    test('six Quick Use slots always exist', () {
      final migration = ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
        savedItems: ['Snap Hook'],
        legacyAugment: 'Survivor',
      );

      expect(migration.quickUse, hasLength(6));
    });

    test('weapons are excluded from Quick Use', () {
      expect(ArcLoadoutLayoutEngine.quickUseOptionForName('Bobcat'), isNull);
    });

    test('attachments are excluded from Quick Use', () {
      expect(
        ArcLoadoutLayoutEngine.quickUseOptionForName('Compensator II'),
        isNull,
      );
    });

    test('augment is allowed in Quick Use', () {
      expect(
        ArcLoadoutLayoutEngine.quickUseOptionForName('Survivor')?.type,
        ArcLoadoutSlotType.augment,
      );
    });

    test('only one augment is allowed', () {
      final migration = ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
        savedItems: ['Survivor', 'Combat Augment', 'Vita Shot'],
      );
      final augmentCount = migration.quickUse
          .map(ArcLoadoutLayoutEngine.quickUseOptionForName)
          .whereType<ArcLoadoutOption>()
          .where((option) => option.type == ArcLoadoutSlotType.augment)
          .length;

      expect(augmentCount, 1);
    });

    test('legacy augment migrates into first available Quick Use slot', () {
      final migration = ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
        savedItems: ['Snap Hook', 'Vita Shot'],
        legacyAugment: 'Combat Augment',
      );

      expect(migration.quickUse[2], 'Combat Augment');
      expect(migration.augment, 'Combat Augment');
    });

    test('legacy augment does not overwrite six valid Quick Use items', () {
      final migration = ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
        savedItems: [
          'Snap Hook',
          'Vita Shot',
          'Lure Grenade',
          'Pulse Mine',
          'Triggernade',
          'Wolfpack',
        ],
        legacyAugment: 'Combat Augment',
      );

      expect(migration.quickUse, [
        'Snap Hook',
        'Vita Shot',
        'Lure Grenade',
        'Pulse Mine',
        'Triggernade',
        'Wolfpack',
      ]);
      expect(migration.augment, isEmpty);
    });

    test('save and reload preserves visible Quick Use state', () {
      final migration = ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
        savedItems: ['Survivor', 'Snap Hook', 'Vita Shot', 'Empty Slot'],
      );
      final loadout = ArcSavedLoadout(
        id: 'favourite-loadout',
        name: 'Test Loadout',
        category: ArcLoadoutCategory.saved,
        playStyle: ArcPlayerPlayStyle.balanced,
        augment: migration.augment,
        shield: 'Shield Level 2',
        primaryWeapon: 'Anvil',
        primaryAttachments: ['Empty Slot', 'Empty Slot'],
        secondaryWeapon: 'Stitcher',
        secondaryAttachments: [
          'Empty Slot',
          'Empty Slot',
          'Empty Slot',
          'Empty Slot',
        ],
        equipment: ['Snap Hook'],
        consumables: ['Vita Shot'],
        quickUse: migration.quickUse,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

      final reloaded = ArcSavedLoadout.fromMap(loadout.id, loadout.toMap());

      expect(reloaded.quickUse, migration.quickUse);
      expect(reloaded.augment, migration.augment);
    });
  });
}
