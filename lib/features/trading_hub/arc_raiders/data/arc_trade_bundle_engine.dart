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
    final equivalentSubstitutions = <String>[];
    final usedOfferIndexes = <int>{};
    const fittedEngine = ArcFittedWeaponTradeEngine();
    final terms = template.effectiveTerms;
    var matchedRequiredComponents = 0;
    var matchedRequiredQuantity = 0;

    for (final requested in template.components) {
      int? matchIndex;
      for (var index = 0; index < offer.components.length; index++) {
        if (usedOfferIndexes.contains(index)) continue;
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

      if (matchIndex == null && terms.allowEquivalentSubstitutions) {
        for (var index = 0; index < offer.components.length; index++) {
          if (usedOfferIndexes.contains(index)) continue;
          final supplied = offer.components[index];
          if (!terms.acceptsCategory(supplied.type)) continue;
          matchIndex = index;
          equivalentSubstitutions.add(
            '${supplied.quantity}x ${supplied.itemName} offered for ${requested.itemName}',
          );
          break;
        }
      }

      if (matchIndex == null) {
        if (requested.required && !terms.allowFlexibleAlternatives) {
          missing.add('${requested.quantity}x ${requested.itemName}');
        }
        continue;
      }

      usedOfferIndexes.add(matchIndex);
      final supplied = offer.components[matchIndex];
      if (requested.required) {
        matchedRequiredComponents += 1;
        matchedRequiredQuantity += supplied.quantity;
      }
      if (supplied.quantity != requested.quantity &&
          !terms.allowFlexibleAlternatives) {
        incorrect.add(
          '${requested.itemName}: requested ${requested.quantity}, offered ${supplied.quantity}',
        );
      }
    }

    if (terms.allowFlexibleAlternatives) {
      if (matchedRequiredComponents < terms.minimumRequiredComponents) {
        missing.add(
          'At least ${terms.minimumRequiredComponents} requested ${terms.minimumRequiredComponents == 1 ? 'component' : 'components'}',
        );
      }
      if (matchedRequiredQuantity < terms.minimumRequiredQuantity) {
        missing.add(
          'At least ${terms.minimumRequiredQuantity} total requested ${terms.minimumRequiredQuantity == 1 ? 'item' : 'items'}',
        );
      }
    }

    if (!template.allowEquivalentOffers &&
        !terms.allowEquivalentSubstitutions &&
        !terms.allowFlexibleAlternatives) {
      for (var index = 0; index < offer.components.length; index++) {
        if (!usedOfferIndexes.contains(index)) {
          final component = offer.components[index];
          unexpected.add('${component.quantity}x ${component.itemName}');
        }
      }
    } else {
      for (var index = 0; index < offer.components.length; index++) {
        if (usedOfferIndexes.contains(index)) continue;
        final component = offer.components[index];
        if (!terms.acceptsCategory(component.type)) {
          unexpected.add('${component.quantity}x ${component.itemName}');
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
      equivalentSubstitutions: List.unmodifiable(equivalentSubstitutions),
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
      final terms = template.effectiveTerms;
      if (terms.minimumRequiredComponents > template.components.length) {
        errors.add(
          'Bundle ${template.name} asks for more minimum components than it defines.',
        );
      }
      final totalQuantity = template.components.fold<int>(
        0,
        (total, component) => total + component.quantity,
      );
      if (terms.minimumRequiredQuantity > totalQuantity) {
        errors.add(
          'Bundle ${template.name} asks for more minimum quantity than it defines.',
        );
      }
      for (final component in template.components.where(
        (component) =>
            component.type == ArcTradeBundleComponentType.fittedWeapon,
      )) {
        final fitted = component.fittedWeapon;
        if (fitted == null) {
          errors.add(
            'Bundle ${template.name} has an incomplete fitted weapon.',
          );
          continue;
        }
        errors.addAll(
          const ArcFittedWeaponTradeEngine()
              .validate(fitted)
              .map((error) => '${template.name}: $error'),
        );
      }
      if (!ids.add(template.id)) {
        errors.add('Duplicate bundle ID: ${template.id}.');
      }
    }
    return errors;
  }
}
