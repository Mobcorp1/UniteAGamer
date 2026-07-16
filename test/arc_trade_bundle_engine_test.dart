import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_bundle_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';

void main() {
  const engine = ArcTradeBundleEngine();
  const component = ArcTradeBundleComponent(
    id: 'bobcat-1',
    type: ArcTradeBundleComponentType.weapon,
    itemId: 'bobcat',
    itemName: 'Bobcat',
    quantity: 2,
  );
  const template = ArcTradeBundleTemplate(
    id: 'bundle-a',
    name: 'Two Bobcats',
    components: <ArcTradeBundleComponent>[component],
  );

  test('exact bundle matches requested quantity', () {
    const offer = ArcExactTradeBundleOffer(
      templateId: 'bundle-a',
      components: <ArcTradeBundleComponent>[component],
    );
    expect(engine.compare(template: template, offer: offer).isExact, isTrue);
  });

  test('quantity mismatch is reported', () {
    const offer = ArcExactTradeBundleOffer(
      templateId: 'bundle-a',
      components: <ArcTradeBundleComponent>[
        ArcTradeBundleComponent(
          id: 'bobcat-1',
          type: ArcTradeBundleComponentType.weapon,
          itemId: 'bobcat',
          itemName: 'Bobcat',
          quantity: 1,
        ),
      ],
    );
    final result = engine.compare(template: template, offer: offer);
    expect(result.isExact, isFalse);
    expect(result.incorrect, isNotEmpty);
  });

  test('templates serialize without losing fitted weapon configuration', () {
    const fitted = ArcTradeBundleTemplate(
      id: 'fitted-bobcat',
      name: 'Fitted Bobcat',
      components: <ArcTradeBundleComponent>[
        ArcTradeBundleComponent(
          id: 'fitted-1',
          type: ArcTradeBundleComponentType.fittedWeapon,
          itemId: 'bobcat',
          itemName: 'Bobcat',
          quantity: 1,
          fittedWeapon: ArcFittedWeaponConfiguration(
            weaponId: 'bobcat',
            weaponName: 'Bobcat',
            attachmentsBySlot: <String, String>{
              'Converter': 'Kinetic Converter',
            },
          ),
        ),
      ],
    );
    final restored = ArcTradeBundleTemplate.fromMap(fitted.toMap());
    expect(restored.components.single.fittedWeapon, isNotNull);
    expect(
      restored.components.single.fittedWeapon!.attachmentsBySlot['Converter'],
      'Kinetic Converter',
    );
  });

  test('Riven Tides keys are present with stable IDs', () {
    const expected = <String>{
      'hotel-keycard-no-102',
      'hotel-keycard-no-107',
      'hotel-keycard-no-113',
      'hotel-keycard-no-205',
      'hotel-keycard-no-208',
      'hotel-keycard-no-311',
      'hotel-keycard-no-404',
      'classified-records-keycard',
      'riven-tides-secure-storage-keycard',
      'crane-house-keycard',
    };
    final actual = ArcTradeCatalog.items.map((item) => item.id).toSet();
    expect(actual.containsAll(expected), isTrue);
  });

  test('listing bundle cap is enforced', () {
    final errors = engine.validateTemplates(
      List<ArcTradeBundleTemplate>.filled(4, template),
    );
    expect(errors, isNotEmpty);
  });
}
