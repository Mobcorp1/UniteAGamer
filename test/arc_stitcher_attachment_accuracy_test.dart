import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_weapon_attachment_database.dart';

void main() {
  test('Stitcher exposes verified high-end options', () {
    List<String> names(String slot) =>
        ArcLoadoutCompatibilityRegistry.compatibleAttachmentsForSlot(
          weaponName: 'Stitcher',
          slotLabel: slot,
        ).map((a) => a.name).toList();

    expect(
      names('Muzzle Mod'),
      containsAll(<String>[
        'Compensator III',
        'Silencer III',
        'Extended Barrel III',
      ]),
    );
    expect(names('Underbarrel Mod'), contains('Angled Grip III'));
    expect(names('Light Magazine Mod'), contains('Extended Light Mag III'));
    expect(
      names('Stock Mod'),
      containsAll(<String>['Stable Stock III', 'Padded Stock']),
    );
  });

  test(
    'Silencer III is find-only and Padded Stock remains blueprint craftable',
    () {
      final silencer = ArcWeaponAttachmentDatabase.attachmentForName(
        'Silencer III',
      )!;
      final padded = ArcWeaponAttachmentDatabase.attachmentForName(
        'Padded Stock',
      )!;
      expect(silencer.supportsWeapon('Stitcher'), isTrue);
      expect(silencer.findOnly, isTrue);
      expect(padded.supportsWeapon('Stitcher'), isTrue);
      expect(padded.craftable, isTrue);
      expect(
        padded.craftingRequirements.map((r) => r.label),
        containsAll(<String>['2x Mod Components', '5x Duct Tape']),
      );
    },
  );
}
