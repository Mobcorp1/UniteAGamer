import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_fitted_weapon_trade_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';

class ArcTradeBundleEngine {
  const ArcTradeBundleEngine();

  ArcTradeBundleMatchResult compare({
    required ArcTradeBundleTemplate template,
    required ArcExactTradeBundleOffer offer,
  }) {
    final missing = <String>[];
    final incorrect = <String>[];
    final unexpected = <String>[];
    final usedOfferIndexes = <int>{};
    const fittedEngine = ArcFittedWeaponTradeEngine();

    for (final requested in template.components) {
      int? matchIndex;
      for (var index = 0; index < offer.components.length; index++) {
        if (usedOfferIndexes.contains(index)) {
          continue;
        }
        final supplied = offer.components[index];
        if (supplied.type != requested.type ||
            supplied.itemId != requested.itemId) {
          continue;
        }
        if (requested.type == ArcTradeBundleComponentType.fittedWeapon) {
          final requestedConfig = requested.fittedWeapon;
          final suppliedConfig = supplied.fittedWeapon;
          if (requestedConfig == null ||
              suppliedConfig == null ||
              !fittedEngine.matchesRequirement(
                requested: requestedConfig,
                offered: suppliedConfig,
              )) {
            continue;
          }
        }
        matchIndex = index;
        break;
      }

      if (matchIndex == null) {
        if (requested.required) {
          missing.add('${requested.quantity}× ${requested.itemName}');
        }
        continue;
      }

      usedOfferIndexes.add(matchIndex);
      final supplied = offer.components[matchIndex];
      if (supplied.quantity != requested.quantity) {
        incorrect.add(
          '${requested.itemName}: requested ${requested.quantity}, offered ${supplied.quantity}',
        );
      }
    }

    if (!template.allowEquivalentOffers) {
      for (var index = 0; index < offer.components.length; index++) {
        if (!usedOfferIndexes.contains(index)) {
          final component = offer.components[index];
          unexpected.add('${component.quantity}× ${component.itemName}');
        }
      }
    }

    final status = missing.isEmpty && incorrect.isEmpty && unexpected.isEmpty
        ? ArcTradeBundleMatchStatus.exact
        : offer.components.isEmpty ||
              missing.length == template.components.length
        ? ArcTradeBundleMatchStatus.mismatch
        : ArcTradeBundleMatchStatus.partial;

    return ArcTradeBundleMatchResult(
      status: status,
      missing: List.unmodifiable(missing),
      incorrect: List.unmodifiable(incorrect),
      unexpected: List.unmodifiable(unexpected),
    );
  }

  List<String> validateTemplates(List<ArcTradeBundleTemplate> templates) {
    final errors = <String>[];
    if (templates.length > 3) {
      errors.add('A listing can contain no more than three accepted bundles.');
    }
    final ids = <String>{};
    for (final template in templates) {
      if (!template.isValid) {
        errors.add('Bundle ${template.name} is incomplete.');
      }
      if (!ids.add(template.id)) {
        errors.add('Duplicate bundle ID: ${template.id}.');
      }
    }
    return errors;
  }
}
