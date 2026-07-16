import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_fitted_weapon_trade_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_bundle_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';

void main() {
  const fittedEngine = ArcFittedWeaponTradeEngine();
  const bundleEngine = ArcTradeBundleEngine();

  test('Stitcher fitted weapon exposes four canonical slots', () {
    expect(fittedEngine.slotsForWeapon('Stitcher'), <String>[
      'Muzzle Mod',
      'Underbarrel Mod',
      'Magazine Mod',
      'Stock Mod',
    ]);
  });

  test('Anvil fitted weapon exposes two canonical slots', () {
    expect(fittedEngine.slotsForWeapon('Anvil'), <String>[
      'Muzzle Mod',
      'Tech Mod',
    ]);
  });

  test('zero-slot weapons produce a valid empty configuration', () {
    const config = ArcFittedWeaponConfiguration(
      weaponId: 'jupiter',
      weaponName: 'Jupiter',
    );
    expect(fittedEngine.validate(config), isEmpty);
  });

  test('any-compatible slot accepts a real compatible offered attachment', () {
    const requested = ArcFittedWeaponConfiguration(
      weaponId: 'ferro',
      weaponName: 'Ferro',
      attachmentsBySlot: <String, String>{
        'Muzzle Mod': ArcFittedWeaponConfiguration.anyCompatibleAttachment,
      },
    );
    const offered = ArcFittedWeaponConfiguration(
      weaponId: 'ferro',
      weaponName: 'Ferro',
      attachmentsBySlot: <String, String>{'Muzzle Mod': 'Compensator I'},
    );
    expect(
      fittedEngine.matchesRequirement(requested: requested, offered: offered),
      isTrue,
    );
  });

  test('exact fitted weapon mismatch is reported as missing/unexpected', () {
    const requestedConfig = ArcFittedWeaponConfiguration(
      weaponId: 'ferro',
      weaponName: 'Ferro',
      attachmentsBySlot: <String, String>{'Muzzle Mod': 'Compensator I'},
    );
    const offeredConfig = ArcFittedWeaponConfiguration(
      weaponId: 'ferro',
      weaponName: 'Ferro',
      attachmentsBySlot: <String, String>{'Muzzle Mod': 'Muzzle Brake I'},
    );
    const template = ArcTradeBundleTemplate(
      id: 'ferro-build',
      name: 'Ferro build',
      components: <ArcTradeBundleComponent>[
        ArcTradeBundleComponent(
          id: 'requested-ferro',
          type: ArcTradeBundleComponentType.fittedWeapon,
          itemId: 'ferro',
          itemName: 'Fully kitted Ferro',
          quantity: 1,
          fittedWeapon: requestedConfig,
        ),
      ],
    );
    const offer = ArcExactTradeBundleOffer(
      templateId: 'ferro-build',
      components: <ArcTradeBundleComponent>[
        ArcTradeBundleComponent(
          id: 'offered-ferro',
          type: ArcTradeBundleComponentType.fittedWeapon,
          itemId: 'ferro',
          itemName: 'Fully kitted Ferro',
          quantity: 1,
          fittedWeapon: offeredConfig,
        ),
      ],
    );

    final result = bundleEngine.compare(template: template, offer: offer);
    expect(result.status, ArcTradeBundleMatchStatus.mismatch);
    expect(result.missing, isNotEmpty);
  });
}
