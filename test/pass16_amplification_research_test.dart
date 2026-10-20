import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_state.dart';

void main() {
  test('15 researched perks have unique identities and valid weapons', () {
    expect(ArcAmplificationCatalog.projects.length, 15);
    expect(ArcAmplificationCatalog.projects.map((e) => e.id).toSet().length,15);
    expect(ArcAmplificationCatalog.moduleByWeapon.length,15);
    for(final p in ArcAmplificationCatalog.projects){
      expect(p.objectives,isNotEmpty);
      expect(p.weapons,isNotEmpty);
      expect(p.materialCount,greaterThan(0));
      for(final w in p.weapons) {
        expect(ArcAmplificationCatalog.moduleByWeapon.containsKey(w),isTrue);
      }
      for(final objective in p.objectives) {
        expect(objective.target,greaterThan(0));
      }
    }
  });
  test('allows only 5 concurrent research projects while retaining paused objectives', () {
    var state=ArcAmplificationState.empty;
    for(final project in ArcAmplificationCatalog.projects.take(5)) {
      state=state.start(project.id);
    }
    expect(state.active.length,5);
    expect(()=>state.start(ArcAmplificationCatalog.projects[5].id),throwsStateError);
    final pausedId = state.active.first;
    final replacementId = ArcAmplificationCatalog.projects[5].id;
    state = state.setObjective(pausedId, 0, 20);
    state = state.pause(pausedId);
    expect(state.active.length, 4);
    expect(state.objectiveCount(pausedId, 0), 20);

    // Filling the freed slot must not silently resume the paused project.
    state = state.start(replacementId);
    expect(state.active.length, 5);
    expect(state.active, isNot(contains(pausedId)));
    expect(() => state.start(pausedId), throwsStateError);

    // Free a slot, resume, and verify the saved objective has survived.
    state = state.pause(replacementId);
    state = state.start(pausedId);
    expect(state.active.length, 5);
    expect(state.objectiveCount(pausedId, 0), 20);
    expect(state.active.toSet().length, 5);
  });
  test('Magazine Geometry exact Bastion gates and atomic resource spending', () {
    var s=ArcAmplificationState.empty.start('magazine_geometry_101')
        .setPoints(5000).setMaterial('Bastion Cell',5);
    expect(s.canComplete('magazine_geometry_101'),false);
    s=s.setObjective('magazine_geometry_101',0,15000);
    expect(s.canComplete('magazine_geometry_101'),false);
    s=s.setObjective('magazine_geometry_101',1,1);
    expect(s.canComplete('magazine_geometry_101'),true);
    s=s.complete('magazine_geometry_101');
    expect(s.researchPoints,0);
    expect(s.materials['Bastion Cell'],0);
    expect(s.completed,contains('magazine_geometry_101'));
    expect(s.active, isNot(contains('magazine_geometry_101')));
    expect(()=>s.complete('magazine_geometry_101'),throwsStateError);
  });
  test('studied items credit point balance, no automatic game sync',(){
    var s=ArcAmplificationState.empty.study('ARC Data Module',2).study('Battered Paperback',1);
    expect(s.researchPoints,450);
    expect(()=>s.study('ARC Data Module',0),throwsArgumentError);
  });
  test('shared resource inventory cannot be spent twice',(){
    var s=ArcAmplificationState.empty.start('action_economy').start('top_mounted_optics_retrofittings');
    s=s.setPoints(5000).setMaterial('Sentinel Firing Core',8).setMaterial('Snitch Scanner',14);
    s=s.setObjective('action_economy',0,1000).complete('action_economy');
    expect(s.canComplete('top_mounted_optics_retrofittings'),false);
    expect(s.researchPoints,0);
  });
  test('unlock does not mark a perk installed; incompatible perk rejected',(){
    var s=ArcAmplificationState.empty.planPerk('Rattler','magazine_geometry_101');
    expect(s.installedPerks, isEmpty);
    expect(()=>s.confirmApplied('Rattler','magazine_geometry_101'),throwsStateError);
    expect(()=>s.planPerk('Rattler','shield_stress_testing'),throwsArgumentError);
  });
  test('weapon node materials are separate and deducted only on confirmation',(){
    var s=ArcAmplificationState.empty.start('magazine_geometry_101')
      .setPoints(5000).setMaterial('Bastion Cell',5)
      .setObjective('magazine_geometry_101',0,15000)
      .setObjective('magazine_geometry_101',1,1).complete('magazine_geometry_101');
    expect(s.missingNodeMaterials('Rattler','magazine_geometry_101')['Pressure Regulator'],4);
    expect(()=>s.confirmApplied('Rattler','magazine_geometry_101'),throwsStateError);
    s=s.setMaterial('Pressure Regulator',4).confirmApplied('Rattler','magazine_geometry_101');
    expect(s.materials['Pressure Regulator'],0);
    expect(s.installedPerks['Rattler'],contains('magazine_geometry_101'));
    expect(s.confirmApplied('Rattler','magazine_geometry_101').materials['Pressure Regulator'],0);
  });
  test('serialization round-trip rejects unknown projects and invalid amounts',(){
    final s=ArcAmplificationState.empty.start('solid_core_casting_tech')
      .setMaterial('Tick Pod',20).setObjective('solid_core_casting_tech',0,14)
      .planPerk('Il Toro','solid_core_casting_tech');
    final restored=ArcAmplificationState.fromMap(s.toMap());
    expect(restored.active,['solid_core_casting_tech']);
    expect(restored.objectiveCount('solid_core_casting_tech',0),14);
    expect(restored.materials['Tick Pod'],20);
    expect(restored.plannedPerks['Il Toro'],'solid_core_casting_tech');
    expect(ArcAmplificationState.fromMap({'active':['not_a_research'],'researchPoints':-100}).active,isEmpty);
    expect(ArcAmplificationState.fromMap({'researchPoints':-100}).researchPoints,0);
  });
}
