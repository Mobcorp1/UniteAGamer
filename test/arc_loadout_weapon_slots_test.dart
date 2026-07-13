import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_weapon_catalog.dart';

void main() {
  const expectedSlots = <String, List<String>>{
    'Anvil': ['Muzzle Mod', 'Tech Mod'],
    'Aphelion': ['Underbarrel Mod', 'Stock Mod'],
    'Arpeggio': [
      'Muzzle Mod',
      'Underbarrel Mod',
      'Medium Magazine Mod',
      'Stock Mod',
    ],
    'Bettina': ['Muzzle Mod', 'Underbarrel Mod', 'Stock Mod'],
    'Bobcat': [
      'Muzzle Mod',
      'Underbarrel Mod',
      'Light Magazine Mod',
      'Stock Mod',
    ],
    'Burletta': ['Muzzle Mod', 'Light Magazine Mod'],
    'Canto': [
      'Muzzle Mod',
      'Underbarrel Mod',
      'Medium Magazine Mod',
      'Stock Mod',
    ],
    'Equalizer': [],
    'Ferro': ['Muzzle Mod', 'Underbarrel Mod', 'Stock Mod'],
    'Hairpin': ['Light Magazine Mod'],
    'Hullcracker': ['Underbarrel Mod', 'Stock Mod'],
    'Il Toro': [
      'Shotgun Muzzle Mod',
      'Underbarrel Mod',
      'Shotgun Magazine Mod',
      'Stock Mod',
    ],
    'Jupiter': [],
    'Kettle': [
      'Muzzle Mod',
      'Underbarrel Mod',
      'Light Magazine Mod',
      'Stock Mod',
    ],
    'Osprey': [
      'Muzzle Mod',
      'Underbarrel Mod',
      'Medium Magazine Mod',
      'Stock Mod',
    ],
    'Rascal': [],
    'Rattler': ['Stock Mod', 'Converter'],
    'Renegade': ['Muzzle Mod', 'Underbarrel Mod', 'Stock Mod'],
    'Stitcher': ['Muzzle Mod', 'Underbarrel Mod', 'Magazine Mod', 'Stock Mod'],
    'Tempest': ['Muzzle Mod', 'Underbarrel Mod', 'Medium Magazine Mod'],
    'Torrente': ['Muzzle Mod', 'Medium Magazine Mod', 'Stock Mod'],
    'Venator': ['Underbarrel Mod', 'Medium Magazine Mod'],
    'Vulcano': [
      'Shotgun Muzzle Mod',
      'Underbarrel Mod',
      'Shotgun Magazine Mod',
      'Stock Mod',
    ],
  };

  test('canonical weapon list has the verified attachment slot order', () {
    expect(ArcLoadoutSeedData.weapons.length, expectedSlots.length);
    for (final weapon in ArcLoadoutSeedData.weapons) {
      expect(weapon.slots, expectedSlots[weapon.name], reason: weapon.name);
    }
  });

  test('zero-slot weapons remain zero-slot weapons', () {
    for (final weapon in ['Equalizer', 'Jupiter', 'Rascal']) {
      expect(ArcLoadoutCompatibilityRegistry.slotsForWeapon(weapon), isEmpty);
    }
  });

  test('Mod display labels resolve to the correct slot types', () {
    expect(
      ArcLoadoutCompatibilityRegistry.slotTypeForLabel('Muzzle Mod').name,
      'muzzle',
    );
    expect(
      ArcLoadoutCompatibilityRegistry.slotTypeForLabel('Underbarrel Mod').name,
      'underbarrel',
    );
    expect(
      ArcLoadoutCompatibilityRegistry.slotTypeForLabel('Magazine Mod').name,
      'mediumMagazine',
    );
    expect(
      ArcLoadoutCompatibilityRegistry.slotTypeForLabel('Tech Mod').name,
      'special',
    );
  });

  test('legacy weapon catalogue delegates to the canonical source', () {
    expect(arcLoadoutWeapons.length, ArcLoadoutSeedData.weapons.length);
    for (var i = 0; i < arcLoadoutWeapons.length; i++) {
      expect(arcLoadoutWeapons[i].name, ArcLoadoutSeedData.weapons[i].name);
      expect(
        arcLoadoutWeapons[i].attachmentSlots,
        ArcLoadoutSeedData.weapons[i].slots,
      );
    }
  });
}
