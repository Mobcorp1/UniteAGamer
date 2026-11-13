import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_smart_build_mission_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_smart_build_mission_models.dart';

void main() {
  test('returns null without an active Smart Build', () {
    expect(
      ArcSmartBuildMissionEngine.build(
        plan: null,
        blueprintStates: const <String, ArcBlueprintState>{},
      ),
      isNull,
    );
  });

  test('orders missing Blueprint missions before resource and trade work', () {
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Venator',
      focus: ArcLoadoutCombatFocus.pvp,
      tier: ArcLoadoutBuildTier.meta,
    );
    final snapshot = ArcSmartBuildMissionEngine.build(
      plan: plan,
      blueprintStates: const <String, ArcBlueprintState>{},
    )!;

    expect(snapshot.missions, isNotEmpty);
    expect(snapshot.nextMission?.type, ArcSmartBuildMissionType.blueprintHunt);
    expect(snapshot.incompleteMissions, isNotEmpty);
    expect(snapshot.completionPercent, lessThan(100));
  });

  test('marks owned Blueprint requirements complete', () {
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Anvil',
      focus: ArcLoadoutCombatFocus.balanced,
      tier: ArcLoadoutBuildTier.value,
    );
    final empty = ArcSmartBuildMissionEngine.build(
      plan: plan,
      blueprintStates: const <String, ArcBlueprintState>{},
    )!;
    final blueprintMission = empty.missions.firstWhere(
      (mission) => mission.type == ArcSmartBuildMissionType.blueprintHunt,
    );

    final owned = ArcSmartBuildMissionEngine.build(
      plan: plan,
      blueprintStates: <String, ArcBlueprintState>{
        blueprintMission.targetId!: ArcBlueprintState(
          blueprintId: blueprintMission.targetId!,
          owned: true,
          dupesOwned: 0,
          priorityRank: 0,
          updatedAt: null,
        ),
      },
    )!;

    expect(
      owned.missions
          .firstWhere((mission) => mission.id == blueprintMission.id)
          .completed,
      isTrue,
    );
  });
}
