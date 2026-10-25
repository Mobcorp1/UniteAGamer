import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_stencil_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_weapon_stencil_compatibility.dart';
import 'dart:io';

void main() {
  test('all 14 Stencil slots keep existing asset and saved indices', () {
    expect(ArcStencilCatalogue.names.length, 14);
    expect(ArcWeaponStencilCompatibility.displayName(6), 'Cerulean');
    expect(ArcStencilCatalogue.assetAt(6), endsWith('curulean.webp'));
  });

  test('three broad-use Stencils apply to the documented 20 standard guns', () {
    const guns = <String>[
      'Anvil',
      'Arpeggio',
      'Bantam',
      'Bettina',
      'Bobcat',
      'Burletta',
      'Canto',
      'Ferro',
      'Hairpin',
      'Il Toro',
      'Kettle',
      'Osprey',
      'Rattler',
      'Renegade',
      'Stiletto',
      'Stitcher',
      'Tempest',
      'Torrente',
      'Venator',
      'Vulcano',
    ];
    expect(guns.length, 20);
    for (final gun in guns) {
      for (final common in <int>[1, 13, 14]) {
        expect(
          ArcWeaponStencilCompatibility.isCompatible(
            weaponName: gun,
            slot: common,
          ),
          isTrue,
          reason: '$gun / $common',
        );
      }
    }
    for (final gun in <String>[
      'Aphelion',
      'Equalizer',
      'Jupiter',
      'Rascal',
      'Hullcracker',
    ]) {
      for (final common in <int>[1, 13, 14]) {
        expect(
          ArcWeaponStencilCompatibility.isCompatible(
            weaponName: gun,
            slot: common,
          ),
          isFalse,
          reason: '$gun / $common',
        );
      }
    }
  });

  test('specialty skins only apply to documented firearms', () {
    const cases = <int, List<String>>{
      2: ['Anvil', 'Il Toro', 'Rattler'],
      3: ['Anvil', 'Rattler'],
      4: ['Renegade'],
      5: ['Burletta', 'Canto', 'Ferro', 'Hairpin', 'Kettle', 'Renegade'],
      6: [
        'Anvil',
        'Arpeggio',
        'Bantam',
        'Bettina',
        'Bobcat',
        'Osprey',
        'Venator',
        'Vulcano',
      ],
      7: ['Burletta', 'Il Toro', 'Rattler', 'Stiletto', 'Tempest', 'Torrente'],
      8: ['Hullcracker'],
      9: ['Tempest'],
      10: ['Osprey'],
      11: ['Anvil'],
      12: ['Bobcat'],
    };
    const candidateGuns = <String>[
      'Anvil',
      'Arpeggio',
      'Bantam',
      'Bettina',
      'Bobcat',
      'Burletta',
      'Canto',
      'Ferro',
      'Hairpin',
      'Il Toro',
      'Kettle',
      'Osprey',
      'Rattler',
      'Renegade',
      'Stiletto',
      'Stitcher',
      'Tempest',
      'Torrente',
      'Venator',
      'Vulcano',
      'Hullcracker',
      'Aphelion',
      'Equalizer',
      'Jupiter',
      'Rascal',
    ];
    for (final entry in cases.entries) {
      for (final gun in candidateGuns) {
        expect(
          ArcWeaponStencilCompatibility.isCompatible(
            weaponName: gun,
            slot: entry.key,
          ),
          entry.value.contains(gun),
          reason: '$gun / ${entry.key}',
        );
      }
    }
    expect(ArcWeaponStencilCompatibility.slotsForWeapon('Hullcracker'), [8]);
    expect(ArcWeaponStencilCompatibility.slotsForWeapon('Anvil'), [
      1,
      2,
      3,
      6,
      11,
      13,
      14,
    ]);
    expect(ArcWeaponStencilCompatibility.slotsForWeapon('Jupiter'), isEmpty);
  });

  test('previous saved incompatible Stencils are safely hidden', () {
    expect(
      ArcWeaponStencilCompatibility.compatibleSavedSlot(
        weaponName: 'Bobcat',
        slot: 11,
      ),
      isNull,
    );
    expect(
      ArcWeaponStencilCompatibility.compatibleSavedSlot(
        weaponName: 'Bobcat',
        slot: 12,
      ),
      12,
    );
    expect(
      ArcWeaponStencilCompatibility.compatibleSavedSlot(
        weaponName: 'Tempest',
        slot: 9,
      ),
      9,
    );
    expect(
      ArcWeaponStencilCompatibility.compatibleSavedSlot(
        weaponName: 'Tempest',
        slot: 17,
      ),
      isNull,
    );
  });

  test('picker filters before showing owned or locked Stencil choices', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    ).readAsStringSync();
    expect(
      RegExp(
        r'ArcWeaponStencilCompatibility\.slotsForWeapon\s*\(\s*weaponName\s*,?\s*\)',
      ).hasMatch(source),
      isTrue,
    );
    expect(source, contains('itemCount: compatibleSlots.length + 1'));
    expect(source, contains('final slot = compatibleSlots[index - 1]'));
    expect(source, contains('owned.contains(slot)'));
    expect(
      source,
      contains('ArcWeaponStencilCompatibility.compatibleSavedSlot('),
    );
  });
}
