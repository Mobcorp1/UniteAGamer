import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_integration_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_smart_build_mission_models.dart';

class ArcSmartBuildMissionEngine {
  const ArcSmartBuildMissionEngine._();

  static ArcSmartBuildMissionSnapshot? build({
    required ArcGeneratedLoadoutPlan? plan,
    required Map<String, ArcBlueprintState> blueprintStates,
    Map<String, int> ownedResources = const <String, int>{},
  }) {
    if (plan == null) return null;

    final integration = ArcLoadoutIntegrationEngine.evaluate(
      plan: plan,
      blueprintStates: blueprintStates,
      ownedResources: ownedResources,
    );
    final missions = <ArcSmartBuildMission>[];

    for (final need in integration.blueprints) {
      missions.add(
        ArcSmartBuildMission(
          id: 'blueprint_${need.blueprintId}',
          type: ArcSmartBuildMissionType.blueprintHunt,
          title: need.owned
              ? '${need.itemName} Blueprint secured'
              : 'Hunt ${need.itemName} Blueprint',
          detail: need.owned
              ? '${need.slotLabel} requirement is complete.'
              : '${need.slotLabel} • Priority ${need.priorityRank}',
          priority: need.priorityRank,
          completed: need.owned,
          targetId: need.blueprintId,
          targetName: need.itemName,
          quantity: 1,
        ),
      );
    }

    var resourcePriority = 50;
    for (final gap in integration.resources) {
      missions.add(
        ArcSmartBuildMission(
          id: 'resource_${_slug(gap.itemName)}',
          type: ArcSmartBuildMissionType.resourceGather,
          title: gap.complete
              ? '${gap.itemName} materials secured'
              : 'Gather ${gap.missingQuantity}x ${gap.itemName}',
          detail: '${gap.ownedQuantity}/${gap.requiredQuantity} owned',
          priority: resourcePriority,
          completed: gap.complete,
          targetName: gap.itemName,
          quantity: gap.missingQuantity,
        ),
      );
      resourcePriority--;
    }

    final hasTradeNeeds = integration.tradeTemplate.components.isNotEmpty;
    missions.add(
      ArcSmartBuildMission(
        id: 'trade_bundle',
        type: ArcSmartBuildMissionType.tradeBundle,
        title: hasTradeNeeds
            ? 'Prepare Smart Trade bundle'
            : 'Trade bundle not required',
        detail: hasTradeNeeds
            ? '${integration.tradeTemplate.components.length} exact requirements ready to send to Trading.'
            : 'All tracked Blueprint and resource requirements are complete.',
        priority: 20,
        completed: !hasTradeNeeds,
        quantity: integration.tradeTemplate.components.length,
      ),
    );

    missions.add(
      ArcSmartBuildMission(
        id: 'craft_and_equip',
        type: ArcSmartBuildMissionType.craftAndEquip,
        title: integration.complete
            ? 'Craft and equip ${plan.displayName}'
            : 'Unlock crafting readiness',
        detail: integration.complete
            ? 'Every tracked Blueprint and material requirement is complete.'
            : integration.nextMove,
        priority: 10,
        completed: false,
      ),
    );

    missions.sort((a, b) {
      if (a.completed != b.completed) return a.completed ? 1 : -1;
      return b.priority.compareTo(a.priority);
    });

    return ArcSmartBuildMissionSnapshot(
      displayName: plan.displayName,
      missions: List<ArcSmartBuildMission>.unmodifiable(missions),
    );
  }

  static String _slug(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
