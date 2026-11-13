import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_integration_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';

class ArcLoadoutIntegrationEngine {
  const ArcLoadoutIntegrationEngine._();

  static ArcLoadoutIntegrationSnapshot evaluate({
    required ArcGeneratedLoadoutPlan plan,
    required Map<String, ArcBlueprintState> blueprintStates,
    Map<String, int> ownedResources = const <String, int>{},
  }) {
    final blueprintNeeds = _blueprintNeeds(plan, blueprintStates);
    final resourceGaps = plan.resourceNeeds
        .map(
          (need) => ArcLoadoutResourceGap(
            itemName: need.itemName,
            requiredQuantity: need.quantity,
            ownedQuantity: _resourceCount(ownedResources, need.itemName),
          ),
        )
        .toList(growable: false);

    final missingBlueprints = blueprintNeeds
        .where((item) => item.missing)
        .toList(growable: false);
    final missingResources = resourceGaps
        .where((item) => !item.complete)
        .toList(growable: false);
    final components = <ArcTradeBundleComponent>[
      for (final item in missingBlueprints)
        ArcTradeBundleComponent(
          id: 'loadout_blueprint_${item.blueprintId}',
          type: ArcTradeBundleComponentType.blueprint,
          itemId: item.blueprintId,
          itemName: item.itemName,
          quantity: 1,
          notes: '${item.slotLabel} priority ${item.priorityRank}',
        ),
      for (final item in missingResources)
        ArcTradeBundleComponent(
          id: 'loadout_resource_${_slug(item.itemName)}',
          type: ArcTradeBundleComponentType.resource,
          itemId: _slug(item.itemName),
          itemName: item.itemName,
          quantity: item.missingQuantity,
          notes: 'Required for ${plan.displayName}',
        ),
    ];

    final totalChecks = blueprintNeeds.length + resourceGaps.length;
    final completedChecks =
        blueprintNeeds.where((item) => item.owned).length +
        resourceGaps.where((item) => item.complete).length;
    final completionPercent = totalChecks == 0
        ? 100
        : ((completedChecks / totalChecks) * 100).round().clamp(0, 100).toInt();

    return ArcLoadoutIntegrationSnapshot(
      blueprints: List<ArcLoadoutBlueprintNeed>.unmodifiable(blueprintNeeds),
      resources: List<ArcLoadoutResourceGap>.unmodifiable(resourceGaps),
      tradeTemplate: ArcTradeBundleTemplate(
        id: 'smart_build_${_slug(plan.displayName)}',
        name: '${plan.displayName} Requirements',
        components: List<ArcTradeBundleComponent>.unmodifiable(components),
        allowEquivalentOffers: plan.tier == ArcLoadoutBuildTier.value,
        terms: ArcTradeBundleTerms(
          acceptedCategories: const <ArcTradeBundleComponentType>[
            ArcTradeBundleComponentType.blueprint,
            ArcTradeBundleComponentType.resource,
            ArcTradeBundleComponentType.attachment,
          ],
          minimumRequiredComponents: components.length,
          minimumRequiredQuantity: components.fold<int>(
            0,
            (total, component) => total + component.quantity,
          ),
          allowFlexibleAlternatives: plan.tier == ArcLoadoutBuildTier.value,
          allowEquivalentSubstitutions: plan.tier == ArcLoadoutBuildTier.value,
          notes: 'Generated from loadout intelligence ${plan.version}.',
        ),
        notes: 'Completes ${plan.displayName}.',
      ),
      completionPercent: completionPercent,
      nextMove: _nextMove(missingBlueprints, missingResources, plan),
    );
  }

  static List<ArcLoadoutBlueprintNeed> _blueprintNeeds(
    ArcGeneratedLoadoutPlan plan,
    Map<String, ArcBlueprintState> states,
  ) {
    final result = <ArcLoadoutBlueprintNeed>[];
    final seen = <String>{};

    void add(String itemName, String slotLabel, int priorityRank) {
      final blueprint = _blueprintForName(itemName);
      if (blueprint == null || !seen.add(blueprint.id)) return;
      result.add(
        ArcLoadoutBlueprintNeed(
          blueprintId: blueprint.id,
          itemName: blueprint.name,
          slotLabel: slotLabel,
          priorityRank: priorityRank,
          owned: states[blueprint.id]?.owned == true,
        ),
      );
    }

    add(plan.primaryWeapon, 'Primary Weapon', 100);
    add(plan.secondaryWeapon, 'Secondary Weapon', 90);
    for (var index = 0; index < plan.primaryAttachments.length; index++) {
      add(
        plan.primaryAttachments[index],
        'Primary Attachment ${index + 1}',
        80 - index,
      );
    }
    for (var index = 0; index < plan.secondaryAttachments.length; index++) {
      add(
        plan.secondaryAttachments[index],
        'Secondary Attachment ${index + 1}',
        60 - index,
      );
    }

    result.sort((a, b) => b.priorityRank.compareTo(a.priorityRank));
    return result;
  }

  static ArcBlueprint? _blueprintForName(String itemName) {
    final target = itemName.trim().toLowerCase();
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.name.trim().toLowerCase() == target) return blueprint;
    }
    return null;
  }

  static int _resourceCount(Map<String, int> owned, String itemName) {
    final target = itemName.trim().toLowerCase();
    for (final entry in owned.entries) {
      if (entry.key.trim().toLowerCase() == target) {
        return entry.value < 0 ? 0 : entry.value;
      }
    }
    return 0;
  }

  static String _nextMove(
    List<ArcLoadoutBlueprintNeed> missingBlueprints,
    List<ArcLoadoutResourceGap> missingResources,
    ArcGeneratedLoadoutPlan plan,
  ) {
    if (missingBlueprints.isNotEmpty) {
      final first = missingBlueprints.first;
      return 'Find or trade for ${first.itemName} — ${first.slotLabel} is the highest-priority missing Blueprint.';
    }
    if (missingResources.isNotEmpty) {
      final first = missingResources.first;
      return 'Gather or trade ${first.missingQuantity}x ${first.itemName} to finish ${plan.displayName}.';
    }
    return '${plan.displayName} is ready to craft and equip.';
  }

  static String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
