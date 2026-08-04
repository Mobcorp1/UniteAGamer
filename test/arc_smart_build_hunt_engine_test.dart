import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_smart_build_hunt_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';

void main() {
  ArcGeneratedLoadoutPlan plan() => ArcGeneratedLoadoutPlan(
    version: 'test',
    researchedAt: DateTime.utc(2026, 8, 3),
    primaryWeapon: 'Venator',
    primaryAttachments: const ['Extended Medium Mag II'],
    secondaryWeapon: 'Stitcher',
    secondaryAttachments: const ['Extended Light Mag II'],
    focus: ArcLoadoutCombatFocus.pvp,
    tier: ArcLoadoutBuildTier.meta,
    blueprintPriorities: const [],
    resourceNeeds: const [],
    rationale: const [],
    confidence: 'test',
  );

  test('returns null without an active smart build', () {
    expect(
      ArcSmartBuildHuntEngine.build(
        plan: null,
        blueprintStates: const <String, ArcBlueprintState>{},
      ),
      isNull,
    );
  });

  test('tracks required and missing smart build blueprints', () {
    final snapshot = ArcSmartBuildHuntEngine.build(
      plan: plan(),
      blueprintStates: const <String, ArcBlueprintState>{},
    );

    expect(snapshot, isNotNull);
    expect(snapshot!.requiredCount, greaterThan(0));
    expect(snapshot.missingCount, snapshot.requiredCount);
    expect(snapshot.nextTargetId, isNotNull);
    expect(snapshot.complete, isFalse);
  });
}
