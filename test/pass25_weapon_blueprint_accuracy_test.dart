import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_weapon_blueprint_ownership.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

void main() {
  final specs = <String, dynamic>{
    for (final weapon in ArcLoadoutSeedData.weapons) weapon.name: weapon,
  };
  test('PASS25 keeps full 25-weapon selection, not a new grid', () {
    expect(ArcLoadoutSeedData.weapons.length, 25);
    expect(ArcBlueprintSeedData.blueprints.length, 83);
    expect(specs.keys.toSet().length, 25);
  });

  test('PASS25 new weapon Blueprints use canonical user blueprint IDs', () {
    expect(ArcWeaponBlueprintOwnership.blueprintIdForName('Bantam'), 'bantam');
    expect(
      ArcWeaponBlueprintOwnership.blueprintIdForName('Stiletto'),
      'stiletto',
    );
    expect(ArcWeaponBlueprintOwnership.blueprintIdForName('Anvil'), 'anvil');
    expect(ArcWeaponBlueprintOwnership.blueprintIdForName('Renegade'), isNull);
    expect(ArcWeaponBlueprintOwnership.isSupplemental('BANTAM'), isTrue);
    expect(
      ArcBlueprintSeedData.blueprints.any((b) => b.id == 'bantam'),
      isFalse,
    );
    expect(
      ArcBlueprintSeedData.blueprints.any((b) => b.id == 'stiletto'),
      isFalse,
    );
  });

  test('PASS25 never invents ownership from missing records', () {
    const absent = <String, ArcBlueprintState>{};
    expect(
      ArcWeaponBlueprintOwnership.hasTrackedRecord('Bantam', absent),
      isFalse,
    );
    expect(ArcWeaponBlueprintOwnership.isLearned('Bantam', absent), isFalse);
    expect(
      ArcWeaponBlueprintOwnership.ownershipLabel('Bantam', absent),
      contains('not tracked'),
    );

    final present = <String, ArcBlueprintState>{
      'bantam': ArcBlueprintState.empty('bantam').copyWith(owned: true),
      'stiletto': ArcBlueprintState.empty('stiletto').copyWith(owned: false),
    };
    expect(ArcWeaponBlueprintOwnership.isLearned('Bantam', present), isTrue);
    expect(
      ArcWeaponBlueprintOwnership.ownershipLabel('Bantam', present),
      'Blueprint owned',
    );
    expect(
      ArcWeaponBlueprintOwnership.hasTrackedRecord('Stiletto', present),
      isTrue,
    );
    expect(
      ArcWeaponBlueprintOwnership.ownershipLabel('Stiletto', present),
      contains('Missing blueprint'),
    );
  });

  test('PASS25 corrections do not misclassify Blueprint weapons', () {
    for (final name in <String>[
      'Bantam',
      'Stiletto',
      'Aphelion',
      'Bettina',
      'Bobcat',
      'Burletta',
      'Canto',
      'Equalizer',
      'Hullcracker',
      'Jupiter',
      'Rascal',
    ]) {
      expect(specs[name].blueprintBased, isTrue, reason: name);
    }
    for (final name in <String>[
      'Arpeggio',
      'Renegade',
      'Rattler',
      'Stitcher',
    ]) {
      expect(specs[name].blueprintBased, isFalse, reason: name);
    }
    expect(specs['Renegade'].gunsmithLevel, 3);
    expect(specs['Aphelion'].gunsmithLevel, 3);
    expect(specs['Bantam'].gunsmithLevel, 1);
    expect(specs['Stiletto'].gunsmithLevel, 1);
  });

  test(
    'PASS25 preserves existing attachment layouts during metadata repairs',
    () {
      expect(specs['Bantam'].slots, isEmpty);
      expect(specs['Stiletto'].slots, [
        'Muzzle Mod',
        'Underbarrel Mod',
        'Stock Mod',
      ]);
      expect(specs['Renegade'].slots, [
        'Muzzle Mod',
        'Underbarrel Mod',
        'Stock Mod',
      ]);
      expect(specs['Anvil'].slots, ['Muzzle Mod']);
    },
  );

  test(
    'PASS25 ownership prompt is inside weapon picker, never Stencil picker',
    () {
      final code = File(
        'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
      ).readAsStringSync();
      final weaponStart = code.indexOf('  Future<void> _pickWeapon({');
      final dialogueStart = code.indexOf(
        '  Future<void> _confirmSupplementalBlueprint(',
      );
      final stencilStart = code.indexOf(
        '  Future<void> _pickStencil(bool primary)',
      );
      expect(weaponStart, greaterThan(-1));
      expect(dialogueStart, greaterThan(weaponStart));
      expect(stencilStart, greaterThan(dialogueStart));
      final weaponPicker = code.substring(weaponStart, dialogueStart);
      final stencilPicker = code.substring(stencilStart);
      expect(
        weaponPicker,
        contains('final selected = await _showPicker<ArcLoadoutWeaponSpec>('),
      );
      expect(
        weaponPicker,
        contains('await _confirmSupplementalBlueprint(selected.name, states);'),
      );
      expect(weaponPicker, contains('previousWeaponName: _secondaryWeapon'));
      expect(
        stencilPicker,
        isNot(contains('await _confirmSupplementalBlueprint(')),
      );
    },
  );

  test('PASS25 weapon picker has manual same-repository ownership update', () {
    final code = File(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    ).readAsStringSync();
    expect(code, contains('ArcWeaponBlueprintOwnership.ownershipLabel('));
    expect(code, contains('_confirmSupplementalBlueprint('));
    expect(code, contains('_blueprintRepository.saveBlueprintState('));
    expect(code, contains('ArcBlueprintOwnershipSource.manual'));
    expect(code, contains('BLUEPRINT NOT TRACKED'));
  });
}
