import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_integration_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_smart_build_hunt_models.dart';

class ArcSmartBuildHuntEngine {
  const ArcSmartBuildHuntEngine._();

  static ArcSmartBuildHuntSnapshot? build({
    required ArcGeneratedLoadoutPlan? plan,
    required Map<String, ArcBlueprintState> blueprintStates,
  }) {
    if (plan == null) return null;

    final integration = ArcLoadoutIntegrationEngine.evaluate(
      plan: plan,
      blueprintStates: blueprintStates,
    );
    final required = integration.blueprints
        .map((item) => item.blueprintId)
        .toSet();
    final missing = integration.missingBlueprints
        .map((item) => item.blueprintId)
        .toSet();
    final next = integration.missingBlueprints.isEmpty
        ? null
        : integration.missingBlueprints.first;

    return ArcSmartBuildHuntSnapshot(
      displayName: plan.displayName,
      requiredBlueprintIds: Set<String>.unmodifiable(required),
      missingBlueprintIds: Set<String>.unmodifiable(missing),
      completionPercent: integration.completionPercent,
      nextTargetId: next?.blueprintId,
      nextTargetName: next?.itemName,
    );
  }
}
